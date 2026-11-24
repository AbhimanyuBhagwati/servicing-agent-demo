@IsTest
private class ServicingDemoWriteHandoffCaseTest {

    private static ServicingDemoWriteHandoffCase.Request liveReadDownRequest(String sessionKey) {
        ServicingDemoWriteHandoffCase.Request req = new ServicingDemoWriteHandoffCase.Request();
        req.sessionKey = sessionKey;
        req.customerId = '1001';
        req.exitCause = 'SOURCE_FAILED_LIVE_READ';
        req.identityResult = 'FOUND';
        req.statusResult = 'NOT_AVAILABLE';
        req.statusCause = 'DEMO_SWITCH_LIVE_READ_DOWN';
        req.historyResult = 'FOUND';
        req.historyValue = 'Bill 2026-11: 64.50 USD, Open';
        req.historyDataTime = '2026-11-23 02:00 GMT';
        req.historyAppointmentCopy = 'Technician visit, Thursday, 14:00-16:00';
        return req;
    }

    private static ServicingDemoWriteHandoffCase.Response write(ServicingDemoWriteHandoffCase.Request req) {
        return ServicingDemoWriteHandoffCase.writeHandoffCase(
            new List<ServicingDemoWriteHandoffCase.Request>{ req })[0];
    }

    @IsTest
    static void writesOneCaseWithTheRecord() {
        Account a = ServicingDemoTestFactory.customersWithCases();
        ServicingDemoWriteHandoffCase.Response res = write(liveReadDownRequest(''));
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        System.assertEquals('CASE_WRITTEN', res.causeCode);
        System.assertNotEquals('', res.caseNumber);

        Case c = [SELECT Subject, Priority, Origin, AccountId, ContactId, Description FROM Case WHERE Id = :res.recordRef];
        System.assertEquals(a.Id, c.AccountId);
        System.assertNotEquals(null, c.ContactId);
        System.assertEquals('Medium', c.Priority);
        System.assert(c.Subject.contains('SOURCE_FAILED_LIVE_READ'));
        System.assert(c.Description.startsWith('INTERNAL RECORD FOR THE SERVICE REP'));
        System.assert(c.Description.contains('could not look: DEMO_SWITCH_LIVE_READ_DOWN'));
        System.assert(c.Description.contains('old (from the nightly copy of 2026-11-23 02:00 GMT)'));
        System.assert(c.Description.contains('5b. Appointment in the same nightly copy: old (from the nightly copy of 2026-11-23 02:00 GMT): Technician visit'));
        System.assert(c.Description.contains('6. Open cases (Salesforce, real query, public notes only): not asked'));
        System.assert(c.Description.contains('2. Change: not asked'));
        System.assert(c.Description.contains('proven by the login'));
    }

    @IsTest
    static void oneCaseForOneSession() {
        ServicingDemoTestFactory.customersWithCases();
        ServicingDemoWriteHandoffCase.Response firstCall = write(liveReadDownRequest('0Mw000000000001'));
        ServicingDemoWriteHandoffCase.Response secondCall = write(liveReadDownRequest('0Mw000000000001'));
        System.assertEquals(ServicingDemoResult.FOUND, secondCall.resultCode);
        System.assertEquals('CASE_ALREADY_WRITTEN_FOR_SESSION', secondCall.causeCode);
        System.assertEquals(firstCall.caseNumber, secondCall.caseNumber);
    }

    @IsTest
    static void changeNotConfirmedGetsHighPriority() {
        ServicingDemoTestFactory.customersWithCases();
        ServicingDemoWriteHandoffCase.Request req = new ServicingDemoWriteHandoffCase.Request();
        req.customerId = '1001';
        req.exitCause = 'CHANGE_NOT_CONFIRMED';
        req.identityResult = 'FOUND';
        req.statusResult = 'FOUND';
        req.statusValue = 'Technician visit, Thursday, 14:00-16:00';
        req.statusDataTime = '2026-11-23 10:00 GMT';
        req.changeResult = 'NOT_CONFIRMED';
        req.changeRequestKey = '1001-WO-1001-01:FRI1000';
        req.changeTimeBefore = 'Thursday, 14:00-16:00';
        req.changeTimeWanted = 'FRI-1000 = Friday, 10:00-12:00';
        req.changeReadAfter = 'Thursday, 14:00-16:00';
        ServicingDemoWriteHandoffCase.Response res = write(req);
        Case c = [SELECT Priority, Description FROM Case WHERE Id = :res.recordRef];
        System.assertEquals('High', c.Priority);
        System.assert(c.Description.contains('NOT CONFIRMED. Do not book a second time.'));
        System.assert(c.Description.contains('found: Technician visit'));
    }

