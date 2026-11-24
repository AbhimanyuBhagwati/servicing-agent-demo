/**
 * Action 3 of the demo specification, "Get the billing history".
 *
 * The bills are REAL Data 360 data: a fixed query on the data lake object of the
 * data stream "Billing History Demo" (a file upload of a billing export, test
 * data; see ServicingDemoBillingSource). The time of the data is the last refresh
 * of that data stream. In production the same object is federated to Snowflake
 * (Zero Copy); this demo has no Snowflake.
 *
 * The copy of the appointment is still a STUB (ServicingDemoStubData). It serves
 * the rule for the old value of design/06 section 6: after a live read with the
 * result NOT_AVAILABLE, the AI agent can tell this value as the past, with its
 * time. The value and the time come from this result, and not from the model.
 *
 * Two rules of ours give HELD_BACK: the age limit (data older than
 * COPY_AGE_LIMIT_HOURS; in production the data platform owner sets it) and the
 * customer examination (a row of a different customer).
 *
 * Results: FOUND; NOTHING_THERE (no bills in the copy; the AI agent gives no
 * negative fact from the copy); NOT_AVAILABLE (an error or no data stream, caught;
 * never thrown, R02); HELD_BACK.
 */
public with sharing class ServicingDemoGetBillingHistory {

    public static final String SOURCE_TEXT = ServicingDemoBillingSource.SOURCE_TEXT;

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Customer ID' description='The verified customer ID of the session' required=true)
        public String customerId;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE, NOT_AVAILABLE or HELD_BACK')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The rows of the copy that were read')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The load time of the nightly copy')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this read')
        public String readTime = '';
        @InvocableVariable(label='Billing summary' description='The last bills of the customer, one line for each bill')
        public String billingSummary = '';
        @InvocableVariable(label='Last bill amount' description='The amount of the last bill')
        public String lastBillAmount = '';
        @InvocableVariable(label='Last bill status' description='The status of the last bill')
        public String lastBillStatus = '';
        @InvocableVariable(label='Appointment copy found' description='True when the copy has an appointment of this customer')
        public Boolean appointmentCopyFound = false;
        @InvocableVariable(label='Appointment copy text' description='The appointment as the nightly copy showed it at the load time')
        public String appointmentCopyText = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Get the billing history'
        description='REAL Data 360 query (data stream Billing History Demo, test data) for the bills of the verified customer, with the time of the data. The appointment copy is a stub. In production: Zero Copy federation to Snowflake.'
    )
    public static List<Response> getBillingHistory(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }
        for (Request req : requests) {
            responses.add(evaluate(req));
        }
        return responses;
    }

    private static Response evaluate(Request req) {
        Response res = new Response();
        ServicingDemoBillingSource.Source source = ServicingDemoBillingSource.current();
        res.dataSource = source.sourceText();
        res.readTime = ServicingDemoResult.nowText();
        try {
            if (forceError) {
                throw new ServicingDemoResult.DemoException('forced for a test');
            }
            String customerId = req == null ? '' : ServicingDemoResult.safe(req.customerId).trim();
            if (String.isBlank(customerId)) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'NO_VERIFIED_CUSTOMER_ID';
                return res;
            }

            Datetime loadAt = source.loadTime();
            if (loadAt == null) {
                res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
                res.causeCode = 'NO_DATA_STREAM';
                return res;
            }
            res.dataTime = ServicingDemoResult.timeText(loadAt);
            Long ageHours = (Datetime.now().getTime() - loadAt.getTime()) / 3600000L;
            if (ageHours > ServicingDemoStubData.COPY_AGE_LIMIT_HOURS) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'COPY_OLDER_THAN_AGE_LIMIT';
                return res;
            }

            List<ServicingDemoStubData.Bill> bills = source.billsFor(customerId);
            ServicingDemoStubData.Appointment copyRow = ServicingDemoStubData.appointmentFor(customerId);

            // The customer examination: every row must carry the customer ID of the session.
            for (ServicingDemoStubData.Bill b : bills) {
                if (b.customerId != customerId) {
                    res.resultCode = ServicingDemoResult.HELD_BACK;
                    res.causeCode = 'CUSTOMER_MISMATCH';
                    return res;
                }
            }
            if (copyRow != null && copyRow.customerId != customerId) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'CUSTOMER_MISMATCH';
                return res;
            }

            if (copyRow != null) {
                res.appointmentCopyFound = true;
                res.appointmentCopyText = ServicingDemoStubData.appointmentText(copyRow);
            }

            if (bills.isEmpty()) {
                res.resultCode = ServicingDemoResult.NOTHING_THERE;
                res.causeCode = 'NO_BILLS_IN_COPY';
                return res;
            }

            List<String> lines = new List<String>();
            for (ServicingDemoStubData.Bill b : bills) {
                lines.add(ServicingDemoStubData.billText(b));
            }
            ServicingDemoStubData.Bill lastBill = bills[bills.size() - 1];
            res.resultCode = ServicingDemoResult.FOUND;
            res.recordRef = 'Copy rows for customer ' + customerId + ' (' + bills.size() + ' bills)';
            res.billingSummary = String.join(lines, '; ');
            res.lastBillAmount = lastBill.amount;
            res.lastBillStatus = lastBill.status;
        } catch (Exception e) {
            res = new Response();
            res.dataSource = source.sourceText();
            res.readTime = ServicingDemoResult.nowText();
            res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
            res.causeCode = ServicingDemoResult.causeFrom(e);
        }
        return res;
    }
}