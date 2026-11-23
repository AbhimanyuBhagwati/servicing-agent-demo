# Servicing Agent (demo)

A thin prototype of a design document for a customer-servicing AI agent, for a Salesforce Developer Edition org with Agentforce Builder and Agent Script. The design document is not in this repository: "design/06" and the § numbers below refer to it. Tell the demo as: **"a thin prototype in a Developer Edition org, with the client's systems as stubs that return test data."**

Written 2026-11-23 from the official Agent Script specification, the official recipes, Salesforce's open-source agent skills and the boilerplate that the Salesforce CLI generated. **Status (2026-11-23):** deployed to one Developer Edition org, and run there. The three scenarios below worked in the preview with live actions. The agent is published as Version 1, **not activated**, with no channel. The transcripts, the two problems found in the org and their corrections, and two screenshots are in [`docs/RESULT.md`](docs/RESULT.md).

## What the demo shows

- **One agent, `Servicing_Agent_Demo`**, in Agent Script. `start_agent` is the Agent Router. It sends each message to one of three jobs (`status`, `account`, `product`), to `person_job` (the list of jobs for persons, a planned exit) or to `handoff` ("I want a person").
- **The identity first.** A fixed `run` of action 1 sets the customer ID one time in the session, at the start of the first job that needs account data (`status`, `account` or `handoff`). The model never sets it. The router stays a pure router of transitions.
- **The must-have read first, as a fixed `run`**, in each job, with the customer ID bound from the variable. The outputs go into variables. Then **a fixed branch on the result** builds the instructions for the model. The model does not choose the path for a failure.
- **The six results of design/06 §5**: `FOUND`, `NOTHING_THERE`, `NOT_AVAILABLE`, `REFUSED`, `NOT_CONFIRMED`, `HELD_BACK`. Each action catches its own errors and returns `NOT_AVAILABLE` with a cause code. No action throws.
- **The rule for a failure (design/06 §4)** and **the rule for the old value (§6)**: when the live read is down, the agent tells the 02:00 copy as the past, with its time, says what it cannot confirm, and offers a case for a service rep.
- **The one change**, with a request key, an `available when` guard, and the branches for `REFUSED` and `NOT_CONFIRMED`.
- **The handoff in its order (design/06 §7)**: the exit cause, the way to a person (action 7), the case written by code (action 8), then the true sentence with the case number. The case carries the record of §8, each fact with its state.

## Real or stub

| # | Action (Apex class) | Real or stub | The production part that it replaces |
|---|---|---|---|
| 1 | Get the verified customer (`ServicingDemoGetVerifiedCustomer`) | Stub: reads a demo setting | User Verification and a linked variable |
| 2 | Get the appointment status (`ServicingDemoGetAppointmentStatus`) | Stub: test data; "not available" when the demo switch "live read down" is on | The live read through the client's interface layer |
| 3 | Get the billing history (`ServicingDemoGetBillingHistory`) | Stub: test rows with the load time 02:00 (and the copy of the appointment from the same load) | Data 360, Zero Copy query federation to Snowflake |
| 4 | Get the open cases (`ServicingDemoGetOpenCases`) | REAL: a fixed SOQL query on Case, only public comments (`CaseComment.IsPublished = true`) | The same |
| 5 | Get the policy (`ServicingDemoGetPolicy`) | Stub: two policy texts with a version and a start date; "nothing there" for other subjects | The retriever on the search index |
| 6 | Change the appointment (`ServicingDemoChangeAppointment`) | Stub, with a request key; "not confirmed" when the demo switch "change no reply" is on; "refused" for a time that is not free | The one write action through the interface layer |
| 7 | Examine the way to a person (`ServicingDemoCheckWayToPerson`) | Stub: returns "case only" (no Omni-Channel in this org) | Check Availability for Routing and the hours |
| 8 | Write the handoff case (`ServicingDemoWriteHandoffCase`) | REAL: inserts a Case with the record of design/06 §8 in its description | The same |

Two shared classes: `ServicingDemoResult` (the result contract, the time format, the cause code, the read of the demo settings; a helper, no system behind it) and `ServicingDemoStubData` (the invented test data of the stubs). Each class starts with "DEMO STUB: replaces ..." or "REAL".

All client facts in the stubs are invented [A]: the appointment, the free slots, the bills, the two policy texts, the next step text. Customer IDs 1001 and 1002 only.

## The mapping to design/06

