# Data 360: the data of the Customer Insights agent

The second agent of this project, **Customer Insights (demo)**, answers questions of a store's staff about 10 customers. This folder holds its data: eight CSV files, one for each source system of an invented online store.

> **What it is, and what it is not.** All people, products, orders, tickets, returns, reviews and survey answers are invented. Each file is one Data 360 data stream from a file upload, in a Developer Edition org. The files stand for separate systems of a store; they are not connections to real systems.

## The eight sources

| File and Data 360 table | Source system it stands for | Rows | Primary key | What it holds |
|---|---|---|---|---|
| `Insights_Customers` | CRM | 10 | `customer_id` | Customer 1 to Customer 10: city, joined date, loyalty tier, marketing opt-in, preferred channel |
| `Insights_Products` | Product catalog | 12 | `product_id` | Name, category, supplier, price |
| `Insights_Orders` | Web shop | 39 | `order_id` | Date, status, carrier, promised date, delivered date, total |
| `Insights_Order_Lines` | Web shop | 47 | `line_id` | The products in each order, with quantity and price |
| `Insights_Tickets` | Help desk | 30 | `ticket_id` | Category, subject, priority, status, resolution, CSAT. 21 of 30 (70%) are resolved. |
| `Insights_Returns` | Warehouse returns system | 8 | `return_id` | Reason, status (Refunded, Pending, Rejected), refund |
| `Insights_Reviews` | Review site | 24 | `review_id` | Rating 1 to 5, title, text |
| `Insights_Surveys` | Survey tool | 8 | `response_id` | NPS score 0 to 10, comment |

The tables join on `customer_id`, `product_id` and `order_id`. Each row also has `source_system`.

## The patterns in the data

The data is small, so a person can check each answer. It also has patterns that an analyst can find:

| Pattern | Where it shows |
|---|---|
| One product has a quality problem | Volt Wireless Earbuds: 6 buyers, 5 returns, 6 tickets, average rating 1.67 |
| One carrier is late | QuickShip: 12 of 13 delivered orders late. ParcelPro: 1 of 24 late. One QuickShip order is in transit after its promised date. |
| Customers that can leave | Customer 4 (Gold): last order in May, 3 tickets not resolved, a refund pending since April, NPS 2. Customer 9: a rejected return, an escalated ticket, NPS 0. |
| A valuable customer with a problem | Customer 10: the highest spend, an escalated ticket for a damaged TV, NPS 5 |
| A sales opportunity | 4 customers bought the coffee machine; Customer 7 never bought coffee pods and has an open ticket "Which pods fit my coffee machine" |
| A guide is missing, not quality | Smart Thermostat: 3 how-to tickets, average rating 4.33 |

## Make the files again

```bash
python3 make_data.py
```

The script writes the eight CSV files from the records in it. It uses fixed values, so the files are the same each time.

## Load the files (one time)

For each file: Data Streams, then **New**, then **File Upload**. Upload the file. Set the Data Lake Object label and API name to the file name (for example `Insights_Customers`), the category to **Other**, and the primary key from the table above. Data Space `default`, then **Deploy**.

The Apex class `InsightsData360` holds the eight table names and data stream names. If you change a name, change the class.

The agent has no age limit on this data. To load a file again: open its data stream, then **Update File** (Full Refresh).
