@IsTest
private class ServicingDemoGetAppointmentStatusTest {

    private static ServicingDemoGetAppointmentStatus.Response callFor(String customerId) {
        ServicingDemoGetAppointmentStatus.Request req = new ServicingDemoGetAppointmentStatus.Request();
        req.customerId = customerId;
        return ServicingDemoGetAppointmentStatus.getAppointmentStatus(
            new List<ServicingDemoGetAppointmentStatus.Request>{ req })[0];
    }

    @IsTest
    static void foundForCustomerA() {
        ServicingDemoGetAppointmentStatus.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals('WO-1001-01', res.appointmentId);
        System.assertEquals('THU-1400', res.appointmentSlotCode);
        System.assert(res.appointmentText.contains('Thursday'));
        System.assert(res.freeSlots.contains('FRI-1000'));
        System.assertEquals(res.readTime, res.dataTime);
    }

    @IsTest
    static void nothingThereForCustomerB() {
        ServicingDemoGetAppointmentStatus.Response res = callFor('1002');
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, res.resultCode);
        System.assertEquals('NO_OPEN_APPOINTMENT', res.causeCode);
        System.assertEquals('', res.appointmentText);
    }

    @IsTest
    static void notAvailableWhenTheLiveReadIsDown() {
        ServicingDemoTestFactory.settings('1001', true, false);
        ServicingDemoGetAppointmentStatus.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('DEMO_SWITCH_LIVE_READ_DOWN', res.causeCode);
        System.assertEquals('', res.appointmentText);
    }

    @IsTest
    static void heldBackWithNoCustomerId() {
        ServicingDemoGetAppointmentStatus.Response res = callFor(' ');
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('NO_VERIFIED_CUSTOMER_ID', res.causeCode);
    }

    @IsTest
    static void heldBackForARowOfADifferentCustomer() {
        ServicingDemoStubData.rowCustomerIdOverride = '2002';
        ServicingDemoGetAppointmentStatus.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('CUSTOMER_MISMATCH', res.causeCode);
        System.assertEquals('', res.appointmentText);
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoGetAppointmentStatus.forceError = true;
        ServicingDemoGetAppointmentStatus.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoGetAppointmentStatus.getAppointmentStatus(null).size());
    }
}
