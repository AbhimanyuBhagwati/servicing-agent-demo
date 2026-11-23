/**
 * DEMO STUB: replaces the live read through the client's interface layer.
 *
 * Action 2 of the demo specification, "Get the appointment status".
 * It returns test data from ServicingDemoStubData. When the demo switch
 * Servicing_Demo_Settings__c.Live_Read_Down__c is on, it returns NOT_AVAILABLE,
 * as if the interface layer gave no usable reply in the time limit.
 *
 * In production this action makes one HTTPS request through a named
 * credential, with a time limit that Apex sets (R05), to the interface layer of
 * the client, which reads field service and gives one reply. This demo makes
 * no callout.
 *
 * The customer examination of design/06: each row must carry the customer ID
 * of the session; a row of a different customer gives HELD_BACK and no value.
 *
 * Results: FOUND; NOTHING_THERE (the source answered: no open appointment);
 * NOT_AVAILABLE (switch on, or an error, caught; never thrown, R02);
 * HELD_BACK (no verified customer ID, or a row of a different customer).
 */
public with sharing class ServicingDemoGetAppointmentStatus {

    public static final String SOURCE_TEXT = 'DEMO STUB for the live read of field service through the interface layer';

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Customer ID' description='The verified customer ID of the session' required=true)
        public String customerId;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE, NOT_AVAILABLE or HELD_BACK')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The work order of the appointment')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The time of the value (live: the time of the read)')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this read')
        public String readTime = '';
        @InvocableVariable(label='Appointment ID' description='The ID of the appointment, for the change action')
        public String appointmentId = '';
        @InvocableVariable(label='Appointment text' description='The appointment: kind, day, date, time window and status')
        public String appointmentText = '';
        @InvocableVariable(label='Appointment slot code' description='The slot code of the present appointment')
        public String appointmentSlotCode = '';
        @InvocableVariable(label='Free slots' description='The free slots for a change, each as CODE = day, date, time window')
        public String freeSlots = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Get the appointment status'
        description='DEMO STUB for the live read through the client interface layer. Returns the present technician appointment of the verified customer, from test data.'
    )
    public static List<Response> getAppointmentStatus(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }
        for (Request req : requests) {
            responses.add(evaluate(req));
        }
        return responses;
    }

    private static Response evaluate(Request req) {
        Response res = new Response();
        res.dataSource = SOURCE_TEXT;
        res.readTime = ServicingDemoResult.nowText();
        try {
            if (forceError) {
                throw new ServicingDemoResult.DemoException('forced for a test');
            }
            String customerId = req == null ? '' : ServicingDemoResult.safe(req.customerId).trim();
            if (String.isBlank(customerId)) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'NO_VERIFIED_CUSTOMER_ID';
                return res;
            }
            if (ServicingDemoResult.liveReadDown()) {
                res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
                res.causeCode = 'DEMO_SWITCH_LIVE_READ_DOWN';
                return res;
            }

            ServicingDemoStubData.Appointment a = ServicingDemoStubData.appointmentFor(customerId);
            if (a == null) {
                res.resultCode = ServicingDemoResult.NOTHING_THERE;
                res.causeCode = 'NO_OPEN_APPOINTMENT';
                res.dataTime = res.readTime;
                return res;
            }
            if (a.customerId != customerId) {
                res.resultCode = ServicingDemoResult.HELD_BACK;
                res.causeCode = 'CUSTOMER_MISMATCH';
                return res;
            }

            res.resultCode = ServicingDemoResult.FOUND;
            res.recordRef = a.appointmentId;
            res.dataTime = res.readTime;
            res.appointmentId = a.appointmentId;
            res.appointmentText = ServicingDemoStubData.appointmentText(a);
            res.appointmentSlotCode = a.slotCode;
            res.freeSlots = ServicingDemoStubData.freeSlotsText();
        } catch (Exception e) {
            res = new Response();
            res.dataSource = SOURCE_TEXT;
            res.readTime = ServicingDemoResult.nowText();
            res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
            res.causeCode = ServicingDemoResult.causeFrom(e);
        }
        return res;
    }
}