| design/06 | In the demo |
|---|---|
| §4 The rule for a failure | The `NOT_AVAILABLE` and `HELD_BACK` branches in `status`, `account` and `product`: no guess; the known fact and its age; what cannot be confirmed; the offer of a case |
| §5 The six results; the fields with each result | `ServicingDemoResult` and the `Response` class of each action: `resultCode`, `causeCode`, `dataSource`, `recordRef`, `dataTime`, `readTime`, and small typed values |
| §5 "Each action catches its own error" (R02) | A `try`/`catch` in each action; tests drive each `catch` |
| §6 Step 1, prove the identity | The fixed `run` of action 1 at the start of `status`, `account` and `handoff`, guarded so that it runs one time in a session |
| §6 Step 2, find the job | `start_agent agent_router` with `@utils.transition to` for each job |
| §6 Step 3, get the facts (and the order of the reads in the design's detail of step 3) | Status: the live read, then the cases. Account: the history (one time in a session), then the cases. Product: the policy. A read that the job only uses when available does not start after a must-have read gave `NOT_AVAILABLE` or `HELD_BACK`. The reads run in sequence. |
| §6 Step 4, answer from the results only | The instruction text of each branch, with the values and the times from the variables |
| §6 The one action | `change_appointment`, with `available when` (identity proven, the status found, the change switch not off, no change done or pending) |
| §6 The rule for the old value | After a live read with `NOT_AVAILABLE`: one read of the 02:00 copy, told as the past with its time; no negative fact from the copy; the age limit in action 3 gives `HELD_BACK` |
| §7 H1 the exit cause | `exit_cause`, set by code in each failure branch; `CUSTOMER_REQUEST` only when the customer asks; `JOB_FOR_PERSONS` in `person_job` |
| §7 H2 the way to a person | Action 7, before any offer of a person |
| §7 H3 the case | Action 8, a fixed `run`, before any escalation attempt |
| §7 H4 the true sentence | The handoff instructions: the case number and the next step text from code |
| §7 H5a one escalation attempt | A commented line in `handoff`, with its guard. Not active: no Omni-Channel in this org |
| §7 H6 the case write failed | One more write when no way is open; then the truth and the telephone number on the bill |
| §8 The record for the service rep | The Case Description: "INTERNAL", the exit cause first, the change, the identity, each source with one of the marks ("found", "nothing there", "could not look" with the cause, "held back" with the cause, "not asked", "old" with its time), the pointer to the conversation, the summary (empty) |
| §9 End states | Not computed (see "What the demo simplifies") |
| §12 The switch "the change off" | The variable `change_switch_off` and the `available when` guard |

## What the demo simplifies

- **H2b, the offer.** The only open way in this org is a case. So the handoff writes the case at once when the customer accepts help, or asks for a person, or the change is not confirmed. In production, with an open way, the customer selects a colleague or a case.
- **No end states, no session records, no comparison group, no result line events (R44), no entry rule.** The case and the trace of the preview are the only records.
- **No time limits.** The stubs make no callout, so no Apex time limit is set (R05).
- **The policy match is a keyword match**, not a search index. The product job has no product catalog read.
- **The age limit of the copy is a constant (26 hours)** in `ServicingDemoStubData`, not a value of a data platform owner.
- **The switch "the change off" is a variable default** in the script, not a value that a duty role sets.
- **The change stores nothing.** After a `FOUND` change, a new session shows the old appointment again.

## The customer ID: two ways

- **Way A (the script uses it).** Action 1 reads the demo setting `Logged_In_Customer_Id__c` and checks that one Account has that customer ID in its standard field Account Number. The script calls it one time in the session, as a fixed `run` at the start of `status`, `account` or `handoff` (whichever comes first), with `contextCustomerId=""`. The result goes into the mutable variable `customer_id`. No tool lets the model write that variable.
- **Way B (a test, not used).** The installed CLI preview accepts `--context-variables Name=Value`. To test it: in the three subagents `status`, `account` and `handoff`, change `with contextCustomerId=""` to `with contextCustomerId=@variables.VerifiedCustomerId` (the boilerplate's variable), then start the preview with `--context-variables VerifiedCustomerId=1002`. Action 1 then uses that value, and its output `identityProof` says "way B". Which variables the flag can set is not confirmed [Test]. Way B uses a mutable variable; the design does not accept that for production.
- **Production.** A linked variable from the verified messaging session (R21): nothing in the agent can assign it. The mapping from the token to the customer record is test T12 of design/06.

## The two ways into the org

### Way 1: the Salesforce CLI (the main path)

Run from the folder `demo/servicing-agent`. The flags marked [to confirm] come from Salesforce's open-source agent skills or long-established CLI use, and not from `--help` in this CLI. Run `sf <command> --help` first.

1. Deploy the custom setting and the Apex classes (with their tests):
   ```
   sf project deploy start --source-dir force-app/main/default/objects --source-dir force-app/main/default/classes
   ```
2. Optional, the Apex tests with coverage [to confirm the flags]:
   ```
   sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 10
   ```
3. The test data and the org default row of the setting:
   ```
   sf apex run --file scripts/apex/create_demo_data.apex
   ```
4. Compile the Agent Script against the org (it creates nothing):
   ```
   sf agent validate authoring-bundle --api-name Servicing_Agent_Demo
   ```
5. Preview the LOCAL bundle with the real Apex actions, with no publish:
   ```
   sf agent preview start --authoring-bundle Servicing_Agent_Demo --use-live-actions
   sf agent preview send --authoring-bundle Servicing_Agent_Demo --session-id <ID from start> -u "When is my technician coming?"
   sf agent preview end --authoring-bundle Servicing_Agent_Demo --session-id <ID from start>
   ```
   [to confirm: the names of `--authoring-bundle` and `--session-id` on `send` and `end`.]
6. Between scenarios, set the switches and start a NEW preview session (each read happens one time in a session):
   ```
   sf apex run --file scripts/apex/scenario_1_normal.apex
   sf apex run --file scripts/apex/scenario_2_live_read_down.apex
   sf apex run --file scripts/apex/scenario_3_change_no_reply.apex
   ```
7. **The agent user, the queue and the publish.** The preview with live actions and the publish need an agent user: an identity in the org, so create it only in your own org. Deploy the permission set `Servicing_Agent_Demo_Access` (class access for the ten classes; read on Account, Contact and Case; create on Case, with the field permissions that the case write needs) and the case queue, then create the agent user (profile "Einstein Agent User", no password, two permission sets):
   ```
   sf project deploy start --source-dir force-app/main/default/permissionsets --source-dir force-app/main/default/queues
   sf apex run --file scripts/apex/create_agent_user.apex
   ```
   The script prints the username (`servicing.demo.agent@<your org ID>.ext`). Put it in place of `REPLACE_WITH_AGENT_USER_USERNAME` in two files: `default_agent_user` in the `.agent` file, and `botUser` in `force-app/main/default/aiAgents/Servicing_Agent_Demo.aiAgentDefinition-meta.xml`. The repository keeps the placeholder, so that no org ID is in it. Then:
   ```
   sf agent publish authoring-bundle --api-name Servicing_Agent_Demo
   ```
   The publish creates the agent and writes its metadata (`aiAgents/`, `aiAgentDefinitionVersions/`, with the compiled Agent Graph in `agentGraph/`) into this project. Activation (`sf agent activate`) is not done in this demo.

### Way 2: the browser

Setup and the Developer Console, then the Script view of Agentforce Builder. The exact order and the file to paste at each step are in `PASTE_GUIDE.md`.

## The three demo scenarios

Start a new preview session for each scenario. The model writes the words, so the wording changes; the facts and the order must be the ones below. If a fact in the answer is not in the list, that is a finding.

### Scenario 1: the normal status

Settings: customer 1001; "live read down" off; "change no reply" off (`scenario_1_normal.apex`).

| Type | The answer must give |
|---|---|
| When is my technician coming? | The visit (a check of the internet line) on the next Thursday, with its date, 14:00-16:00, status Scheduled, named as the **live** status at the time of the read. It can name the open case "Slow internet in the evening" and its public note. It never gives the internal note ("noise on the line"). |
| Can you move it to Saturday morning? | That time is not free, and nothing changed. The free times: FRI-1000 (Friday 10:00-12:00), FRI-1400 (Friday 14:00-16:00), MON-0800 (Monday 08:00-10:00), with their dates. |
| Then Friday at 10, please. | The change is complete: a confirmation number `CNF-` and 8 characters, and the new time Friday 10:00-12:00. |

### Scenario 2: the live read is down

Settings: customer 1001; "live read down" **on** (`scenario_2_live_read_down.apex`).

| Type | The answer must give |
|---|---|
| When is my technician coming? | Four things: "At [today 02:00], our records showed" the Thursday visit, 14:00-16:00; it cannot confirm that now, and the present status can be different; it cannot change the appointment now; it can save the request as a case for a service rep. No "live" claim, no guess, no promise of a person or of a time for a call. |
| Yes, please save a case for a service rep. | The request is saved as case [number], with the facts found; the next step: a service rep works on the case from the case queue; keep the case number. It does not say that a person joins the chat. |

Then show the case in Setup (Cases): Subject `Servicing demo handoff: SOURCE_FAILED_LIVE_READ`, Priority Medium, and in the Description: "INTERNAL RECORD FOR THE SERVICE REP"; "4. Live status ...: could not look: DEMO_SWITCH_LIVE_READ_DOWN"; "5b. Appointment in the same nightly copy: old (from the nightly copy of ...)"; "2. Change: not asked"; "6. Open cases ...: not asked" (the case read did not start after the failed must-have read).

### Scenario 3: the change is not confirmed

Settings: customer 1001; "live read down" off; "change no reply" **on** (`scenario_3_change_no_reply.apex`).

| Type | The answer must give |
|---|---|
| When is my technician coming? | As in scenario 1. |
| Please move it to Friday at 14:00. | No offer, code goes to the handoff: the change was sent and no confirmation came; the appointment is possibly still Thursday 14:00-16:00; do not book again; a service rep examines the appointment first; the request is saved as case [number]. It never says that the change is done. |

Then show the case: Priority **High**, Subject `Servicing demo handoff: CHANGE_NOT_CONFIRMED`, and "2. Change: NOT CONFIRMED. Do not book a second time. Examine the appointment first. request key 1001-WO-1001-01:FRI1400; ...; read after the change: ..." [Test: if the transition in the instructions does not fire in the same turn, the customer reads "a service rep will examine the appointment" first, and the case comes with the next message, from `after_reasoning`.]

### More questions, if a panelist asks

| Type | The answer must give |
|---|---|
| What was my last bill? | From our records at [02:00], the nightly copy: the bills, the last one 64.50 USD, Open, with its due date. It says that a payment after that time is not in these records. |
| What happens to my router if I cancel? | The approved text "Equipment return policy", version 4, valid from 2026-09-01: return within 30 days, with a prepaid label. |
| Do you sell satellite TV? | "I have no approved policy text for that question", no answer from its own knowledge, the offer of a case. |
| I want to cancel my contract. | A job for a service rep (planned exit); a case with the exit cause `JOB_FOR_PERSONS`. |
| I want to talk to a human. | No service rep can take the chat now; the case number; the next step. |
| (Setting: customer 9999, or empty) When is my technician coming? | No appointment detail and no account detail; sign in again in the app; the offer of a case. |

## What not to claim

- **No connection** to Snowflake, Data 360, an interface layer of a client, a search index, Enhanced Chat, User Verification or Omni-Channel. Each of those is a stub that returns test data, or is absent. The two real parts are the case read and the case write in Salesforce.
- **No escalation to a person.** `@utils.escalate` is a commented line; this org has no messaging connection.
- **No production use, no users, no customers, no deployment, no impact, no measured KPI.** Test data only, in a Developer Edition org.
- **Nothing is proven by the demo** beyond what the preview shows. The tests of design/06 (T1 to T14) are still open.
- **Do not say "service agent" for the person.** The person is a service rep; Agentforce Service Agent is the AI.

## Files

```
servicing-agent/
  sfdx-project.json
  README.md, PASTE_GUIDE.md
  docs/RESULT.md             the run in the org: transcripts, problems and corrections
  docs/screenshots/          the Agent Graph in the builder; the preview with its trace
  force-app/main/default/
    aiAuthoringBundles/Servicing_Agent_Demo/Servicing_Agent_Demo.agent
    aiAuthoringBundles/Servicing_Agent_Demo/Servicing_Agent_Demo.bundle-meta.xml
    aiAgents/, aiAgentDefinitionVersions/   written by the publish (Version 1), with the compiled Agent Graph
    classes/                 10 classes, 10 test classes (9 tests + 1 test data factory), each with -meta.xml
    objects/Servicing_Demo_Settings__c/   the hierarchy custom setting and its 3 fields
    permissionsets/Servicing_Agent_Demo_Access.permissionset-meta.xml
    queues/Servicing_Demo_Case_Queue.queue-meta.xml
  scripts/apex/create_demo_data.apex, create_agent_user.apex
  scripts/apex/scenario_1_normal.apex, scenario_2_live_read_down.apex, scenario_3_change_no_reply.apex
```
