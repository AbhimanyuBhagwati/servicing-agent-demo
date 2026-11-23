/**
 * Tests for the two shared classes: ServicingDemoResult (REAL helper) and
 * ServicingDemoStubData (DEMO STUB DATA).
 */
@IsTest
private class ServicingDemoSharedTest {

    @IsTest
    static void resultHelpers() {
        System.assertEquals('', ServicingDemoResult.timeText(null));
        System.assertNotEquals('', ServicingDemoResult.nowText());
        System.assertEquals('', ServicingDemoResult.dateText(null));
        System.assertEquals('2026-11-26', ServicingDemoResult.dateText(Date.newInstance(2026, 11, 26)));
        System.assertEquals('APEX_UNKNOWN_ERROR', ServicingDemoResult.causeFrom(null));
        System.assertEquals('APEX_DEMOEXCEPTION',
            ServicingDemoResult.causeFrom(new ServicingDemoResult.DemoException('x')));
        System.assertEquals('', ServicingDemoResult.safe(null));
        System.assertEquals('abc', ServicingDemoResult.cut('abc', 10));
        System.assertEquals('abcdefg...', ServicingDemoResult.cut('abcdefghijklmn', 10));
    }

    @IsTest
    static void settingsWithNoRow() {
        System.assertEquals('', ServicingDemoResult.loggedInCustomerId());
        System.assertEquals(false, ServicingDemoResult.liveReadDown());
        System.assertEquals(false, ServicingDemoResult.changeNoReply());
    }

    @IsTest
    static void settingsWithRow() {
        ServicingDemoTestFactory.settings(' 1001 ', true, true);
        System.assertEquals('1001', ServicingDemoResult.loggedInCustomerId());
        System.assertEquals(true, ServicingDemoResult.liveReadDown());
        System.assertEquals(true, ServicingDemoResult.changeNoReply());
    }

    @IsTest
    static void stubDates() {
        System.assertEquals(0, ServicingDemoStubData.dayOfWeek(Date.newInstance(2026, 11, 22)), 'Sunday');
        System.assertEquals(4, ServicingDemoStubData.dayOfWeek(Date.newInstance(2026, 11, 26)), 'Thursday');
        Date nextThursday = ServicingDemoStubData.nextDay(4);
        System.assert(nextThursday > Date.today());
        System.assertEquals(4, ServicingDemoStubData.dayOfWeek(nextThursday));
        System.assert(ServicingDemoStubData.slotText(4, '14:00-16:00').startsWith('Thursday '));
    }

    @IsTest
    static void stubAppointmentsAndSlots() {
        System.assertEquals(null, ServicingDemoStubData.appointmentFor('1002'));
        ServicingDemoStubData.Appointment a = ServicingDemoStubData.appointmentFor('1001');
        System.assertEquals('WO-1001-01', a.appointmentId);
        System.assert(ServicingDemoStubData.appointmentText(a).contains('14:00-16:00'));
        System.assertEquals('', ServicingDemoStubData.appointmentText(null));
        System.assertEquals(3, ServicingDemoStubData.freeSlots().size());
        System.assert(ServicingDemoStubData.freeSlotsText().contains('FRI-1000 = Friday'));
        System.assertEquals('FRI-1000', ServicingDemoStubData.findFreeSlot('fri 1000').code);
        System.assertEquals('MON-0800', ServicingDemoStubData.findFreeSlot('MON-08:00').code);
        System.assertEquals('FRI-1000', ServicingDemoStubData.findFreeSlot('Friday at 10').code);
        System.assertEquals('FRI-1400', ServicingDemoStubData.findFreeSlot('friday 14:00').code);
        System.assertEquals('MON-0800', ServicingDemoStubData.findFreeSlot('Monday 8 am').code);
        System.assertEquals(null, ServicingDemoStubData.findFreeSlot('Saturday morning'));
        System.assertEquals(null, ServicingDemoStubData.findFreeSlot('SAT-0900'));
        System.assertEquals(null, ServicingDemoStubData.findFreeSlot(''));
    }

    @IsTest
    static void stubBillsAndLoadTime() {
        Datetime loadAt = ServicingDemoStubData.loadTime();
        System.assertEquals(2, loadAt.hour());
        System.assert(loadAt <= Datetime.now());
        ServicingDemoStubData.loadTimeOverride = Datetime.newInstance(2026, 1, 1, 2, 0, 0);
        System.assertEquals(2026, ServicingDemoStubData.loadTime().year());

        System.assertEquals(3, ServicingDemoStubData.billsFor('1001').size());
        System.assertEquals(1, ServicingDemoStubData.billsFor('1002').size());
        System.assertEquals(0, ServicingDemoStubData.billsFor('9999').size());
        String openBill = ServicingDemoStubData.billText(ServicingDemoStubData.billsFor('1001')[2]);
        System.assert(openBill.contains('Open') && openBill.contains('due'));
    }

    @IsTest
    static void stubPolicies() {
        System.assertEquals(2, ServicingDemoStubData.policies().size());
        System.assertEquals('POL-EQUIP-01', ServicingDemoStubData.findPolicy('How do I return my router?').policyId);
        System.assertEquals('POL-PLAN-02', ServicingDemoStubData.findPolicy('Can I change my PLAN?').policyId);
        System.assertEquals(null, ServicingDemoStubData.findPolicy('Do you sell satellite TV?'));
        System.assertEquals(null, ServicingDemoStubData.findPolicy(null));
    }
}
