"""Make the test data of the Customer Insights demo: 10 invented customers of an
invented online store, in 8 CSV files. Each file stands for one source system.

All people, products, orders, tickets, returns, reviews and surveys are invented.
Run:  python3 make_data.py      (writes the CSV files next to this script)
"""
import csv
import datetime as dt
import pathlib

HERE = pathlib.Path(__file__).parent
D = dt.date.fromisoformat


def day(s, plus=0):
    return (D(s) + dt.timedelta(days=plus)).isoformat()


# ---------------------------------------------------------------- CRM: customers
CUSTOMERS = [
    # id,   name,          city,       joined,       tier,     opt-in, channel
    ("C01", "Customer 1", "Austin", "2024-03-12", "Gold", "Yes", "App"),
    ("C02", "Customer 2", "Denver", "2024-07-02", "Silver", "Yes", "Web"),
    ("C03", "Customer 3", "Seattle", "2025-01-20", "Silver", "No", "Web"),
    ("C04", "Customer 4", "Chicago", "2023-11-05", "Gold", "Yes", "App"),
    ("C05", "Customer 5", "Miami", "2025-06-14", "Bronze", "No", "Web"),
    ("C06", "Customer 6", "Boston", "2024-09-30", "Silver", "Yes", "App"),
    ("C07", "Customer 7", "Phoenix", "2025-03-08", "Bronze", "Yes", "Web"),
    ("C08", "Customer 8", "Atlanta", "2024-12-01", "Silver", "No", "App"),
    ("C09", "Customer 9", "Portland", "2025-08-19", "Bronze", "No", "Web"),
    ("C10", "Customer 10", "New York", "2023-05-22", "Gold", "Yes", "App"),
]

# ------------------------------------------------------- Product catalog: products
PRODUCTS = [
    # id,   name,                      category,      supplier,     price
    ("P01", "Aero Running Shoes", "Sportswear", "StrideWorks", 89.00),
    ("P02", "Trail Rain Jacket", "Sportswear", "StrideWorks", 120.00),
    ("P03", "Barista Coffee Machine", "Kitchen", "BrewHaus", 249.00),
    ("P04", "Coffee Pods 50 Pack", "Kitchen", "BrewHaus", 22.00),
    ("P05", "Smart Blender", "Kitchen", "MixMaster", 79.00),
    ("P06", "4K Smart TV 55 Inch", "Electronics", "Vistaline", 649.00),
    ("P07", "Volt Wireless Earbuds", "Electronics", "SoundCo", 59.00),
    ("P08", "Phone Fast Charger", "Electronics", "SoundCo", 25.00),
    ("P09", "Smart Thermostat", "Home", "HomeWell", 139.00),
    ("P10", "LED Desk Lamp", "Home", "Lumen and Co", 35.00),
    ("P11", "Yoga Mat", "Sportswear", "StrideWorks", 30.00),
    ("P12", "Air Purifier", "Home", "HomeWell", 199.00),
]
PRICE = {p[0]: p[4] for p in PRODUCTS}

