# Paste guide: the browser path

The order to put the Servicing Agent (demo) into a Developer Edition org through the browser, with no installation. The CLI path in `README.md` is the main path; use this guide only when the CLI is not available.

Each step names the file to paste. Paste the content of the `.cls` file only, never the `-meta.xml` file. All file paths are relative to `demo/servicing-agent/`.

Some button names come from long-established Setup pages and were not seen in this org; they are marked [to confirm].

## Step 1. The custom setting, by hand

The metadata files `force-app/main/default/objects/Servicing_Demo_Settings__c/...` describe the same setting for the CLI. In the browser, make it by hand:

1. Setup → Quick Find: **Custom Settings** → **Custom Settings** → **New**.
2. Fill in:
   - Label: `Servicing Demo Settings`
   - Object Name: `Servicing_Demo_Settings` (the API name becomes `Servicing_Demo_Settings__c`)
   - Setting Type: **Hierarchy**
   - Visibility: **Public**
   - Description: `Demo switches for the Servicing Agent (demo). Test data only.`
3. **Save**.
4. On the detail page of the setting, in **Custom Fields**, click **New**, and make three fields:

   | Data type | Field Label | Field Name (API name) | Other values |
   |---|---|---|---|
   | Text | Logged In Customer Id | `Logged_In_Customer_Id` (→ `Logged_In_Customer_Id__c`) | Length 20 |
   | Checkbox | Live Read Down | `Live_Read_Down` (→ `Live_Read_Down__c`) | Default Value: Unchecked |
   | Checkbox | Change No Reply | `Change_No_Reply` (→ `Change_No_Reply__c`) | Default Value: Unchecked |

   The API names must be exactly these: the Apex classes read them.
5. Do not enter values now. Step 4 sets the org default row (customer 1001, both switches off).

## Step 2. The Apex classes, one by one

Setup → Quick Find: **Apex Classes** → **New** → paste the whole content of the file → **Save**. Or: Developer Console → **File** → **New** → **Apex Class** → the class name → paste → **Save**. The API version of a class made in the browser is the default of the org.

Paste in this order. A class can be saved only after the classes that it uses.

| # | File to paste | What it is |
|---|---|---|
| 1 | `force-app/main/default/classes/ServicingDemoResult.cls` | REAL helper: the result contract and the demo settings |
| 2 | `force-app/main/default/classes/ServicingDemoStubData.cls` | DEMO STUB DATA |
| 3 | `force-app/main/default/classes/ServicingDemoGetVerifiedCustomer.cls` | Action 1, stub |
| 4 | `force-app/main/default/classes/ServicingDemoGetAppointmentStatus.cls` | Action 2, stub |
| 5 | `force-app/main/default/classes/ServicingDemoGetBillingHistory.cls` | Action 3, stub |
| 6 | `force-app/main/default/classes/ServicingDemoGetOpenCases.cls` | Action 4, REAL |
| 7 | `force-app/main/default/classes/ServicingDemoGetPolicy.cls` | Action 5, stub |
| 8 | `force-app/main/default/classes/ServicingDemoChangeAppointment.cls` | Action 6, stub |
| 9 | `force-app/main/default/classes/ServicingDemoCheckWayToPerson.cls` | Action 7, stub |
| 10 | `force-app/main/default/classes/ServicingDemoWriteHandoffCase.cls` | Action 8, REAL |
| 11 | `force-app/main/default/classes/ServicingDemoTestFactory.cls` | Test data for the tests |
| 12 | `force-app/main/default/classes/ServicingDemoSharedTest.cls` | Test |
| 13 | `force-app/main/default/classes/ServicingDemoGetVerifiedCustomerTest.cls` | Test |
| 14 | `force-app/main/default/classes/ServicingDemoGetAppointmentStatusTest.cls` | Test |
| 15 | `force-app/main/default/classes/ServicingDemoGetBillingHistoryTest.cls` | Test |
| 16 | `force-app/main/default/classes/ServicingDemoGetOpenCasesTest.cls` | Test |
| 17 | `force-app/main/default/classes/ServicingDemoGetPolicyTest.cls` | Test |
| 18 | `force-app/main/default/classes/ServicingDemoChangeAppointmentTest.cls` | Test |
| 19 | `force-app/main/default/classes/ServicingDemoCheckWayToPersonTest.cls` | Test |
| 20 | `force-app/main/default/classes/ServicingDemoWriteHandoffCaseTest.cls` | Test |

