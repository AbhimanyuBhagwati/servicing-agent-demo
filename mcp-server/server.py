"""Network operations (demo): a small MCP server for the Servicing Agent demo.

It stands for one outside system of the client: the network operations system.
It keeps its own test data in data/network_events.json. It is NOT connected to a
real network. The agent in Salesforce reads this data live, through MCP; nothing
is copied into Salesforce.

Transport: Streamable HTTP, which is the transport that the Agentforce MCP client
accepts. The address has a long random path (see run_demo.sh). There is no
authentication, so the server holds test data only and runs only for a demo.

The result follows the result contract of the demo's Apex actions: a result
(FOUND, NOTHING_THERE, NOT_AVAILABLE, REFUSED), a cause code, the source, a record
reference, the time of the data and the time of the read, and the value.
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings
from mcp.types import ToolAnnotations
from pydantic import BaseModel, Field

HERE = Path(__file__).parent
DATA_FILE = HERE / "data" / "network_events.json"
SWITCH_FILE = HERE / "switches.json"
LOG_FILE = HERE / "logs" / "calls.log"
SOURCE = "Network operations system (demo MCP server, test data)"

PORT = int(os.environ.get("MCP_PORT", "8787"))
PATH = os.environ.get("MCP_PATH", "/mcp")
PUBLIC_HOST = os.environ.get("MCP_PUBLIC_HOST", "")  # the ngrok host name, for the host check

LOCAL_TZ = datetime.now().astimezone().tzinfo


class NetworkStatus(BaseModel):
    """The result of one read of the network status."""

    resultCode: str = Field(description="FOUND, NOTHING_THERE, NOT_AVAILABLE or REFUSED.")
    causeCode: str = Field(description="Why: OPEN_OUTAGE, NO_OPEN_OUTAGE, UNKNOWN_CUSTOMER, SOURCE_DOWN or BAD_INPUT.")
    source: str = Field(description="The system that gave the data.")
    recordRef: str = Field(description="The outage reference, for example INC-4471. Empty when there is none.")
    outageFound: bool = Field(description="True only when an open outage affects the customer's area.")
    area: str = Field(description="The network area of the customer's service. Empty when unknown.")
    dataTime: str = Field(description="When the network system last updated this record.")
    readTime: str = Field(description="When this read happened.")
    statusText: str = Field(description="The facts in one or two sentences, for the agent to use.")


def _load_events() -> dict:
    data = json.loads(DATA_FILE.read_text())
    if data.get("rebase_to_now"):
        stamps = [e["updated_at"] for e in data["events"] if e.get("status") == "OPEN"] or [
            e["updated_at"] for e in data["events"]
        ]
        newest = max(datetime.fromisoformat(s) for s in stamps)
        shift = (datetime.now(timezone.utc) - timedelta(minutes=20)) - newest
        for e in data["events"]:
            for k in ("reported_at", "updated_at", "estimated_restore_at", "restored_at"):
                if k in e:
                    e[k] = (datetime.fromisoformat(e[k]) + shift).isoformat()
    return data


DATA = _load_events()


def _switches() -> dict:
    try:
        return json.loads(SWITCH_FILE.read_text())
    except (OSError, ValueError):
        return {}


def _fmt(ts: str) -> str:
    """A time for a person: the weekday, the date and the local time with its zone."""
    t = datetime.fromisoformat(ts).astimezone(LOCAL_TZ)
    return t.strftime("%a %d %b %H:%M %Z").strip()


def _stamp(t: datetime) -> str:
    """The same time format as the Apex actions of the demo, for example 2026-11-24 04:07 EST."""
    return t.astimezone(LOCAL_TZ).strftime("%Y-%m-%d %H:%M %Z")


def _now() -> str:
    return _stamp(datetime.now(timezone.utc))


def _log(customer_id: str, r: NetworkStatus) -> None:
    line = f"{_now()}  check_network_status customer_id={customer_id!r} -> {r.resultCode}/{r.causeCode} {r.recordRef}"
    print(line, flush=True)
    LOG_FILE.parent.mkdir(exist_ok=True)
    with LOG_FILE.open("a") as f:
        f.write(line + "\n")


# The public host with and without a port: at registration Salesforce sends
# "host", and at run time it sends "host:443".
hosts = ["127.0.0.1:*", "localhost:*", "[::1]:*"] + ([PUBLIC_HOST, f"{PUBLIC_HOST}:*"] if PUBLIC_HOST else [])
mcp = FastMCP(
    "network-operations-demo",
    instructions="Network operations (demo). One read-only tool: the network status of a customer's service area. Test data only.",
    host="127.0.0.1",
    port=PORT,
    streamable_http_path=PATH,
    stateless_http=True,
    json_response=True,
    transport_security=TransportSecuritySettings(
        enable_dns_rebinding_protection=True,
        allowed_hosts=hosts,
        allowed_origins=[f"https://{h}" for h in hosts if "*" not in h],
    ),
)


@mcp.tool(
    name="check_network_status",
    title="Check network status",
    description=(
        "Read the network status of the customer's service area from the network operations system: "
        "is there an open outage, what it is, and when the service is estimated to come back. "
        "Input: the customer ID of the verified customer (digits only). Read only. "
        "The result is FOUND (an open outage), NOTHING_THERE (no open outage, or an unknown customer), "
        "NOT_AVAILABLE (the network system did not answer) or REFUSED (the input is not a customer ID)."
    ),
    annotations=ToolAnnotations(readOnlyHint=True, destructiveHint=False, idempotentHint=True, openWorldHint=False),
    structured_output=True,
)
def check_network_status(customer_id: str) -> NetworkStatus:
    read = _now()
    sw = _switches()
    if sw.get("slow_seconds"):
        time.sleep(float(sw["slow_seconds"]))

    def result(code, cause, text, ref="", found=False, area="", data_time=""):
        r = NetworkStatus(resultCode=code, causeCode=cause, source=SOURCE, recordRef=ref, outageFound=found,
                          area=area, dataTime=data_time, readTime=read, statusText=text)
        _log(customer_id, r)
        return r

    cid = (customer_id or "").strip()
    if not re.fullmatch(r"\d{1,20}", cid):
        return result("REFUSED", "BAD_INPUT", "The input is not a customer ID. No read was made.")
    if sw.get("source_down"):
        return result("NOT_AVAILABLE", "SOURCE_DOWN",
                      "The network operations system did not answer. The network status is not known.")
    cust = DATA["customers"].get(cid)
    if not cust:
        return result("NOTHING_THERE", "UNKNOWN_CUSTOMER",
                      "The network operations system has no service area for this customer.")
    area = cust["area"]
    in_area = [e for e in DATA["events"] if e["area"] == area]
    open_events = [e for e in in_area if e["status"] == "OPEN"]
    if open_events:
        e = max(open_events, key=lambda x: x["updated_at"])
        crew = "A repair crew is on site." if e.get("crew_on_site") else "No repair crew is on site yet."
        text = (f"Open outage {e['id']} in area {area}: {e['kind']}. Impact: {e['impact']}. "
                f"Reported {_fmt(e['reported_at'])}. {crew} "
                f"Estimated restore: {_fmt(e['estimated_restore_at'])} (an estimate, not a promise). "
                f"Last update {_fmt(e['updated_at'])}.")
        return result("FOUND", "OPEN_OUTAGE", text, e["id"], True, area, _stamp(datetime.fromisoformat(e["updated_at"])))
    last = max(in_area, key=lambda x: x["updated_at"]) if in_area else None
    text = f"No open outage in area {area}."
    if last:
        text += f" The last event, {last['id']} ({last['kind'].lower()}), was closed {_fmt(last['updated_at'])}."
    return result("NOTHING_THERE", "NO_OPEN_OUTAGE", text, "", False, area,
                  _stamp(datetime.fromisoformat(last["updated_at"])) if last else "")


if __name__ == "__main__":
    print(f"network-operations-demo on http://127.0.0.1:{PORT}{PATH[:5]}... (public host: {PUBLIC_HOST or 'none'})",
          file=sys.stderr, flush=True)
    mcp.run(transport="streamable-http")
