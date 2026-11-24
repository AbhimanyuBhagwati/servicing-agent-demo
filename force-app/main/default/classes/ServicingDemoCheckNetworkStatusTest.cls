@IsTest
private class ServicingDemoCheckNetworkStatusTest {

    private class Answer implements HttpCalloutMock {
        Integer status;
        String body;
        String contentType;
        Boolean throwIt = false;
        Answer(Integer status, String body, String contentType) {
            this.status = status;
            this.body = body;
            this.contentType = contentType;
        }
        public HttpResponse respond(HttpRequest req) {
            if (throwIt) {
                throw new CalloutException('Read timed out');
            }
            System.assertEquals('callout:NetworkOperationsDemo', req.getEndpoint());
            Map<String, Object> rpc = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            System.assertEquals('tools/call', rpc.get('method'));
            HttpResponse res = new HttpResponse();
            res.setStatusCode(status);
            res.setHeader('Content-Type', contentType);
            res.setBody(body);
            return res;
        }
    }

    private static String toolAnswer(String code, String cause, Boolean outage) {
        return JSON.serialize(new Map<String, Object>{
            'jsonrpc' => '2.0', 'id' => 1,
            'result' => new Map<String, Object>{
                'isError' => false,
                'structuredContent' => new Map<String, Object>{
                    'resultCode' => code, 'causeCode' => cause, 'recordRef' => outage ? 'INC-4471' : '',
                    'outageFound' => outage, 'area' => 'NORTH-7', 'dataTime' => '2026-11-24 04:15 EST',
                    'readTime' => '2026-11-24 04:35 EST', 'statusText' => 'Open outage INC-4471 in area NORTH-7.'
                }
            }
        });
    }

    private static ServicingDemoCheckNetworkStatus.Response callFor(String customerId, Answer mock) {
        if (mock != null) {
            Test.setMock(HttpCalloutMock.class, mock);
        }
        ServicingDemoCheckNetworkStatus.Request req = new ServicingDemoCheckNetworkStatus.Request();
        req.customerId = customerId;
        Test.startTest();
        ServicingDemoCheckNetworkStatus.Response res = ServicingDemoCheckNetworkStatus.checkNetworkStatus(
            new List<ServicingDemoCheckNetworkStatus.Request>{ req })[0];
        Test.stopTest();
        return res;
    }

    @IsTest
    static void foundGivesTheFactsOfTheServer() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001',
            new Answer(200, toolAnswer('FOUND', 'OPEN_OUTAGE', true), 'application/json'));
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals('INC-4471', res.recordRef);
        System.assertEquals(true, res.outageFound);
        System.assertEquals('2026-11-24 04:15 EST', res.dataTime);
        System.assertEquals('2026-11-24 04:35 EST', res.readTime);
        System.assert(res.statusText.contains('INC-4471'));
    }

    @IsTest
    static void anAnswerAsServerSentEventsIsRead() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1002',
            new Answer(200, 'event: message\ndata: ' + toolAnswer('NOTHING_THERE', 'NO_OPEN_OUTAGE', false) + '\n\n',
                'text/event-stream'));
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, res.resultCode);
        System.assertEquals(false, res.outageFound);
    }

    @IsTest
    static void heldBackWithNoCustomerId() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('  ', null);
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('NO_VERIFIED_CUSTOMER_ID', res.causeCode);
    }

    @IsTest
    static void anHttpErrorIsNotAvailable() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001', new Answer(502, 'Bad Gateway', 'text/plain'));
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('MCP_HTTP_502', res.causeCode);
    }

    @IsTest
    static void aTimeOutIsNotAvailable() {
        Answer mock = new Answer(200, '', 'application/json');
        mock.throwIt = true;
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001', mock);
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_CALLOUTEXCEPTION', res.causeCode);
    }

    @IsTest
    static void anMcpErrorIsNotAvailable() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001', new Answer(200,
            '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Unknown tool"}}', 'application/json'));
        System.assertEquals('MCP_ERROR', res.causeCode);
    }

    @IsTest
    static void aToolErrorIsNotAvailable() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001', new Answer(200,
            '{"jsonrpc":"2.0","id":1,"result":{"isError":true,"content":[]}}', 'application/json'));
        System.assertEquals('MCP_TOOL_ERROR', res.causeCode);
    }

    @IsTest
    static void noStructuredContentIsNotAvailable() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001', new Answer(200,
            '{"jsonrpc":"2.0","id":1,"result":{"isError":false,"content":[]}}', 'application/json'));
        System.assertEquals('MCP_NO_STRUCTURED_CONTENT', res.causeCode);
    }

    @IsTest
    static void anUnknownResultIsNotAvailable() {
        ServicingDemoCheckNetworkStatus.Response res = callFor('1001',
            new Answer(200, toolAnswer('MAYBE', 'X', false), 'application/json'));
        System.assertEquals('MCP_UNKNOWN_RESULT', res.causeCode);
        System.assertEquals('', res.statusText);
    }

    @IsTest
    static void aBadAnswerIsNotAvailable() {
        System.assertEquals('MCP_BAD_ANSWER',
            callFor('1001', new Answer(200, 'not json', 'text/plain')).causeCode);
    }

    @IsTest
    static void readBodyHandlesEmptyAndBrokenAnswers() {
        HttpResponse empty = new HttpResponse();
        empty.setBody('');
        System.assertEquals(null, ServicingDemoCheckNetworkStatus.readBody(empty));
        HttpResponse broken = new HttpResponse();
        broken.setBody('{not json');
        System.assertEquals(null, ServicingDemoCheckNetworkStatus.readBody(broken));
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoCheckNetworkStatus.checkNetworkStatus(null).size());
    }
}
