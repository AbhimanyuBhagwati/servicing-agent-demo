"""Calls the demo MCP server as an MCP client does: initialize, list the tools, call the tool.

Usage: .venv/bin/python test_client.py <server URL> [customer IDs ...]
"""
import asyncio
import json
import sys

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


async def main(url: str, ids: list[str]) -> None:
    async with streamablehttp_client(url) as (read, write, _):
        async with ClientSession(read, write) as s:
            init = await s.initialize()
            print("server:", init.serverInfo.name, "| protocol:", init.protocolVersion)
            tools = await s.list_tools()
            for t in tools.tools:
                print("tool:", t.name, "| input:", list(t.inputSchema.get("properties", {})),
                      "| output:", list((t.outputSchema or {}).get("properties", {})))
            for cid in ids:
                r = await s.call_tool("check_network_status", {"customer_id": cid})
                sc = r.structuredContent or {}
                print(f"\n{cid!r} -> {sc.get('resultCode')}/{sc.get('causeCode')} {sc.get('recordRef')}")
                print("  ", sc.get("statusText"))
                print("   isError:", r.isError, "| dataTime:", sc.get("dataTime"), "| readTime:", sc.get("readTime"))


if __name__ == "__main__":
    asyncio.run(main(sys.argv[1], sys.argv[2:] or ["1001", "1002", "9999", "abc"]))
