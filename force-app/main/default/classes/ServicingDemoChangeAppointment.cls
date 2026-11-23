/**
 * DEMO STUB: replaces the one write action through the client's interface layer.
 *
 * Action 6 of the demo specification, "Change the appointment".
 * It takes a request key. The same key and the same slot give the same
 * confirmation number (an idempotent write: Salesforce guidance asks for an
 * idempotency key on each write action, R46; the key is our design).
 *   - The demo switch Servicing_Demo_Settings__c.Change_No_Reply__c on:
 *     NOT_CONFIRMED. The change was "sent" and no reply came. The action then
 *     does one read of the appointment (design/06 §6): in this stub the read
 *     shows the time before, so the script goes to the handoff with a case of
 *     high priority. "Do not book a second time. Examine the appointment first."
 *   - A slot that is not free: REFUSED. Nothing changed. The free slots come back.
 *   - A free slot: FOUND, with a confirmation number.
 * Nothing is stored: the stub does not change the test data.
 *
 * In production this action sends one HTTPS request through a named credential
 * with a time limit that Apex sets (R05), and a change is complete only after
 * the action stores the confirmation. This demo makes no callout.
 *
 * Results: FOUND, REFUSED, NOT_CONFIRMED; HELD_BACK (no customer ID, no key, or
 * an appointment of a different customer); NOT_AVAILABLE (the request was not
 * sent: an error, caught; never thrown, R02).
 */
public with sharing class ServicingDemoChangeAppointment {

    public static final String SOURCE_TEXT = 'DEMO STUB for the change of field service through the interface layer';

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Customer ID' description='The verified customer ID of the session' required=true)
        public String customerId;
        @InvocableVariable(label='Appointment ID' description='The ID of the present appointment, from the status read' required=true)
        public String appointmentId;
        @InvocableVariable(label='Wanted slot' description='The slot code of a free time, for example FRI-1000, or else the customer words for the time' required=true)
        public String wantedSlot;
        @InvocableVariable(label='Request key' description='The key of this change request. A retry uses the same key.' required=true)
        public String requestKey;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, REFUSED, NOT_CONFIRMED, NOT_AVAILABLE or HELD_BACK')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that gave the value')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The work order of the appointment')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The time of the reply')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this request')
        public String readTime = '';
        @InvocableVariable(label='Request key used' description='The full key of the request: the key and the slot')
        public String requestKeyUsed = '';
        @InvocableVariable(label='Time before' description='The appointment before the change')
        public String timeBefore = '';
        @InvocableVariable(label='Time wanted' description='The slot that the customer wants')
        public String timeWanted = '';
        @InvocableVariable(label='Confirmation number' description='The confirmation of the change. Empty unless the result is FOUND.')
        public String confirmationNumber = '';
        @InvocableVariable(label='New appointment text' description='The appointment after the change. Empty unless the result is FOUND.')
        public String newAppointmentText = '';
        @InvocableVariable(label='Read after the change' description='For NOT_CONFIRMED: what one read of the appointment showed after the send')
        public String readAfterText = '';
        @InvocableVariable(label='Free slots' description='The free slots, each as CODE = day, date, time window')
        public String freeSlots = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Change the appointment'
        description='DEMO STUB for the one write action through the client interface layer. Changes the technician appointment to one free slot, with a request key.'
    )
    public static List<Response> changeAppointment(List<Request> requests) {
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
        res.freeSlots = ServicingDemoStubData.freeSlotsText();
        try {
            if (forceError) {
                throw new ServicingDemoResult.DemoException('forced for a test');
            }
            String customerId = req == null ? '' : ServicingDemoResult.safe(req.customerId).trim();
            String appointmentId = req == null ? '' : ServicingDemoResult.safe(req.appointmentId).trim();
            String wanted = req == null ? '' : ServicingDemoResult.safe(req.wantedSlot).trim();
            String key = req == null ? '' : ServicingDemoResult.safe(req.requestKey).trim();

            if (String.isBlank(customerId)) {
                return heldBack(res, 'NO_VERIFIED_CUSTOMER_ID');
            }
            if (String.isBlank(key)) {
                return heldBack(res, 'NO_REQUEST_KEY');
            }
            ServicingDemoStubData.Appointment a = ServicingDemoStubData.appointmentFor(customerId);
            if (a == null || a.appointmentId != appointmentId || a.customerId != customerId) {
                return heldBack(res, 'APPOINTMENT_NOT_OF_THIS_CUSTOMER');
            }

            ServicingDemoStubData.Slot slot = ServicingDemoStubData.findFreeSlot(wanted);
            res.recordRef = a.appointmentId;
            res.timeBefore = a.slotText;
            res.timeWanted = slot != null ? slot.code + ' = ' + slot.text : wanted;
            res.requestKeyUsed = key + ':' + ServicingDemoStubData.normalize(slot != null ? slot.code : wanted);

            // From here the request counts as "sent" to the interface layer.
            if (ServicingDemoResult.changeNoReply()) {
                res.resultCode = ServicingDemoResult.NOT_CONFIRMED;
                res.causeCode = 'DEMO_SWITCH_NO_REPLY_AFTER_SEND';
                // One read of the appointment after the send. In this stub it shows the time before.
                res.readAfterText = ServicingDemoStubData.appointmentText(a);
                return res;
            }
            res.dataTime = ServicingDemoResult.nowText();
            if (slot == null) {
                res.resultCode = ServicingDemoResult.REFUSED;
                res.causeCode = ServicingDemoStubData.normalize(wanted) == ServicingDemoStubData.normalize(a.slotCode)
                    ? 'SLOT_IS_THE_PRESENT_APPOINTMENT'
                    : 'SLOT_NOT_FREE';
                return res;
            }
            res.resultCode = ServicingDemoResult.FOUND;
            res.confirmationNumber = confirmationFor(res.requestKeyUsed);
            res.newAppointmentText = a.kind + ', ' + slot.text + ', status Scheduled (work order ' + a.appointmentId + ')';
        } catch (Exception e) {
            res = new Response();
            res.dataSource = SOURCE_TEXT;
            res.readTime = ServicingDemoResult.nowText();
            res.freeSlots = ServicingDemoStubData.freeSlotsText();
            res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
            res.causeCode = ServicingDemoResult.causeFrom(e);
        }
        return res;
    }

    /** The same full key always gives the same confirmation number. */
    @TestVisible
    static String confirmationFor(String fullKey) {
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(fullKey));
        return 'CNF-' + EncodingUtil.convertToHex(digest).substring(0, 8).toUpperCase();
    }

    private static Response heldBack(Response res, String cause) {
        res.resultCode = ServicingDemoResult.HELD_BACK;
        res.causeCode = cause;
        return res;
    }
}