A Developer Edition org does not require the tests for this path. They are there for the CLI path and to show that each action returns a result and never throws.

Optional: run the tests. Developer Console → **Test** → **New Run** → select the `ServicingDemo...Test` classes → **Run** [to confirm]. Or Setup → **Apex Test Execution** → **Select Tests**.

## Step 3. Only if an agent user runs the agent: the permission set

Do this before the preview with live actions: the preview and the published agent run as an agent user, and Salesforce enforces this permission set for it.

Setup → **Permission Sets** → **New** → Label `Servicing Agent Demo Access` → **Save**. Then:
- **Apex Class Access** → **Edit** → add the ten classes of rows 1 to 10 above → **Save**.
- **Object Settings**: Accounts: Read; Contacts: Read; Cases: Read and Create. Account field Account Number: Read. Case fields Account, Contact, Description, Origin, Priority, Subject: Read and Edit; Case field Status: Read. Without the Case fields, the case write fails.
- **Manage Assignments** → add the agent user.

The file `force-app/main/default/permissionsets/Servicing_Agent_Demo_Access.permissionset-meta.xml` is the same permission set for the CLI.

## Step 4. The test data

Developer Console → **Debug** → **Open Execute Anonymous Window** → paste the whole content of `scripts/apex/create_demo_data.apex` → **Execute**.

The log shows "Servicing demo: test data created" (or "already there" on a second run) and "org default settings: customer 1001, live read down off, change no reply off".

It creates two test Accounts (Demo Customer A, customer ID 1001; Demo Customer B, customer ID 1002), one Contact on each, two open Cases on Demo Customer A, one public and one internal CaseComment, and the org default row of the setting.

## Step 5. The agent

1. App Launcher → **Agentforce Studio** → **Agents** → **New Agent**.
2. The org offers the template **Agentforce Service Agent** (seen in the org on 2026-11-23). A Service Agent runs as an agent user, which is an identity in the org: create it only in your own org (`scripts/apex/create_agent_user.apex`). Name: `Servicing Agent (demo)`; API name: `Servicing_Agent_Demo` [to confirm the fields of the dialog].
3. In Agentforce Builder, switch from **Canvas** to **Script** view.
4. Select all the script text, and paste the whole content of `force-app/main/default/aiAuthoringBundles/Servicing_Agent_Demo/Servicing_Agent_Demo.agent`. This replaces the subagents of the template (Service Customer Verification, General FAQ, and the others) with the subagents of the demo.
5. **Keep the builder's own values** in the `config:` block for `developer_name` and `default_agent_user` if they differ from the file. The file has `default_agent_user: "REPLACE_WITH_AGENT_USER_USERNAME"`, a placeholder: put the username of your agent user there (see step 7 of the CLI path in `README.md`).
6. Save. The builder compiles the script and shows each error with its line.

## Step 6. The preview

In Agentforce Builder, open the **Preview** panel. It has two modes, Simulate and Live Test (Trailhead, ©2026). Use the mode that runs the real Apex actions [to confirm which one in this org]. Type the questions of the three scenarios in `README.md`.

## Step 7. Change the scenario

Setup → **Custom Settings** → **Servicing Demo Settings** → **Manage** → **Edit** on the default organization level value → change the checkboxes → **Save**. Then start a NEW preview conversation: each read happens one time in a session.

| Scenario | Logged In Customer Id | Live Read Down | Change No Reply |
|---|---|---|---|
| 1. The normal status | 1001 | off | off |
| 2. The live read is down | 1001 | **on** | off |
| 3. The change is not confirmed | 1001 | off | **on** |
| Identity not proven | 9999, or empty | off | off |

## Step 8. Show the record for the service rep

App Launcher → **Cases** → the newest case with the Subject `Servicing demo handoff: ...` → the **Description**. It starts with "INTERNAL RECORD FOR THE SERVICE REP" and gives the exit cause first, then the change, the identity and each source with its state.
