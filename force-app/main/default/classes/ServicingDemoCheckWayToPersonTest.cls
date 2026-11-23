@IsTest
private class ServicingDemoCheckWayToPersonTest {

    private static ServicingDemoCheckWayToPerson.Response check() {
        ServicingDemoCheckWayToPerson.Request req = new ServicingDemoCheckWayToPerson.Request();
        req.exitCause = 'CUSTOMER_REQUEST';
        return ServicingDemoCheckWayToPerson.checkWayToPerson(
            new List<ServicingDemoCheckWayToPerson.Request>{ req })[0];
    }

    @IsTest
    static void caseOnlyInThisOrg() {
        ServicingDemoCheckWayToPerson.Response res = check();
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals(false, res.routeOpen);
        System.assertEquals('CASE_ONLY', res.wayToPerson);
        System.assertEquals('NO_OMNI_CHANNEL_IN_DEMO_ORG', res.causeCode);
        System.assertEquals(ServicingDemoCheckWayToPerson.NEXT_STEP_TEXT, res.nextStepText);
    }

    @IsTest
    static void notAvailableOnAnErrorStillGivesCaseOnly() {
        ServicingDemoCheckWayToPerson.forceError = true;
        ServicingDemoCheckWayToPerson.Response res = check();
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals(false, res.routeOpen);
        System.assertEquals('CASE_ONLY', res.wayToPerson);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoCheckWayToPerson.checkWayToPerson(null).size());
    }
}
