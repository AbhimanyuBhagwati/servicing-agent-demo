/**
 * The source of the bills for action 3, "Get the billing history".
 *
 * REAL in this demo: a fixed Data 360 query on the data lake object
 * Billing_History_Demo__dll. A Data 360 data stream fills it from a file upload of
 * a billing export (data360/billing_history.csv, test data). The time of the data
 * is the last refresh of that data stream, not the time of the read.
 *
 * In production the same action reads a Data 360 object that is federated to
 * Snowflake (Zero Copy), with the filter on the customer ID pushed down. This demo
 * has no Snowflake.
 *
 * A Data 360 query from Apex counts as a callout. This action writes nothing, so no
 * DML comes before it. Apex tests cannot query Data 360, so the tests set a fake
 * source with the stub rows (see ServicingDemoGetBillingHistoryTest).
 */
public with sharing class ServicingDemoBillingSource {

    public static final String DATA_LAKE_OBJECT = 'Billing_History_Demo__dll';
    public static final String DATA_STREAM_NAME = 'Billing History Demo';
    public static final String SOURCE_TEXT = 'Data 360: data stream "Billing History Demo" (a file upload of a billing export, test data; in production, Zero Copy federation to Snowflake)';

    /** The contract of a source of bills. */
    public interface Source {
        List<ServicingDemoStubData.Bill> billsFor(String customerId);
        Datetime loadTime();
        String sourceText();
    }

    /** Test only: a fake source in place of Data 360. */
    @TestVisible
    static Source testSource;

    public static Source current() {
        return testSource != null ? testSource : new Data360Source();
    }

    /** The real source: Data 360. */
    public class Data360Source implements Source {

        public String sourceText() {
            return SOURCE_TEXT;
        }

        /** The last refresh of the data stream: the time of the data. Null when there is no stream. */
        public Datetime loadTime() {
            String streamName = DATA_STREAM_NAME;
            List<SObject> rows = Database.query(
                'SELECT LastRefreshDate FROM DataStream WHERE Name = :streamName LIMIT 1');
            return rows.isEmpty() ? null : (Datetime) rows[0].get('LastRefreshDate');
        }

        /** A fixed query. Only a customer ID of digits goes into the SQL text. */
        public List<ServicingDemoStubData.Bill> billsFor(String customerId) {
            List<ServicingDemoStubData.Bill> bills = new List<ServicingDemoStubData.Bill>();
            if (String.isBlank(customerId) || !Pattern.matches('[0-9]{1,20}', customerId)) {
                return bills;
            }
            ConnectApi.CdpQueryInput query = new ConnectApi.CdpQueryInput();
            query.sql = 'SELECT customer_id__c, bill_period__c, amount__c, currency__c, bill_status__c, due_date__c'
                + ' FROM ' + DATA_LAKE_OBJECT
                + ' WHERE customer_id__c = \'' + customerId + '\''
                + ' ORDER BY bill_period__c';
            ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(query);
            Map<String, Integer> columns = new Map<String, Integer>();
            for (String name : output.metadata.keySet()) {
                columns.put(name, output.metadata.get(name).placeInOrder);
            }
            for (ConnectApi.CdpQueryV2Row row : output.data) {
                bills.add(toBill(row.rowData, columns));
            }
            return bills;
        }
    }

    /** One row of the query as a bill of the demo. */
    @TestVisible
    static ServicingDemoStubData.Bill toBill(List<Object> values, Map<String, Integer> columns) {
        ServicingDemoStubData.Bill b = new ServicingDemoStubData.Bill();
        b.customerId = text(values, columns, 'customer_id__c');
        b.period = text(values, columns, 'bill_period__c');
        String amount = text(values, columns, 'amount__c');
        String amountText = String.isBlank(amount) ? '' : Decimal.valueOf(amount).setScale(2).toPlainString();
        b.amount = (amountText + ' ' + text(values, columns, 'currency__c')).trim();
        b.status = text(values, columns, 'bill_status__c');
        String due = text(values, columns, 'due_date__c');
        b.dueDate = String.isBlank(due) ? '' : ServicingDemoResult.dateText(Date.valueOf(due.left(10)));
        return b;
    }

    private static String text(List<Object> values, Map<String, Integer> columns, String name) {
        Integer i = columns.get(name);
        if (i == null || values == null || i >= values.size() || values[i] == null) {
            return '';
        }
        return String.valueOf(values[i]).trim();
    }
}
