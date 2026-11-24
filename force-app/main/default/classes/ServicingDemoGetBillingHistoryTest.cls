@IsTest
private class ServicingDemoGetBillingHistoryTest {

    /** Apex tests cannot query Data 360: this fake source gives the stub rows. */
    private class StubSource implements ServicingDemoBillingSource.Source {
        public Boolean noStream = false;
        public List<ServicingDemoStubData.Bill> billsFor(String customerId) {
            return ServicingDemoStubData.billsFor(customerId);
        }
        public Datetime loadTime() {
            return noStream ? null : ServicingDemoStubData.loadTime();
        }
        public String sourceText() {
            return 'test source';
        }
    }

    private static ServicingDemoGetBillingHistory.Response callFor(String customerId) {
        if (ServicingDemoBillingSource.testSource == null) {
            ServicingDemoBillingSource.testSource = new StubSource();
        }
        ServicingDemoGetBillingHistory.Request req = new ServicingDemoGetBillingHistory.Request();
        req.customerId = customerId;
        return ServicingDemoGetBillingHistory.getBillingHistory(
            new List<ServicingDemoGetBillingHistory.Request>{ req })[0];
    }

    @IsTest
    static void foundForCustomerAWithTheAppointmentCopy() {
        ServicingDemoGetBillingHistory.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assert(res.billingSummary.contains('64.50 USD'));
        System.assertEquals('64.50 USD', res.lastBillAmount);
        System.assertEquals('Open', res.lastBillStatus);
        System.assertEquals(true, res.appointmentCopyFound);
        System.assert(res.appointmentCopyText.contains('Thursday'));
        System.assertEquals(ServicingDemoResult.timeText(ServicingDemoStubData.loadTime()), res.dataTime);
    }

    @IsTest
    static void foundForCustomerBWithNoAppointmentCopy() {
        ServicingDemoGetBillingHistory.Response res = callFor('1002');
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals(false, res.appointmentCopyFound);
    }

    @IsTest
    static void nothingThereForAnUnknownCustomer() {
        ServicingDemoGetBillingHistory.Response res = callFor('9999');
        System.assertEquals(ServicingDemoResult.NOTHING_THERE, res.resultCode);
        System.assertEquals('NO_BILLS_IN_COPY', res.causeCode);
    }

    @IsTest
    static void heldBackWithNoCustomerId() {
        ServicingDemoGetBillingHistory.Response res = callFor('');
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('NO_VERIFIED_CUSTOMER_ID', res.causeCode);
    }

    @IsTest
    static void heldBackWhenTheCopyIsTooOld() {
        ServicingDemoStubData.loadTimeOverride = Datetime.now().addHours(-30);
        ServicingDemoGetBillingHistory.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('COPY_OLDER_THAN_AGE_LIMIT', res.causeCode);
        System.assertEquals(false, res.appointmentCopyFound);
    }

    @IsTest
    static void heldBackForRowsOfADifferentCustomer() {
        ServicingDemoStubData.rowCustomerIdOverride = '2002';
        ServicingDemoGetBillingHistory.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.HELD_BACK, res.resultCode);
        System.assertEquals('CUSTOMER_MISMATCH', res.causeCode);
        System.assertEquals('', res.billingSummary);
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoGetBillingHistory.forceError = true;
        ServicingDemoGetBillingHistory.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
        System.assertEquals(false, res.appointmentCopyFound);
    }

    @IsTest
    static void notAvailableWhenThereIsNoDataStream() {
        StubSource fake = new StubSource();
        fake.noStream = true;
        ServicingDemoBillingSource.testSource = fake;
        ServicingDemoGetBillingHistory.Response res = callFor('1001');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('NO_DATA_STREAM', res.causeCode);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoGetBillingHistory.getBillingHistory(null).size());
    }
}