# --------------------------------------------------------------- Web shop: orders
# id, customer, date, carrier, days late (None = not delivered), status, lines
# Promised date = order date + 3 days. QuickShip is late most of the time.
ORDERS = [
    ("O1001", "C01", "2026-01-15", "ParcelPro", 0, "Delivered", [("P03", 1), ("P04", 2)]),
    ("O1002", "C01", "2026-03-02", "ParcelPro", 0, "Delivered", [("P04", 3)]),
    ("O1003", "C01", "2026-05-20", "QuickShip", 3, "Delivered", [("P07", 1)]),
    ("O1004", "C01", "2026-07-11", "ParcelPro", 0, "Delivered", [("P04", 3), ("P10", 1)]),
    ("O1005", "C01", "2026-10-05", "ParcelPro", 0, "Delivered", [("P12", 1)]),
    ("O1006", "C02", "2026-02-08", "QuickShip", 4, "Delivered", [("P01", 1), ("P11", 1)]),
    ("O1007", "C02", "2026-04-18", "QuickShip", 2, "Delivered", [("P07", 1)]),
    ("O1008", "C02", "2026-06-22", "ParcelPro", 0, "Delivered", [("P02", 1)]),
    ("O1009", "C02", "2026-09-14", "ParcelPro", 0, "Delivered", [("P08", 2)]),
    ("O1010", "C03", "2026-03-10", "ParcelPro", 0, "Delivered", [("P09", 1)]),
    ("O1011", "C03", "2026-04-02", "ParcelPro", 0, "Delivered", [("P10", 2)]),
    ("O1012", "C03", "2026-08-25", "QuickShip", 3, "Delivered", [("P12", 1)]),
    ("O1013", "C04", "2026-01-05", "QuickShip", 6, "Delivered", [("P06", 1)]),
    ("O1014", "C04", "2026-02-14", "ParcelPro", 0, "Delivered", [("P05", 1)]),
    ("O1015", "C04", "2026-03-28", "QuickShip", 3, "Delivered", [("P07", 2)]),
    ("O1016", "C04", "2026-05-09", "QuickShip", 0, "Delivered", [("P01", 1), ("P11", 1)]),
    ("O1017", "C05", "2026-06-20", "ParcelPro", 0, "Delivered", [("P05", 1)]),
    ("O1018", "C05", "2026-07-30", "ParcelPro", None, "Cancelled", [("P08", 1)]),
    ("O1019", "C05", "2026-10-12", "ParcelPro", 0, "Delivered", [("P11", 1)]),
    ("O1020", "C06", "2026-02-20", "QuickShip", 4, "Delivered", [("P03", 1)]),
    ("O1021", "C06", "2026-04-15", "ParcelPro", 0, "Delivered", [("P04", 2)]),
    ("O1022", "C06", "2026-06-30", "ParcelPro", 0, "Delivered", [("P04", 2), ("P10", 1)]),
    ("O1023", "C06", "2026-09-28", "ParcelPro", 0, "Delivered", [("P04", 4)]),
    ("O1024", "C07", "2026-05-05", "ParcelPro", 0, "Delivered", [("P03", 1)]),
    ("O1025", "C07", "2026-07-19", "QuickShip", 3, "Delivered", [("P07", 1)]),
    ("O1026", "C08", "2026-01-28", "QuickShip", 3, "Delivered", [("P09", 1)]),
    ("O1027", "C08", "2026-03-18", "ParcelPro", 0, "Delivered", [("P12", 1)]),
    ("O1028", "C08", "2026-06-05", "ParcelPro", 0, "Delivered", [("P10", 1), ("P08", 1)]),
    ("O1029", "C08", "2026-08-16", "ParcelPro", 0, "Delivered", [("P02", 1)]),
    ("O1030", "C09", "2026-07-01", "QuickShip", 5, "Delivered", [("P05", 1)]),
    ("O1031", "C09", "2026-08-10", "QuickShip", 2, "Delivered", [("P07", 1)]),
    ("O1032", "C10", "2026-01-10", "ParcelPro", 0, "Delivered", [("P06", 1)]),
    ("O1033", "C10", "2026-02-25", "ParcelPro", 1, "Delivered", [("P12", 2)]),
    ("O1034", "C10", "2026-04-08", "ParcelPro", 0, "Delivered", [("P03", 1), ("P04", 2)]),
    ("O1035", "C10", "2026-06-12", "ParcelPro", 0, "Delivered", [("P04", 4)]),
    ("O1036", "C10", "2026-08-08", "ParcelPro", 0, "Delivered", [("P09", 2)]),
    ("O1037", "C10", "2026-10-28", "QuickShip", 4, "Delivered", [("P06", 1)]),
    ("O1038", "C10", "2026-11-15", "QuickShip", None, "In transit", [("P04", 4), ("P08", 1)]),
    ("O1039", "C08", "2026-10-02", "ParcelPro", 0, "Delivered", [("P07", 1)]),
]

