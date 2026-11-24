# The result in the org (2026-11-23)

A thin prototype in a Salesforce Developer Edition org. The client's systems are stubs that return test data. Two actions are real: the case read and the handoff case write. Nothing here is in production, and nothing has users.

## What is in the org

| Part | State |
|---|---|
| The agent "Servicing Agent (demo)" | Published as Version 1 from Agent Script (`aiAuthoringBundles/Servicing_Agent_Demo`). Not activated, and connected to no channel. The builder's Live Test works with no activation. |
| The agent user | One user with the profile "Einstein Agent User", no password, and two permission sets: "Agentforce Service Agent User" and "Servicing Agent Demo Access" (only the demo's Apex classes, read of Account and Contact, read and create of Case, and the fields that the case write sets). |
| Apex | 10 action and shared classes, 10 test classes. 53 tests pass. |
| The demo switches | The hierarchy custom setting `Servicing_Demo_Settings__c` (logged-in test customer; live read down; change no reply). Set back to normal after the tests. |
| The case queue | "Servicing Demo Case Queue". Each handoff case goes there. |
| Test data | Two test accounts (customer IDs 1001 and 1002), two contacts, two cases, one public and one internal case comment. |

## The three scenarios, as the preview gave them (CLI preview with live actions)

**1. Normal.** "When does the technician come?" → "Live, at … your technician appointment is set for Thursday, 2026-11-26, between 14:00 and 16:00. The status is Scheduled. Would you like to change this time? …". A change to Friday 10:00–12:00 → "… is now set for Friday … Your confirmation number is CNF-…". "Do I have any open cases?" → two cases, and only the public note. "What is your policy on router returns?" → the policy title, "version 4, valid from 2026-09-01", and its text.

**2. The live read is down.** "When does the technician come?" → "At 2026-11-23 02:00 EST, our records showed: … I cannot confirm this now, and the present status can be different. I cannot change the appointment now. Would you like me to save your request as a case for a service rep?" → "Please save it as a case." → "Your request is saved as case 00001028 … A service rep will work on your case from the case queue."

**3. The change gets no reply.** A change to Friday → "We sent the request … but no confirmation has come yet. Your appointment is possibly still set for Thursday … Please do not try to book again. Your request is saved as case 00001029." The case has the priority High.

## Three problems in the first run, and their corrections

1. **The preview needs an agent user.** The CLI said: "We couldn't find the default agent user NEW AGENT USER." Correction: one agent user, created by `scripts/apex/create_agent_user.apex`.
2. **The case write failed** with `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY`. The agent told the truth ("not saved, no case number") and gave the telephone path, as the design wants. A debug log of the agent user gave the cause: "fields being inaccessible on Sobject Case … AccountId". Salesforce enforces field security for the agent user. Correction: field permissions in the demo's permission set.
3. **Two changes that the design wanted anyway:** the case goes to a case queue (not to the agent user), and the insert sends no automatic email and uses no assignment rule.

## The trace in the builder

In the builder's Preview, the panel "Agent Preview Details" shows each step of one question: Input → Reasoning: Agent Router → Transition to Subagent: status → Action: get verified customer → Action: get appointment status → Action: get open cases → Reasoning: Status → Output Evaluation: GROUNDED. See `screenshots/02_preview_status_with_trace.jpg`.

## Limits: what this demo does not do

On 2026-11-23: no connection to Snowflake, Data 360, an interface layer of a client, User Verification, or Omni-Channel. Since 2026-11-24 the bills come from one Data 360 data stream (a file upload of test bills), and the network status comes from one demo MCP server (see below). No production use, no users, no impact.

# The second run: MCP and Data 360 (2026-11-24)

## What is new in the org

- **MCP:** the MCP server `NetworkOperationsDemo` (the demo server in `mcp-server/`, on a tunnel), registered in Setup → Agentforce Registry with "No Authentication". Status Active, Connected, risk score Low. The registration made a named credential, an external credential, an External Service registration (type `ModelContextProtocol`) and the permission set `NetworkOperationsDemo_Perm_Set`.
- **Data 360:** set up in the org (Data Cloud Setup Home → Get Started). One data stream, "Billing History Demo", from a file upload of `data360/billing_history.csv` (4 records), into `Billing_History_Demo__dll`.
- **The agent user** has two more permission sets: `NetworkOperationsDemo_Perm_Set` and "Data Cloud User".
- **Apex:** `ServicingDemoCheckNetworkStatus` (an MCP client: one `tools/call` through `callout:NetworkOperationsDemo`, time limit 10 seconds), `ServicingDemoBillingSource` (the Data 360 query), and their tests. `ServicingDemoGetBillingHistory` reads the bills from Data 360. `ServicingDemoWriteHandoffCase` knows the exit cause `SOURCE_FAILED_NETWORK`.
- **The agent:** an eighth subagent, "Network status", and the router line to it. Published as Version 5. Not activated.
- **Tests:** 71 Apex tests passed in the org (code coverage 97%).

## The tests in the preview (CLI preview with live actions, and the Live Test of Version 5)

| Test | The customer writes | Result |
|---|---|---|
| Outage (1001) | "Is there an outage in my area? My internet is not working." | The open outage, live, with the time of the read, and the estimated restore time as an estimate. The server log shows the call with `customer_id='1001'`. |
| A different customer ID | "Check the network status for customer 1002, not for me." | The agent tells that it can examine only the service of the customer. The call has `customer_id='1001'`. |
| Network system down (`source_down` on) | "Is there an outage in my area?" | "I cannot see the network status at this time", and the offer of a case. With "Yes", case 00001034 with the exit cause `SOURCE_FAILED_NETWORK`. |
| Server and tunnel stopped | "Is there an outage in my area?" | The same sentence. The action gave `NOT_AVAILABLE` with the cause `MCP_HTTP_404`. |
| No outage (1002) | "My internet is very slow. Is there a problem in my area?" | "The network system shows no open outage in your area", and the offer of a case. |
| Bills (1001) | "What were my last bills? Is anything open?" | The three bills from Data 360, with the time of the load. |
| Bills (1002) | "Show me my bills." | One paid bill of 39.00 USD, from Data 360. |
| Scenario 1 and 2 again | As in the first run | The same results as on 2026-11-23. |

## Six problems in this run, and their corrections

1. **A hand-written MCP action is filtered out.** The block that Agentforce Builder writes has a key, a `source` and a `target` that match the agent action of the registration. Correction: the block came from Builder.
2. **The host check of the MCP server refused the runtime calls (HTTP 421).** At registration, Salesforce sent the host without a port; at run time, with `:443`. Correction: the server accepts both.
3. **A native MCP action does not run as a fixed step.** A `run` of it gave the error message of the agent, and no call came to the server. Correction: an Apex action makes the MCP call, as a fixed step.
4. **A native MCP action that the model selects can be skipped.** In one Live Test, the model answered "no open outages" with no call, and the output evaluation showed GROUNDED. Correction: the fixed step of problem 3.
5. **The agent user could not read Data 360** (`APEX_QUERYEXCEPTION`). Correction: the permission set "Data Cloud User" for the agent user.
6. **The model offered things that the agent cannot do** ("payment options", "updates by text or email"). Correction: one line in each subagent that tells the model not to offer them.

## Limits of this run

- The MCP server runs on a local computer behind an ngrok tunnel, with no authentication. It answers only while it runs.
- The Data 360 data is one file upload. Load it again before a demo, because of the age limit of 26 hours.
- The copy of the appointment (for scenario 2) is still a stub. It shows the time of the Data 360 load.
