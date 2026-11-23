/**
 * DEMO STUB: replaces Check Availability for Routing and the service hours.
 *
 * Action 7 of the demo specification, "Examine the way to a person"
 * (step H2 of the handoff in design/06 §7). It always returns "case only":
 * this Developer Edition org has no Omni-Channel queue, no service reps
 * online and no messaging connection, so the AI agent does not use the one
 * escalation attempt for a way that cannot work (H5b).
 *
 * In production this is a flow or Apex action that examines the service
 * hours and uses Check Availability for Routing (R10, snippet only), with a
 * queue limit that contact-center operations set [Test T7].
 *
 * The next step text comes from code, not from the model, because the offer
 * of a next step is a promise. The text is invented for the demo [A]; which
 * next step the client can keep is open (design/06 D5).
 *
 * Results: FOUND (the check answered: case only); NOT_AVAILABLE (an error,
 * caught; never thrown, R02).
 */
public with sharing class ServicingDemoCheckWayToPerson {

    public static final String SOURCE_TEXT = 'DEMO STUB for Check Availability for Routing and the service hours';
    public static final String CASE_ONLY = 'CASE_ONLY';
    public static final String NEXT_STEP_TEXT =
        'A service rep works on the case from the case queue. Keep the case number. If you call us, give the case number.';

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Exit cause' description='The cause of the exit to a person' required=false)
        public String exitCause;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND or NOT_AVAILABLE')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The queue that was examined')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The time of the check')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this read')
        public String readTime = '';
        @InvocableVariable(label='Route open' description='True when a service rep can take the chat now')
        public Boolean routeOpen = false;
        @InvocableVariable(label='Way to a person' description='CASE_ONLY in this demo')
        public String wayToPerson = '';
        @InvocableVariable(label='Next step text' description='The true next step to tell the customer')
        public String nextStepText = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Examine the way to a person'
        description='DEMO STUB for Check Availability for Routing and the service hours. Always returns case only in this org.'
    )
    public static List<Response> checkWayToPerson(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }
        for (Request req : requests) {
            Response res = new Response();
            res.dataSource = SOURCE_TEXT;
            res.readTime = ServicingDemoResult.nowText();
            try {
                if (forceError) {
                    throw new ServicingDemoResult.DemoException('forced for a test');
                }
                res.resultCode = ServicingDemoResult.FOUND;
                res.causeCode = 'NO_OMNI_CHANNEL_IN_DEMO_ORG';
                res.recordRef = 'No queue for chats in this org';
                res.dataTime = res.readTime;
                res.routeOpen = false;
                res.wayToPerson = CASE_ONLY;
                res.nextStepText = NEXT_STEP_TEXT;
            } catch (Exception e) {
                res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
                res.causeCode = ServicingDemoResult.causeFrom(e);
                res.routeOpen = false;
                res.wayToPerson = CASE_ONLY;
                res.nextStepText = NEXT_STEP_TEXT;
            }
            responses.add(res);
        }
        return responses;
    }
}