# ------------------------------------------------------------ Help desk: tickets
# id, customer, order, product, opened, channel, category, subject, priority,
# status, resolved (date or ""), resolution, csat (1-5 or "")
TICKETS = [
    ("T01", "C01", "O1003", "P07", "2026-06-10", "Chat", "Product defect", "Left earbud does not charge", "High", "Resolved", "2026-06-11", "Return approved and refund issued", 5),
    ("T02", "C01", "O1003", "", "2026-05-25", "Email", "Late delivery", "Earbuds order is late", "Medium", "Resolved", "2026-05-26", "Delivered; apology and voucher", 4),
    ("T03", "C02", "O1006", "", "2026-02-15", "Email", "Late delivery", "Shoes and mat not delivered yet", "Medium", "Resolved", "2026-02-16", "Delivered; apology", 3),
    ("T04", "C02", "O1007", "P07", "2026-05-12", "Chat", "Product defect", "Earbuds keep disconnecting", "High", "Resolved", "2026-05-14", "Return approved and refund issued", 4),
    ("T05", "C03", "O1010", "P09", "2026-03-15", "Chat", "How-to", "Cannot pair thermostat with the app", "Low", "Resolved", "2026-03-15", "Sent the pairing steps", 5),
    ("T06", "C03", "O1012", "", "2026-08-31", "Email", "Late delivery", "Air purifier is three days late", "Medium", "Resolved", "2026-09-01", "Delivered; apology", 3),
    ("T07", "C04", "O1013", "", "2026-01-13", "Phone", "Late delivery", "TV not delivered after a week", "High", "Resolved", "2026-01-20", "Delivered after six days", 2),
    ("T08", "C04", "O1015", "P07", "2026-04-20", "Phone", "Product defect", "Both earbuds stopped working", "High", "Escalated", "", "", ""),
    ("T09", "C04", "O1016", "P01", "2026-05-18", "Email", "Wrong item", "Wrong shoe size delivered", "Medium", "Open", "", "", ""),
    ("T10", "C04", "O1015", "P07", "2026-07-02", "Phone", "Refund question", "Still waiting for the earbuds refund", "High", "Open", "", "", ""),
    ("T11", "C05", "O1018", "", "2026-07-31", "Email", "Billing", "Charged for a cancelled order", "Medium", "Resolved", "2026-08-02", "Charge reversed", 4),
    ("T12", "C05", "O1017", "P05", "2026-06-28", "Chat", "How-to", "Blender lid does not lock", "Low", "Resolved", "2026-06-28", "Sent the lid steps", 5),
    ("T13", "C06", "O1020", "P03", "2026-03-01", "Email", "Damaged item", "Box crushed, drip tray cracked", "High", "Resolved", "2026-03-03", "New drip tray sent", 5),
    ("T14", "C06", "O1020", "P03", "2026-09-30", "Chat", "How-to", "How to descale the coffee machine", "Low", "Resolved", "2026-09-30", "Sent the descaling guide", 5),
    ("T15", "C07", "O1025", "P07", "2026-08-05", "Chat", "Product defect", "Sound only in one ear", "High", "Resolved", "2026-08-07", "Return approved and refund issued", 3),
    ("T16", "C07", "O1024", "P03", "2026-11-18", "Email", "How-to", "Which pods fit my coffee machine", "Low", "Open", "", "", ""),
    ("T17", "C08", "O1026", "P09", "2026-02-03", "Chat", "How-to", "Thermostat schedule does not save", "Low", "Resolved", "2026-02-04", "Firmware update steps sent", 4),
    ("T18", "C08", "O1026", "", "2026-02-02", "Email", "Late delivery", "Thermostat is late", "Medium", "Resolved", "2026-02-03", "Delivered; apology", 3),
    ("T19", "C08", "O1029", "P02", "2026-08-20", "Email", "Wrong item", "Got size M, ordered L", "Medium", "Resolved", "2026-08-24", "Exchange by return", 4),
    ("T20", "C09", "O1030", "", "2026-07-09", "Phone", "Late delivery", "Blender five days late", "Medium", "Resolved", "2026-07-12", "Delivered; apology", 2),
    ("T21", "C09", "O1030", "P05", "2026-09-20", "Phone", "Refund question", "Why was my blender return rejected", "Medium", "Open", "", "", ""),
    ("T22", "C09", "O1031", "P07", "2026-09-02", "Chat", "Product defect", "Earbuds will not charge", "High", "Escalated", "", "", ""),
    ("T23", "C10", "O1036", "P09", "2026-08-12", "Chat", "How-to", "Thermostat app shows offline", "Low", "Resolved", "2026-08-13", "Wi-Fi reset steps sent", 4),
    ("T24", "C10", "O1037", "P06", "2026-11-04", "Phone", "Damaged item", "TV screen cracked on arrival", "High", "Escalated", "", "", ""),
    ("T25", "C10", "O1037", "P06", "2026-11-20", "Email", "Refund question", "Waiting for the replacement TV", "High", "Open", "", "", ""),
    ("T26", "C03", "", "", "2026-10-15", "Email", "Billing", "Discount code not applied", "Low", "Resolved", "2026-10-16", "Discount refunded", 4),
    ("T27", "C05", "O1019", "", "2026-10-12", "Chat", "Order change", "Change the delivery address", "Low", "Resolved", "2026-10-12", "Address changed", 5),
    ("T28", "C06", "O1023", "", "2026-06-01", "Email", "Billing", "Pods charged two times", "Medium", "Resolved", "2026-06-03", "Second charge reversed", 4),
    ("T29", "C02", "O1009", "P08", "2026-09-20", "Chat", "How-to", "Does the charger work with my phone", "Low", "Resolved", "2026-09-20", "Compatibility list sent", 5),
    ("T30", "C08", "", "P12", "2026-11-22", "Email", "Product question", "Is the air purifier filter in stock", "Low", "Open", "", "", ""),
]

