@IsTest
private class ServicingDemoGetVerifiedCustomerTest {

    private static ServicingDemoGetVerifiedCustomer.Response callWith(String contextCustomerId) {
        ServicingDemoGetVerifiedCustomer.Request req = new ServicingDemoGetVerifiedCustomer.Request();
        req.sessionRef = '';
        req.contextCustomerId = contextCustomerId;
        return ServicingDemoGetVerifiedCustomer.getVerifiedCustomer(
            new List<ServicingDemoGetVerifiedCustomer.Request>{ req })[0];
    }

    @IsTest
    static void foundFromTheSetting() {
        ServicingDemoTestFactory.settings('1001', false, false);
        Account a = ServicingDemoTestFactory.account('Demo Customer A', '1001');
        ServicingDemoGetVerifiedCustomer.Response res = callWith('');
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals('1001', res.customerId);
        System.assertEquals(String.valueOf(a.Id), res.recordRef);
        System.assert(res.identityProof.contains('way A'));
    }

    @IsTest
    static void foundFromTheContextVariable() {
        ServicingDemoTestFactory.settings('1001', false, false);
        ServicingDemoTestFactory.account('Demo Customer B', '1002');
        ServicingDemoGetVerifiedCustomer.Response res = callWith('1002');
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals('1002', res.customerId);
        System.assert(res.identityProof.contains('way B'));
    }

    @IsTest
    static void nothingThereWhenNobodyIsLoggedIn() {
        ServicingDemoGetVerifiedCustomer.Response res = callWith(null);
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, res.resultCode);
        System.assertEquals('NO_LOGIN_IN_DEMO', res.causeCode);
        System.assertEquals('', res.customerId);
    }

    @IsTest
    static void heldBackWhenNoCustomerRecord() {
        ServicingDemoTestFactory.settings('9999', false, false);
        ServicingDemoGetVerifiedCustomer.Response res = callWith('');
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('NO_CUSTOMER_RECORD', res.causeCode);
        System.assertEquals('', res.customerId);
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoGetVerifiedCustomer.forceError = true;
        ServicingDemoGetVerifiedCustomer.Response res = callWith('');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoGetVerifiedCustomer.getVerifiedCustomer(null).size());
    }
}
