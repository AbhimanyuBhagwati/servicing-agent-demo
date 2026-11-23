@IsTest
private class ServicingDemoChangeAppointmentTest {

    private static ServicingDemoChangeAppointment.Response change(String customerId, String appointmentId, String slot, String key) {
        ServicingDemoChangeAppointment.Request req = new ServicingDemoChangeAppointment.Request();
        req.customerId = customerId;
        req.appointmentId = appointmentId;
        req.wantedSlot = slot;
        req.requestKey = key;
        return ServicingDemoChangeAppointment.changeAppointment(
            new List<ServicingDemoChangeAppointment.Request>{ req })[0];
    }

    @IsTest
    static void foundForAFreeSlotAndTheSameKeyGivesTheSameConfirmation() {
        ServicingDemoChangeAppointment.Response firstCall = change('1001', 'WO-1001-01', 'FRI-1000', '1001-WO-1001-01');
        System.assertEquals(ServicingDemoResult.FOUND, firstCall.resultCode);
        System.assert(firstCall.confirmationNumber.startsWith('CNF-'));
        System.assert(firstCall.newAppointmentText.contains('Friday'));
        System.assert(firstCall.timeBefore.contains('Thursday'));
        System.assertEquals('1001-WO-1001-01:FRI1000', firstCall.requestKeyUsed);

        ServicingDemoChangeAppointment.Response retry = change('1001', 'WO-1001-01', 'fri 1000', '1001-WO-1001-01');
        System.assertEquals(firstCall.confirmationNumber, retry.confirmationNumber, 'A retry with the same key gives the same confirmation');
    }

    @IsTest
    static void refusedForASlotThatIsNotFree() {
        ServicingDemoChangeAppointment.Response res = change('1001', 'WO-1001-01', 'SAT-0900', 'k1');
        System.assertEquals(ServicingDemoResult.REFUSED, res.resultCode);
        System.assertEquals('SLOT_NOT_FREE', res.causeCode);
        System.assertEquals('', res.confirmationNumber);
        System.assert(res.freeSlots.contains('MON-0800'));

        ServicingDemoChangeAppointment.Response sameSlot = change('1001', 'WO-1001-01', 'THU-1400', 'k1');
        System.assertEquals(ServicingDemoResult.REFUSED, sameSlot.resultCode);
        System.assertEquals('SLOT_IS_THE_PRESENT_APPOINTMENT', sameSlot.causeCode);
    }

    @IsTest
    static void notConfirmedWhenNoReplyComes() {
        ServicingDemoTestFactory.settings('1001', false, true);
        ServicingDemoChangeAppointment.Response res = change('1001', 'WO-1001-01', 'FRI-1400', 'k2');
        System.assertEquals(ServicingDemoResult.NOT_CONFIRMED, res.resultCode);
        System.assertEquals('DEMO_SWITCH_NO_REPLY_AFTER_SEND', res.causeCode);
        System.assertEquals('', res.confirmationNumber);
        System.assert(res.readAfterText.contains('Thursday'), 'The read after the send shows the time before');
        System.assert(res.timeWanted.startsWith('FRI-1400'));
    }

    @IsTest
    static void heldBackCases() {
        System.assertEquals('NO_VERIFIED_CUSTOMER_ID', change('', 'WO-1001-01', 'FRI-1000', 'k').causeCode);
        System.assertEquals('NO_REQUEST_KEY', change('1001', 'WO-1001-01', 'FRI-1000', ' ').causeCode);
        ServicingDemoChangeAppointment.Response other = change('1002', 'WO-1001-01', 'FRI-1000', 'k');
        System.assertEquals(ServicingDemoResult.HELD_BACK, other.resultCode);
        System.assertEquals('APPOINTMENT_NOT_OF_THIS_CUSTOMER', other.causeCode);
    }

    @IsTest
    static void notAvailableOnAnError() {
        ServicingDemoChangeAppointment.forceError = true;
        ServicingDemoChangeAppointment.Response res = change('1001', 'WO-1001-01', 'FRI-1000', 'k');
        System.assertEquals(ServicingDemoResult.NOT_AVAILABLE, res.resultCode);
        System.assertEquals('APEX_DEMOEXCEPTION', res.causeCode);
        System.assertNotEquals('', res.freeSlots);
    }

    @IsTest
    static void nullListGivesEmptyList() {
        System.assertEquals(0, ServicingDemoChangeAppointment.changeAppointment(null).size());
    }
}
