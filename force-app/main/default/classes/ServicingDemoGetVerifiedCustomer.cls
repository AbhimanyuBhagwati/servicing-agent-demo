/**
 * DEMO STUB: replaces User Verification and a linked variable.
 *
 * Action 1 of the demo specification, "Get the verified customer".
 * Way A (the script uses it): the action reads the customer ID of the test
 * customer that is "logged in" from the demo setting
 * Servicing_Demo_Settings__c.Logged_In_Customer_Id__c.
 * Way B (a test only): the script binds contextCustomerId from a session
 * variable that the CLI preview sets with --context-variables. See README.
 * In both ways the action checks that one Account has that customer ID in its
 * standard field Account Number.
 *
 * In production the customer ID comes from the verified messaging session
 * (Enhanced Chat User Verification, R19) as a linked variable (R21); nothing in
 * the AI agent can change it. The model never sets the customer ID here either:
 * the script calls this action as a fixed step.
 *
 * Results: FOUND; NOTHING_THERE (nobody is logged in); HELD_BACK (no customer
 * record for that ID); NOT_AVAILABLE (an error, caught; never thrown, R02).
 */
public with sharing class ServicingDemoGetVerifiedCustomer {

    public static final String SOURCE_TEXT = 'DEMO STUB for User Verification: the demo setting Logged In Customer Id';

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Session reference' description='The messaging session ID, if there is one. Empty in a builder preview.' required=false)
        public String sessionRef;

        @InvocableVariable(label='Context customer ID' description='Way B only (a test): a customer ID from a session variable that the preview sets. Empty in way A.' required=false)
        public String contextCustomerId;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE, NOT_AVAILABLE or HELD_BACK')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The Account of the customer')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The time of the value')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this read')
        public String readTime = '';
        @InvocableVariable(label='Customer ID' description='The verified customer ID. Empty unless the result is FOUND.')
        public String customerId = '';
        @InvocableVariable(label='Identity proof' description='How the identity was proven in this demo')
        public String identityProof = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Get the verified customer'
        description='DEMO STUB for User Verification and a linked variable. Returns the customer ID of the test customer that the demo setting marks as logged in.'
    )
    public static List<Response> getVerifiedCustomer(List<Request> requests) {
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
        res.dataSource = SOURCE_TEXT;
        res.readTime = ServicingDemoResult.nowText();
        try {
            if (forceError) {
                throw new ServicingDemoResult.DemoException('forced for a test');
            }
            String contextId = req == null ? '' : ServicingDemoResult.safe(req.contextCustomerId).trim();
            String customerId = String.isNotBlank(contextId) ? contextId : ServicingDemoResult.loggedInCustomerId();
            res.identityProof = String.isNotBlank(contextId)
                ? 'Session variable set by the preview (demo way B)'
                : 'Demo setting Logged In Customer Id (demo way A; stands in for the login of the app)';

            if (String.isBlank(customerId)) {
                res.resultCode = ServicingDemoResult.NOTHING_THERE;
                res.causeCode = 'NO_LOGIN_IN_DEMO';
                return res;
            }

            List<Account> accounts = [
                SELECT Id
                FROM Account
                WHERE AccountNumber = :customerId
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            if (accounts.isEmpty()) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'NO_CUSTOMER_RECORD';
                return res;
            }

            res.resultCode = ServicingDemoResult.FOUND;
            res.customerId = customerId;
            res.recordRef = accounts[0].Id;
            res.dataTime = res.readTime;
        } catch (Exception e) {
            res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
            res.causeCode = ServicingDemoResult.causeFrom(e);
            res.customerId = '';
        }
        return res;
    }
}