    @IsTest
    static void identityNotProvenStillWritesACase() {
        ServicingDemoWriteHandoffCase.Request req = new ServicingDemoWriteHandoffCase.Request();
        req.exitCause = 'IDENTITY_NOT_PROVEN';
        req.identityResult = 'HELD_BACK';
        req.identityCause = 'NO_CUSTOMER_RECORD';
        ServicingDemoWriteHandoffCase.Response res = write(req);
        System.assertEquals(ServicingDemoResult.FOUND, res.resultCode);
        Case c = [SELECT AccountId, Description FROM Case WHERE Id = :res.recordRef];
        System.assertEquals(null, c.AccountId);
        System.assert(c.Description.contains('Identity not proven: verify before any account detail.'));
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoWriteHandoffCase.forceError = true;
        ServicingDemoWriteHandoffCase.Response res = write(liveReadDownRequest(''));
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
        System.assertEquals('', res.caseNumber);
        System.assertEquals(0, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void marksAndBlocks() {
        System.assertEquals('not asked', ServicingDemoWriteHandoffCase.mark('', '', '', '', false));
        System.assert(ServicingDemoWriteHandoffCase.mark('NOTHING_THERE', '', '', '', false).startsWith('nothing there'));
        System.assert(ServicingDemoWriteHandoffCase.mark('NOTHING_THERE', '', '', 't', true).contains('nightly copy'));
        System.assertEquals('held back: CUSTOMER_MISMATCH', ServicingDemoWriteHandoffCase.mark('HELD_BACK', 'CUSTOMER_MISMATCH', '', '', false));
        System.assertEquals('OTHER: none', ServicingDemoWriteHandoffCase.mark('OTHER', '', '', '', false));

        ServicingDemoWriteHandoffCase.Request req = new ServicingDemoWriteHandoffCase.Request();
        System.assertEquals('not asked', ServicingDemoWriteHandoffCase.copyBlock(req));
        req.historyResult = 'NOT_AVAILABLE';
        req.historyCause = 'APEX_QUERYEXCEPTION';
        System.assertEquals('could not look: APEX_QUERYEXCEPTION', ServicingDemoWriteHandoffCase.copyBlock(req));
        req.historyResult = 'FOUND';
        System.assert(ServicingDemoWriteHandoffCase.copyBlock(req).startsWith('nothing there in the nightly copy'));

        req.changeResult = 'FOUND';
        System.assert(ServicingDemoWriteHandoffCase.changeBlock(req).startsWith('complete and stored.'));
        req.changeResult = 'REFUSED';
        System.assert(ServicingDemoWriteHandoffCase.changeBlock(req).startsWith('refused, nothing changed'));
        req.changeResult = 'NOT_AVAILABLE';
        System.assert(ServicingDemoWriteHandoffCase.changeBlock(req).startsWith('not sent, nothing changed'));
        req.changeResult = 'HELD_BACK';
        System.assert(ServicingDemoWriteHandoffCase.changeBlock(req).startsWith('held back, not sent'));
        req.changeResult = 'OTHER';
        System.assert(ServicingDemoWriteHandoffCase.changeBlock(req).startsWith('OTHER'));

        for (String cause : new List<String>{
            'JOB_FOR_PERSONS', 'CUSTOMER_REQUEST', 'SOURCE_FAILED_LIVE_READ', 'SOURCE_FAILED_HISTORY',
            'SOURCE_FAILED_NETWORK', 'NO_POLICY', 'CHANGE_NOT_CONFIRMED', 'IDENTITY_NOT_PROVEN', 'SOMETHING_ELSE'
        }) {
            System.assertNotEquals('', ServicingDemoWriteHandoffCase.exitSentence(cause));
        }
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoWriteHandoffCase.writeHandoffCase(null).size());
    }
}
