# Network operations (demo): the MCP server

This folder holds a small MCP server. It stands for one outside system of the client: the **network operations system**. The agent in Salesforce calls its one tool through the **Model Context Protocol (MCP)**. Agentforce is the MCP client.

> **What it is, and what it is not.** It is a demo server with test data in a JSON file. It is not connected to a real network. It runs on a local computer, behind an ngrok tunnel, only during a demo. It has no authentication, so it holds test data only.

## What the server does

| Item | Value |
|---|---|
| Transport | Streamable HTTP (the transport that the Agentforce MCP client accepts) |
| Tool | `check_network_status(customer_id)`: read only |
| Data | `data/network_events.json`: the service area of each test customer, and the network events (outages) |
| Result | The same result contract as the Apex actions of the demo: `resultCode`, `causeCode`, `source`, `recordRef`, `dataTime`, `readTime`, and the value (`statusText`, `outageFound`, `area`) |
| Log | Each call writes one line to the terminal and to `logs/calls.log` |

## The results of the tool

| Customer | Result | Cause | What the agent tells |
|---|---|---|---|
| 1001 | `FOUND` | `OPEN_OUTAGE` | An open outage (INC-4471) in the area, and an estimated restore time (an estimate, not a promise) |
| 1002 | `NOTHING_THERE` | `NO_OPEN_OUTAGE` | No open outage in the area now; it offers a case |
| An unknown ID | `NOTHING_THERE` | `UNKNOWN_CUSTOMER` | The network system has no area for this customer |
| Not digits | `REFUSED` | `BAD_INPUT` | No read is made |
| Switch `source_down` on | `NOT_AVAILABLE` | `SOURCE_DOWN` | "I cannot see the network status at this time", and it offers a case |

The server moves all times of the test data so that the newest update is 20 minutes before the server starts (`rebase_to_now`). Thus the outage always looks current.

## The switches

`switches.json` is read at each call. You do not have to start the server again.

| Switch | Effect |
|---|---|
| `"source_down": true` | The tool returns `NOT_AVAILABLE` / `SOURCE_DOWN`: a clean failure result |
| `"slow_seconds": 70` | The tool waits before it answers. Use it to see what the agent does when the MCP client time limit passes |

To show a real failure, stop the server (Ctrl+C). Then the call does not reach any server.

## Run it

1. Make the Python environment (one time):
   ```bash
   cd mcp-server
   uv venv --python 3.12 .venv
   uv pip install --python .venv/bin/python -r requirements.txt
   ```
2. Make sure that ngrok is installed and signed in (`ngrok config check`).
3. Start the server and the tunnel:
   ```bash
   ./run_demo.sh
   ```
   The script makes a long random path one time and keeps it in `.local/secret_path`. It writes the full public address to `.local/public_url`. Git ignores `.local/` and `logs/`.
4. Test the server as an MCP client does:
   ```bash
   .venv/bin/python test_client.py "$(cat .local/public_url)"
   ```

## Register it in Salesforce

1. Setup → **Agentforce Registry** → **New** → **Register MCP Server**.
2. Name (letters and digits only, for example `NetworkOperationsDemo`), a description, the **Server URL** from `.local/public_url`, and **Authentication Method: No Authentication**.
3. **Create and Continue**. Salesforce connects, reads the tool list, and gives a risk score.
4. **Add Tool** for `check_network_status`, then **Allow and Continue**.
5. Assign the permission set `<Name>_Perm_Set` to the agent user. The registration makes a named credential, an external credential, an External Service registration (type `ModelContextProtocol`) and this permission set.
6. Keep the name `NetworkOperationsDemo`: the Apex action `ServicingDemoCheckNetworkStatus` calls the tool through `callout:NetworkOperationsDemo`, as a fixed step of the agent.

The registration also makes a native MCP action. **Agentforce Builder** can add it from the asset library, and Builder writes its block with its own key, `source` and `target` (a hand-written block does not match these values, and the reasoner filters it out). The demo agent does not use the native action: in this org it does not run as a fixed step, and the model can skip it. The main README tells the tests (section 6.1).

If the ngrok address changes, edit the server URL of the registration (or of its named credential).
