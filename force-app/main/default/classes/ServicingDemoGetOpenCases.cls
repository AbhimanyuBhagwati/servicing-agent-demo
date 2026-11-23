/**
 * REAL: a fixed SOQL query on Case, with only public comments
 * (CaseComment.IsPublished = true).
 *
 * Action 4 of the demo specification, "Get the open cases". The production
 * part is the same: the cases in Salesforce (Service Cloud), read with a fixed
 * query that the model does not write (a rule of our design, design/06 §6).
 *
 * The query is keyed on the customer ID of the session, which lives in the
 * standard field Account.AccountNumber in this demo. The case read uses
 * WITH USER_MODE, so it operates with the permissions of the running user
 * (the agent user in production). A missing read permission on Case gives
 * NOT_AVAILABLE with a cause code, and not a silent "nothing there".
 * Internal comments (IsPublished = false) are never read.
 *
 * Results: FOUND; NOTHING_THERE (a live answer: no open case);
 * NOT_AVAILABLE (no access, or an error, caught; never thrown, R02);
 * HELD_BACK (no verified customer ID).
 */
public with sharing class ServicingDemoGetOpenCases {

    public static final String SOURCE_TEXT = 'Salesforce Case and public CaseComment (real query)';
    public static final Integer MAX_CASES = 5;

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
        @InvocableVariable(label='Record reference' description='The case numbers that were read')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The time of the value (live: the time of the read)')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this read')
        public String readTime = '';
        @InvocableVariable(label='Open case count' description='The number of open cases that were read (at most 5)')
        public String openCaseCount = '';
        @InvocableVariable(label='Case summary' description='The open cases, each with its number, subject, status, date and last public note')
        public String caseSummary = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Get the open cases'
        description='REAL fixed query on Case for the verified customer. Returns the open cases and only their public comments.'
    )
    public static List<Response> getOpenCases(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }
        String readTime = ServicingDemoResult.nowText();

        Set<String> customerIds = new Set<String>();
        for (Request req : requests) {
            String customerId = req == null ? '' : ServicingDemoResult.safe(req.customerId).trim();
            if (String.isNotBlank(customerId)) {
                customerIds.add(customerId);
            }
        }

        Map<String, List<Case>> casesByCustomer = new Map<String, List<Case>>();
        Map<Id, String> lastPublicNote = new Map<Id, String>();
        String sharedFailure = '';
        try {
            if (forceError) {
                throw new ServicingDemoResult.DemoException('forced for a test');
            }
            if (!customerIds.isEmpty()) {
                if (!Schema.sObjectType.Case.isAccessible()) {
                    sharedFailure = 'NO_READ_ACCESS_TO_CASE';
                } else {
                    // The fixed query. The model writes no part of it.
                    List<Case> cases = [
                        SELECT Id, CaseNumber, Subject, Status, CreatedDate, Account.AccountNumber
                        FROM Case
                        WHERE Account.AccountNumber IN :customerIds
                        AND IsClosed = false
                        WITH USER_MODE
                        ORDER BY CreatedDate DESC
                        LIMIT 200
                    ];
                    Set<Id> caseIds = new Set<Id>();
                    for (Case c : cases) {
                        String key = c.Account.AccountNumber;
                        if (!casesByCustomer.containsKey(key)) {
                            casesByCustomer.put(key, new List<Case>());
                        }
                        if (casesByCustomer.get(key).size() < MAX_CASES) {
                            casesByCustomer.get(key).add(c);
                            caseIds.add(c.Id);
                        }
                    }
                    if (!caseIds.isEmpty()) {
                        // Only public comments. Internal comments are never read.
                        for (CaseComment cc : [
                            SELECT Id, ParentId, CommentBody, CreatedDate
                            FROM CaseComment
                            WHERE ParentId IN :caseIds
                            AND IsPublished = true
                            ORDER BY CreatedDate DESC
                            LIMIT 500
                        ]) {
                            if (!lastPublicNote.containsKey(cc.ParentId)) {
                                lastPublicNote.put(cc.ParentId, ServicingDemoResult.cut(cc.CommentBody, 200));
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            sharedFailure = ServicingDemoResult.causeFrom(e);
        }

        for (Request req : requests) {
            Response res = new Response();
            res.dataSource = SOURCE_TEXT;
            res.readTime = readTime;
            String customerId = req == null ? '' : ServicingDemoResult.safe(req.customerId).trim();
            if (String.isBlank(customerId)) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'NO_VERIFIED_CUSTOMER_ID';
            } else if (String.isNotBlank(sharedFailure)) {
                res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
                res.causeCode = sharedFailure;
            } else {
                fill(res, casesByCustomer.get(customerId), lastPublicNote);
            }
            responses.add(res);
        }
        return responses;
    }

    private static void fill(Response res, List<Case> cases, Map<Id, String> lastPublicNote) {
        res.dataTime = res.readTime;
        if (cases == null || cases.isEmpty()) {
            res.resultCode = ServicingDemoResult.NOTHING_THERE;
            res.causeCode = 'NO_OPEN_CASE';
            res.openCaseCount = '0';
            return;
        }
        List<String> lines = new List<String>();
        List<String> numbers = new List<String>();
        for (Case c : cases) {
            String line = 'Case ' + c.CaseNumber + ': ' + ServicingDemoResult.cut(c.Subject, 120)
                + ' (status ' + c.Status + ', opened ' + c.CreatedDate.format('yyyy-MM-dd') + ')';
            if (lastPublicNote.containsKey(c.Id)) {
                line += '. Last public note: ' + lastPublicNote.get(c.Id);
            }
            lines.add(line);
            numbers.add(c.CaseNumber);
        }
        res.resultCode = ServicingDemoResult.FOUND;
        res.recordRef = String.join(numbers, ', ');
        res.openCaseCount = String.valueOf(cases.size());
        res.caseSummary = String.join(lines, ' | ');
    }
}