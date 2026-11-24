/**
 * The network status: an MCP client in Apex.
 *
 * REAL in this demo: one MCP "tools/call" (JSON-RPC 2.0 over Streamable HTTP) to the
 * MCP server NetworkOperationsDemo, through the named credential that its
 * registration in Agentforce Registry made (callout:NetworkOperationsDemo). The
 * server is a small demo server with test data (mcp-server/ in this repository). It
 * stands for the network operations system of the client.
 *
 * Why an Apex action and not the native MCP action of Agentforce: in this org
 * (Winter '27, tested 2026-11-24) a native MCP action does not run as a fixed step
 * (`run`) in Agent Script; it runs only when the model selects it, and in one test
 * the model answered without the read. A read that must happen needs a fixed step,
 * and a fixed step needs an action like this one. Apex also gives its own time
 * limit and a clean result on every failure.
 *
 * Results: FOUND, NOTHING_THERE, NOT_AVAILABLE or REFUSED, as the server gives them;
 * NOT_AVAILABLE for an HTTP error, a time-out, an MCP error or an answer that this
 * class cannot read; HELD_BACK with no customer ID. Never thrown (R02).
 */
public with sharing class ServicingDemoCheckNetworkStatus {

    public static final String NAMED_CREDENTIAL = 'NetworkOperationsDemo';
    public static final String TOOL_NAME = 'check_network_status';
    public static final String PROTOCOL_VERSION = '2025-06-18';
    public static final Integer TIME_LIMIT_MS = 10000;
    public static final String SOURCE_TEXT = 'MCP server NetworkOperationsDemo, tool check_network_status (a demo server with test data)';

    private static final Set<String> KNOWN_RESULTS = new Set<String>{
        ServicingDemoResult.FOUND, ServicingDemoResult.NOTHING_THERE,
        ServicingDemoResult.NOT_AVAILABLE, ServicingDemoResult.REFUSED
    };

    public class Request {
        @InvocableVariable(label='Customer ID' description='The verified customer ID of the session' required=true)
        public String customerId;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE, NOT_AVAILABLE, REFUSED or HELD_BACK')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The outage reference of the network operations system')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='When the network operations system last updated the record')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='When the network status was read')
        public String readTime = '';
        @InvocableVariable(label='Outage found' description='True when an open outage affects the area of the customer')
        public Boolean outageFound = false;
        @InvocableVariable(label='Area' description='The network area of the service of the customer')
        public String area = '';
        @InvocableVariable(label='Status text' description='The facts in one or two sentences, from the network operations system')
        public String statusText = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Check the network status (MCP)'
        description='REAL MCP tools/call to the MCP server NetworkOperationsDemo (a demo server with test data) through its named credential. Reads the network status of the area of the verified customer.'
    )
    public static List<Response> checkNetworkStatus(List<Request> requests) {
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
            String customerId = req == null ? '' : ServicingDemoResult.safe(req.customerId).trim();
            if (String.isBlank(customerId)) {
                return fail(res, ServicingDemoResult.HELD_BACK, 'NO_VERIFIED_CUSTOMER_ID');
            }

            HttpRequest call = new HttpRequest();
            call.setEndpoint('callout:' + NAMED_CREDENTIAL);
            call.setMethod('POST');
            call.setTimeout(TIME_LIMIT_MS);
            call.setHeader('Content-Type', 'application/json');
            call.setHeader('Accept', 'application/json, text/event-stream');
            call.setHeader('MCP-Protocol-Version', PROTOCOL_VERSION);
            call.setBody(JSON.serialize(new Map<String, Object>{
                'jsonrpc' => '2.0',
                'id' => 1,
                'method' => 'tools/call',
                'params' => new Map<String, Object>{
                    'name' => TOOL_NAME,
                    'arguments' => new Map<String, Object>{ 'customer_id' => customerId }
                }
            }));
            HttpResponse answer = new Http().send(call);

            if (answer.getStatusCode() != 200) {
                return fail(res, ServicingDemoResult.NOT_AVAILABLE, 'MCP_HTTP_' + answer.getStatusCode());
            }
            Map<String, Object> body = readBody(answer);
            if (body == null) {
                return fail(res, ServicingDemoResult.NOT_AVAILABLE, 'MCP_BAD_ANSWER');
            }
            if (body.get('error') != null) {
                return fail(res, ServicingDemoResult.NOT_AVAILABLE, 'MCP_ERROR');
            }
            Map<String, Object> result = (Map<String, Object>) body.get('result');
            if (result == null || result.get('isError') == true) {
                return fail(res, ServicingDemoResult.NOT_AVAILABLE, 'MCP_TOOL_ERROR');
            }
            Map<String, Object> content = (Map<String, Object>) result.get('structuredContent');
            if (content == null) {
                return fail(res, ServicingDemoResult.NOT_AVAILABLE, 'MCP_NO_STRUCTURED_CONTENT');
            }
            String code = text(content, 'resultCode');
            if (!KNOWN_RESULTS.contains(code)) {
                return fail(res, ServicingDemoResult.NOT_AVAILABLE, 'MCP_UNKNOWN_RESULT');
            }
            res.resultCode = code;
            res.causeCode = text(content, 'causeCode');
            res.recordRef = text(content, 'recordRef');
            res.outageFound = content.get('outageFound') == true;
            res.area = text(content, 'area');
            res.dataTime = text(content, 'dataTime');
            if (String.isNotBlank(text(content, 'readTime'))) {
                res.readTime = text(content, 'readTime');
            }
            res.statusText = text(content, 'statusText');
        } catch (Exception e) {
            // A time-out or a refused connection is a CalloutException: a clean result, never thrown.
            return fail(res, ServicingDemoResult.NOT_AVAILABLE, ServicingDemoResult.causeFrom(e));
        }
        return res;
    }

    /** The JSON-RPC answer: plain JSON, or one Server-Sent Events message ("data: {...}"). */
    @TestVisible
    static Map<String, Object> readBody(HttpResponse answer) {
        String raw = answer.getBody();
        if (String.isBlank(raw)) {
            return null;
        }
        String payload = raw.trim();
        if (!payload.startsWith('{')) {
            payload = null;
            for (String line : raw.split('\n')) {
                if (line.startsWith('data:')) {
                    payload = line.substringAfter('data:').trim();
                }
            }
        }
        if (String.isBlank(payload)) {
            return null;
        }
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(payload);
        } catch (Exception e) {
            return null;
        }
    }

    private static Response fail(Response res, String code, String cause) {
        res.resultCode = code;
        res.causeCode = cause;
        res.recordRef = '';
        res.outageFound = false;
        res.area = '';
        res.dataTime = '';
        res.statusText = '';
        return res;
    }

    private static String text(Map<String, Object> values, String key) {
        Object v = values.get(key);
        return v == null ? '' : String.valueOf(v).trim();
    }
}