# ------------------------------------------------------ Warehouse: returns
# id, order, customer, product, requested, reason, status, refund
RETURNS = [
    ("R01", "O1003", "C01", "P07", "2026-06-11", "Battery does not charge", "Refunded", 59.00),
    ("R02", "O1007", "C02", "P07", "2026-05-13", "Keeps disconnecting", "Refunded", 59.00),
    ("R03", "O1015", "C04", "P07", "2026-04-22", "Stopped working", "Pending", ""),
    ("R04", "O1025", "C07", "P07", "2026-08-06", "Sound only in one ear", "Refunded", 59.00),
    ("R05", "O1029", "C08", "P02", "2026-08-21", "Wrong size", "Refunded", 120.00),
    ("R06", "O1030", "C09", "P05", "2026-09-15", "Changed my mind", "Rejected", 0.00),
    ("R07", "O1031", "C09", "P07", "2026-09-03", "Will not charge", "Pending", ""),
    ("R08", "O1037", "C10", "P06", "2026-11-05", "Arrived damaged", "Pending", ""),
]

# --------------------------------------------------------- Review site: reviews
# id, customer, product, date, rating, title, text
REVIEWS = [
    ("V01", "C01", "P03", "2026-02-01", 5, "Great coffee every morning", "Easy to use and the coffee is great."),
    ("V02", "C01", "P07", "2026-06-12", 1, "Stopped charging", "The left earbud stopped charging after two weeks."),
    ("V03", "C01", "P12", "2026-10-25", 5, "Quiet and strong", "The air in my flat is much better."),
    ("V04", "C02", "P01", "2026-03-01", 4, "Comfortable", "Good shoes. Delivery was slow."),
    ("V05", "C02", "P07", "2026-05-15", 2, "Keeps disconnecting", "Sound is fine but the connection drops."),
    ("V06", "C02", "P02", "2026-07-10", 5, "Really waterproof", "Kept me dry on a long hike."),
    ("V07", "C03", "P09", "2026-04-01", 5, "Works well once set up", "Setup took a while, then it worked well."),
    ("V08", "C03", "P12", "2026-09-15", 4, "Good purifier", "Works well. It came late."),
    ("V09", "C04", "P07", "2026-04-25", 1, "Both stopped working", "Both earbuds stopped working within a month."),
    ("V10", "C04", "P06", "2026-01-25", 3, "Good TV, slow delivery", "The picture is good but delivery took a week extra."),
    ("V11", "C05", "P05", "2026-07-05", 4, "Strong blender", "Strong motor. The lid is tricky."),
    ("V12", "C06", "P03", "2026-03-10", 4, "Great machine, damaged box", "The machine is great. The box was damaged in transit."),
    ("V13", "C06", "P04", "2026-05-01", 5, "Good pods", "Good taste and a fair price."),
    ("V14", "C07", "P07", "2026-08-08", 2, "One side only", "Sound came from one ear only."),
    ("V15", "C07", "P03", "2026-06-01", 4, "Nice machine", "Makes good coffee."),
    ("V16", "C08", "P09", "2026-02-10", 4, "Confusing setup", "Setup was confusing, but it works now."),
    ("V17", "C08", "P12", "2026-04-01", 5, "Very good", "Quiet and the filter lasts long."),
    ("V18", "C08", "P02", "2026-09-01", 4, "Nice jacket", "Good jacket after the size exchange."),
    ("V19", "C08", "P07", "2026-10-20", 3, "Battery is weak", "Sound is OK but the battery is weak."),
    ("V20", "C09", "P05", "2026-09-22", 2, "Return was refused", "The blender is OK, but my return was refused."),
    ("V21", "C09", "P07", "2026-09-05", 1, "Will not charge", "The earbuds will not charge at all."),
    ("V22", "C10", "P06", "2026-11-06", 2, "Second TV arrived cracked", "My first TV was great. The second one arrived cracked."),
    ("V23", "C10", "P03", "2026-04-20", 5, "Best coffee machine", "Excellent machine for the price."),
    ("V24", "C10", "P09", "2026-08-20", 4, "Great once connected", "Great once the app connected."),
]

