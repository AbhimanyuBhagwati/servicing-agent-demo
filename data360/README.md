# Data 360: the billing history

Action 3 of the agent ("Get the billing history") reads the bills from Data 360. This folder holds the file of test bills, and the procedure to load it.

> **What it is, and what it is not.** It is one file upload of four invented bills into a Data 360 data stream, in a Developer Edition org. It is not a connection to a billing system or to Snowflake. In production, the same action reads a Data 360 object that is federated to Snowflake (Zero Copy).

## The file

[`billing_history.csv`](billing_history.csv):

| Field | Data type in Data 360 | Example |
|---|---|---|
| `bill_id` | Text (primary key) | `B-1001-2026-11` |
| `customer_id` | Text | `1001` |
| `bill_period` | Text | `2026-11` |
| `amount` | Number | `64.50` |
| `currency` | Text | `USD` |
| `bill_status` | Text | `Open` |
| `due_date` | Date | `2026-12-05` |
| `source_system` | Text | `Billing system (demo export)` |

Customer 1001 has three bills (the last bill is open). Customer 1002 has one paid bill.

## Create the data stream (one time)

1. Data 360 must be set up in the org: Setup, then Data Cloud Setup Home, then **Get Started**. This step can take some time.
2. Open the Data Streams tab (for example `/lightning/o/DataStream/list`), then **New**.
3. Select **File Upload**, then **Next**, then upload `billing_history.csv`.
4. Set these values:
   - Data Lake Object Label: `Billing History Demo`
   - Data Lake Object API Name: `Billing_History_Demo`
   - Category: **Other**
   - Primary Key: `bill_id`
   - On the tab Supported Fields, set the data type of `customer_id` and of `bill_period` to **Text**.
5. **Next**. Data Stream Name: `Billing History Demo`. Data Space: `default`. **Deploy**.
6. Wait until the data stream shows the status Active and the last run Success, with 4 records.
7. Assign the permission set **Data Cloud User** to the agent user. Without it, action 3 gives `NOT_AVAILABLE` with the cause `APEX_QUERYEXCEPTION`.

The Apex class `ServicingDemoBillingSource` uses these two names. If you change a name, change the class:

| Name | Constant |
|---|---|
| `Billing_History_Demo__dll` | `DATA_LAKE_OBJECT` |
| `Billing History Demo` | `DATA_STREAM_NAME` |

## Load the file again (before each demo)

The time of the data is the last refresh of the data stream. The design holds back a copy that is older than 26 hours (`HELD_BACK`, `COPY_OLDER_THAN_AGE_LIMIT`). A file upload is one load, so it becomes too old after one day.

Before a demo: open the data stream **Billing History Demo**, then **Update File**, and upload the same file again.
