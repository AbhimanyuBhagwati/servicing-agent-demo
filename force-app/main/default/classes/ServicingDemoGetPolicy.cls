/**
 * DEMO STUB: replaces the retriever on the search index.
 *
 * Action 5 of the demo specification, "Get the policy".
 * It holds two invented policy texts, each with a version and a start date,
 * in ServicingDemoStubData, and finds one by keywords in the customer's
 * question. Any other subject gives NOTHING_THERE: the AI agent then has no
 * approved policy text and does not answer from its own knowledge.
 *
 * In production this is a retriever action on a search index in Data 360
 * (a hybrid search), with prefilters that the builder sets, over documents
 * that an owner approved for customers. This demo has no search index and no
 * semantic search: a keyword match only.
 *
 * Results: FOUND; NOTHING_THERE (no approved policy text for the question);
 * NOT_AVAILABLE (an error, caught; never thrown, R02).
 */
public with sharing class ServicingDemoGetPolicy {

    public static final String SOURCE_TEXT = 'DEMO STUB for the retriever on the search index (two approved test texts)';

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Question text' description='The question of the customer, as the customer wrote it' required=false)
        public String questionText;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE or NOT_AVAILABLE')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The policy document and its version')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The start date of the approved version')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this read')
        public String readTime = '';
        @InvocableVariable(label='Policy title' description='The title of the approved policy document')
        public String policyTitle = '';
        @InvocableVariable(label='Policy version' description='The version of the approved policy document')
        public String policyVersion = '';
        @InvocableVariable(label='Policy start date' description='The date from which this version applies')
        public String policyStartDate = '';
        @InvocableVariable(label='Policy text' description='The approved text that the answer must use')
        public String policyText = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Get the policy'
        description='DEMO STUB for the retriever on the search index. Returns one approved policy text with its version and start date, or NOTHING_THERE.'
    )
    public static List<Response> getPolicy(List<Request> requests) {
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
            String question = req == null ? '' : ServicingDemoResult.safe(req.questionText);
            if (String.isBlank(question)) {
                res.resultCode = ServicingDemoResult.NOTHING_THERE;
                res.causeCode = 'EMPTY_QUESTION';
                return res;
            }
            ServicingDemoStubData.Policy p = ServicingDemoStubData.findPolicy(question);
            if (p == null) {
                res.resultCode = ServicingDemoResult.NOTHING_THERE;
                res.causeCode = 'NO_APPROVED_POLICY_TEXT';
                return res;
            }
            res.resultCode = ServicingDemoResult.FOUND;
            res.recordRef = p.policyId + ' version ' + p.version;
            res.dataTime = p.startDate;
            res.policyTitle = p.title;
            res.policyVersion = p.version;
            res.policyStartDate = p.startDate;
            res.policyText = p.text;
        } catch (Exception e) {
            res = new Response();
            res.dataSource = SOURCE_TEXT;
            res.readTime = ServicingDemoResult.nowText();
            res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
            res.causeCode = ServicingDemoResult.causeFrom(e);
        }
        return res;
    }
}