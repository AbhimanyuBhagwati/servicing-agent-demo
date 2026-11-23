@IsTest
private class ServicingDemoGetOpenCasesTest {

    private static List<ServicingDemoGetOpenCases.Response> callFor(List<String> customerIds) {
        List<ServicingDemoGetOpenCases.Request> requests = new List<ServicingDemoGetOpenCases.Request>();
        for (String customerId : customerIds) {
            ServicingDemoGetOpenCases.Request req = new ServicingDemoGetOpenCases.Request();
            req.customerId = customerId;
            requests.add(req);
        }
        return ServicingDemoGetOpenCases.getOpenCases(requests);
    }

    @IsTest
    static void foundWithOnlyThePublicNote() {
        ServicingDemoTestFactory.customersWithCases();
        List<ServicingDemoGetOpenCases.Response> results = callFor(new List<String>{ '1001', '1002', '' });

        ServicingDemoGetOpenCases.Response a = results[0];
        System.assertEquals(ServicingDemoResult.FOUND, a.resultCode);
        System.assertEquals('2', a.openCaseCount);
        System.assert(a.caseSummary.contains('Slow internet in the evening'));
        System.assert(a.caseSummary.contains('A technician visit is booked for Thursday.'));
        System.assert(!a.caseSummary.contains('INTERNAL'), 'An internal note must never be read');

        ServicingDemoGetOpenCases.Response b = results[1];
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, b.resultCode);
        System.assertEquals('0', b.openCaseCount);

        ServicingDemoGetOpenCases.Response blank = results[2];
        System.assertEquals(ServicingDemoResult.HELD_BACK, blank.resultCode);
        System.assertEquals('NO_VERIFIED_CUSTOMER_ID', blank.causeCode);
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoGetOpenCases.forceError = true;
        ServicingDemoGetOpenCases.Response res = callFor(new List<String>{ '1001' })[0];
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoGetOpenCases.getOpenCases(null).size());
    }
}
