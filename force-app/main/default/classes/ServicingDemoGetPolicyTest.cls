@IsTest
private class ServicingDemoGetPolicyTest {

    private static ServicingDemoGetPolicy.Response ask(String question) {
        ServicingDemoGetPolicy.Request req = new ServicingDemoGetPolicy.Request();
        req.questionText = question;
        return ServicingDemoGetPolicy.getPolicy(new List<ServicingDemoGetPolicy.Request>{ req })[0];
    }

    @IsTest
    static void foundForAReturnQuestion() {
        ServicingDemoGetPolicy.Response res = ask('What happens with my router when I cancel?');
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals('Equipment return policy', res.policyTitle);
        System.assertEquals('4', res.policyVersion);
        System.assertEquals('2026-09-01', res.policyStartDate);
        System.assertEquals('POL-EQUIP-01 version 4', res.recordRef);
        System.assert(res.policyText.contains('30 days'));
    }

    @IsTest
    static void foundForAPlanQuestion() {
        System.assertEquals('Plan change policy', ask('Can I change my plan?').policyTitle);
    }

    @IsTest
    static void nothingThereForAnotherSubject() {
        ServicingDemoGetPolicy.Response res = ask('Do you sell satellite TV?');
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, res.resultCode);
        System.assertEquals('NO_APPROVED_POLICY_TEXT', res.causeCode);
        System.assertEquals('', res.policyText);
    }

    @IsTest
    static void nothingThereForAnEmptyQuestion() {
        ServicingDemoGetPolicy.Response res = ask(null);
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, res.resultCode);
        System.assertEquals('EMPTY_QUESTION', res.causeCode);
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoGetPolicy.forceError = true;
        ServicingDemoGetPolicy.Response res = ask('router');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoGetPolicy.getPolicy(null).size());
    }
}