# ---------------------------------------------------------- Survey tool: NPS
# id, customer, date, score 0-10, comment
SURVEYS = [
    ("S01", "C01", "2026-10-20", 9, "Fast help when my earbuds failed."),
    ("S02", "C02", "2026-07-01", 7, "Delivery is slow, but support is good."),
    ("S03", "C03", "2026-09-10", 8, "Good products."),
    ("S04", "C04", "2026-07-15", 2, "Still no refund after months."),
    ("S05", "C06", "2026-10-02", 10, "Love the coffee machine and the help."),
    ("S06", "C08", "2026-09-05", 8, "Easy exchange."),
    ("S07", "C09", "2026-09-25", 0, "Refund refused and the earbuds are broken."),
    ("S08", "C10", "2026-11-21", 5, "I like the store, but the TV problem takes too long."),
]

SOURCE = {
    "Insights_Customers": "CRM",
    "Insights_Products": "Product catalog",
    "Insights_Orders": "Web shop",
    "Insights_Order_Lines": "Web shop",
    "Insights_Tickets": "Help desk",
    "Insights_Returns": "Warehouse returns system",
    "Insights_Reviews": "Review site",
    "Insights_Surveys": "Survey tool",
}


def write(name, header, rows):
    path = HERE / f"{name}.csv"
    with path.open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(header + ["source_system"])
        for r in rows:
            w.writerow(list(r) + [SOURCE[name]])
    print(f"{path.name}: {len(rows)} rows")


def money(x):
    return f"{x:.2f}"


def main():
    write("Insights_Customers",
          ["customer_id", "customer_name", "city", "joined_date", "loyalty_tier", "marketing_opt_in", "preferred_channel"],
          CUSTOMERS)
    write("Insights_Products",
          ["product_id", "product_name", "product_category", "supplier", "unit_price"],
          [(a, b, c, d, money(e)) for a, b, c, d, e in PRODUCTS])

    orders, lines = [], []
    n = 0
    for oid, cid, odate, carrier, late, status, items in ORDERS:
        promised = day(odate, 3)
        delivered = "" if late is None else day(promised, late)
        total = sum(PRICE[p] * q for p, q in items)
        orders.append((oid, cid, odate, status, carrier, promised, delivered, money(total)))
        for p, q in items:
            n += 1
            lines.append((f"L{n:03d}", oid, cid, p, q, money(PRICE[p]), money(PRICE[p] * q)))
    write("Insights_Orders",
          ["order_id", "customer_id", "order_date", "order_status", "carrier", "promised_date", "delivered_date", "order_total"],
          orders)
    write("Insights_Order_Lines",
          ["line_id", "order_id", "customer_id", "product_id", "quantity", "unit_price", "line_total"],
          lines)
    write("Insights_Tickets",
          ["ticket_id", "customer_id", "order_id", "product_id", "opened_date", "ticket_channel", "ticket_category",
           "subject", "priority", "ticket_status", "resolved_date", "resolution", "csat_score"],
          TICKETS)
    write("Insights_Returns",
          ["return_id", "order_id", "customer_id", "product_id", "requested_date", "return_reason", "return_status", "refund_amount"],
          [r[:7] + (money(r[7]) if r[7] != "" else "",) for r in RETURNS])
    write("Insights_Reviews",
          ["review_id", "customer_id", "product_id", "review_date", "rating", "review_title", "review_text"],
          REVIEWS)
    write("Insights_Surveys",
          ["response_id", "customer_id", "response_date", "nps_score", "survey_comment"],
          SURVEYS)


if __name__ == "__main__":
    main()
