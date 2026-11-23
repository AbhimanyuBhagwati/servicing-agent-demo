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

No connection to Snowflake, Data 360, an interface layer of a client, User Verification, or Omni-Channel. No production use, no users, no impact. The time zone and the times in the answers are from the stubs.
