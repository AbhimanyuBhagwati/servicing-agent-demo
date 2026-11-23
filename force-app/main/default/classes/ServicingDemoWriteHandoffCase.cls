/**
 * REAL: inserts one Case with the record of design/06 §8 in its Description.
 *
 * Action 8 of the demo specification, "Write the handoff case" (step H3 of the
 * handoff in design/06 §7). The production part is the same: a Case in
 * Salesforce, written by code before any escalation attempt, because
 * @utils.escalate takes no inputs (R41) and is attempted only once (R09).
 *
 * Code writes the facts: each block of the record is built here from the
 * results of the actions, and each fact has its state ("found", "nothing
 * there", "could not look" with the cause, "held back" with the cause,
 * "not asked", or "old" with its time). No field is blank. The model writes
 * no part of the record. The record has the mark "internal".
 *
 * One case for one session: when a session key is given, a second call in
 * the same session returns the case that is already there.
 *
 * Order of work (R43): a callout cannot follow uncommitted DML in the same
 * transaction. In production a callout (for example the change request) can
 * come in the same transaction, so this record write is the last step, after
 * each callout. This demo makes no callout; the order is kept on purpose.
 *
 * Results: FOUND (the case is written, or was already written for this
 * session); NOT_AVAILABLE (the write failed: an error, caught; never thrown, R02).
 */
public with sharing class ServicingDemoWriteHandoffCase {

    public static final String SOURCE_TEXT = 'Salesforce Case (real insert)';
    public static final Integer MAX_DESCRIPTION = 32000;

    @TestVisible
    static Boolean forceError = false;

    public class Request {
        @InvocableVariable(label='Session key' description='The messaging session ID. Empty in a builder preview.' required=false)
        public String sessionKey;
        @InvocableVariable(label='Customer ID' description='The verified customer ID, or empty' required=false)
        public String customerId;
        @InvocableVariable(label='Exit cause' description='The cause of the exit, set by the script' required=false)
        public String exitCause;
        @InvocableVariable(label='Identity result' description='The result of the identity step' required=false)
        public String identityResult;
        @InvocableVariable(label='Identity cause' description='The cause code of the identity step' required=false)
        public String identityCause;
        @InvocableVariable(label='Status result' description='The result of the live read' required=false)
        public String statusResult;
        @InvocableVariable(label='Status cause' description='The cause code of the live read' required=false)
        public String statusCause;
        @InvocableVariable(label='Status value' description='The value of the live read' required=false)
        public String statusValue;
        @InvocableVariable(label='Status data time' description='The time of the data of the live read' required=false)
        public String statusDataTime;
        @InvocableVariable(label='History result' description='The result of the history read' required=false)
        public String historyResult;
        @InvocableVariable(label='History cause' description='The cause code of the history read' required=false)
        public String historyCause;
        @InvocableVariable(label='History value' description='The value of the history read' required=false)
        public String historyValue;
        @InvocableVariable(label='History data time' description='The load time of the copy' required=false)
        public String historyDataTime;
        @InvocableVariable(label='History appointment copy' description='The appointment as the nightly copy showed it, if any' required=false)
        public String historyAppointmentCopy;
        @InvocableVariable(label='Cases result' description='The result of the case read' required=false)
        public String casesResult;
        @InvocableVariable(label='Cases cause' description='The cause code of the case read' required=false)
        public String casesCause;
        @InvocableVariable(label='Cases value' description='The value of the case read' required=false)
        public String casesValue;
        @InvocableVariable(label='Policy result' description='The result of the policy read' required=false)
        public String policyResult;
        @InvocableVariable(label='Policy cause' description='The cause code of the policy read' required=false)
        public String policyCause;
        @InvocableVariable(label='Policy value' description='The policy title and text' required=false)
        public String policyValue;
        @InvocableVariable(label='Policy version' description='The policy version' required=false)
        public String policyVersion;
        @InvocableVariable(label='Change result' description='The result of the change' required=false)
        public String changeResult;
        @InvocableVariable(label='Change cause' description='The cause code of the change' required=false)
        public String changeCause;
        @InvocableVariable(label='Change request key' description='The request key of the change' required=false)
        public String changeRequestKey;
        @InvocableVariable(label='Change time before' description='The appointment before the change' required=false)
        public String changeTimeBefore;
        @InvocableVariable(label='Change time wanted' description='The slot that the customer wanted' required=false)
        public String changeTimeWanted;
        @InvocableVariable(label='Change confirmation' description='The confirmation number, if any' required=false)
        public String changeConfirmation;
        @InvocableVariable(label='Change read after' description='What one read after the change showed' required=false)
        public String changeReadAfter;
        @InvocableVariable(label='Summary text' description='A summary of the AI agent. Not verified. Can be empty.' required=false)
        public String summaryText;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND or NOT_AVAILABLE')
        public String resultCode = '';
        @InvocableVariable(label='Cause code' description='A short cause code of the demo, never the text of an error')
        public String causeCode = '';
        @InvocableVariable(label='Data source' description='The system that stored the record')
        public String dataSource = '';
        @InvocableVariable(label='Record reference' description='The ID of the case')
        public String recordRef = '';
        @InvocableVariable(label='Time of the data' description='The time of the write')
        public String dataTime = '';
        @InvocableVariable(label='Time of the read' description='The time of this call')
        public String readTime = '';
        @InvocableVariable(label='Case number' description='The case number to tell the customer. Empty unless the result is FOUND.')
        public String caseNumber = '';
    }

    @InvocableMethod(
        label='Servicing Demo: Write the handoff case'
        description='REAL insert of one Case for the handoff, with the known facts of the session and the state of each fact in the description.'
    )
    public static List<Response> writeHandoffCase(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null) {
            return responses;
        }
        String writeTime = ServicingDemoResult.nowText();

        // The account and the first contact of each customer ID, read one time.
        Set<String> customerIds = new Set<String>();
        for (Request req : requests) {
            if (req != null && String.isNotBlank(req.customerId)) {
                customerIds.add(req.customerId.trim());
            }
        }
        Map<String, Account> accountByCustomer = new Map<String, Account>();
        try {
            if (!customerIds.isEmpty()) {
                for (Account a : [
                    SELECT Id, AccountNumber, (SELECT Id FROM Contacts ORDER BY CreatedDate ASC LIMIT 1)
                    FROM Account
                    WHERE AccountNumber IN :customerIds
                    ORDER BY CreatedDate ASC
                ]) {
                    if (!accountByCustomer.containsKey(a.AccountNumber)) {
                        accountByCustomer.put(a.AccountNumber, a);
                    }
                }
            }
        } catch (Exception e) {
            // The case is still written, with no link to the account. The identity block tells the customer ID.
            accountByCustomer.clear();
        }

        List<Case> toInsert = new List<Case>();
        List<Integer> insertIndex = new List<Integer>();
        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i] == null ? new Request() : requests[i];
            Response res = new Response();
            res.dataSource = SOURCE_TEXT;
            res.readTime = writeTime;
            responses.add(res);
            try {
                if (forceError) {
                    throw new ServicingDemoResult.DemoException('forced for a test');
                }
                String key = ServicingDemoResult.safe(req.sessionKey).trim();
                if (String.isNotBlank(key)) {
                    String pattern = '%[session ' + key + ']%';
                    List<Case> existing = [
                        SELECT Id, CaseNumber
                        FROM Case
                        WHERE Subject LIKE :pattern
                        AND CreatedDate = TODAY
                        ORDER BY CreatedDate ASC
                        LIMIT 1
                    ];
                    if (!existing.isEmpty()) {
                        res.resultCode = ServicingDemoResult.FOUND;
                        res.causeCode = 'CASE_ALREADY_WRITTEN_FOR_SESSION';
                        res.recordRef = existing[0].Id;
                        res.caseNumber = existing[0].CaseNumber;
                        res.dataTime = writeTime;
                        continue;
                    }
                }
                toInsert.add(buildCase(req, key, accountByCustomer, writeTime));
                insertIndex.add(i);
            } catch (Exception e) {
                res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
                res.causeCode = ServicingDemoResult.causeFrom(e);
            }
        }

        if (!toInsert.isEmpty()) {
            try {
                // No automatic email and no assignment rule: the agent user sends no email,
                // and the owner is the case queue.
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.optAllOrNone = false;
                dmo.EmailHeader.triggerAutoResponseEmail = false;
                dmo.EmailHeader.triggerUserEmail = false;
                dmo.EmailHeader.triggerOtherEmail = false;
                dmo.AssignmentRuleHeader.useDefaultRule = false;
                List<Database.SaveResult> saveResults = Database.insert(toInsert, dmo);
                Set<Id> written = new Set<Id>();
                for (Integer j = 0; j < saveResults.size(); j++) {
                    Response res = responses[insertIndex[j]];
                    if (saveResults[j].isSuccess()) {
                        written.add(saveResults[j].getId());
                        res.recordRef = saveResults[j].getId();
                    } else {
                        res.resultCode = ServicingDemoResult.NOT_AVAILABLE;
                        List<Database.Error> errors = saveResults[j].getErrors();
                        res.causeCode = errors.isEmpty()
                            ? 'CASE_WRITE_FAILED'
                            : 'CASE_WRITE_FAILED_' + errors[0].getStatusCode().name();
                        // The full error text goes only to the debug log, for the operations owner.
                        // It never goes to the agent or the customer (design/06 section 5).
                        if (!errors.isEmpty()) {
                            System.debug(LoggingLevel.ERROR, 'Servicing demo case write failed: ' + errors[0].getMessage());
                        }
                    }
                }
                Map<Id, Case> numbers = new Map<Id, Case>([SELECT Id, CaseNumber FROM Case WHERE Id IN :written]);
                for (Integer j = 0; j < saveResults.size(); j++) {
                    Response res = responses[insertIndex[j]];
                    if (saveResults[j].isSuccess() && numbers.containsKey(saveResults[j].getId())) {
                        res.resultCode = ServicingDemoResult.FOUND;
                        res.causeCode = 'CASE_WRITTEN';
                        res.caseNumber = numbers.get(saveResults[j].getId()).CaseNumber;
                        res.dataTime = writeTime;
                    }
                }
            } catch (Exception e) {
                for (Integer index : insertIndex) {
                    responses[index].resultCode = ServicingDemoResult.NOT_AVAILABLE;
                    responses[index].causeCode = ServicingDemoResult.causeFrom(e);
                    responses[index].caseNumber = '';
                }
            }
        }
        return responses;
    }

    // ---- The record of design/06 §8 ----

    @TestVisible
    static Case buildCase(Request req, String key, Map<String, Account> accountByCustomer, String writeTime) {
        String exitCause = String.isBlank(req.exitCause) ? 'NOT_SET_BY_SCRIPT' : req.exitCause.trim();
        String customerId = ServicingDemoResult.safe(req.customerId).trim();

        Case c = new Case();
        // The case goes to the case queue (design/06 section 7, H3 and H5b): a team of
        // service reps works it, and the agent user does not own it.
        Id queueId = caseQueueId();
        if (queueId != null) {
            c.OwnerId = queueId;
        }
        c.Subject = 'Servicing demo handoff: ' + exitCause + (String.isBlank(key) ? '' : ' [session ' + key + ']');
        c.Origin = 'Web';
        c.Priority = exitCause == 'CHANGE_NOT_CONFIRMED' ? 'High' : 'Medium';
        Account a = accountByCustomer.get(customerId);
        if (a != null) {
            c.AccountId = a.Id;
            if (a.Contacts != null && !a.Contacts.isEmpty()) {
                c.ContactId = a.Contacts[0].Id;
            }
        }
        String recordText = buildDescription(req, exitCause, key, writeTime);
        c.Description = recordText.length() > MAX_DESCRIPTION ? recordText.substring(0, MAX_DESCRIPTION) : recordText;
        return c;
    }

    @TestVisible
    static String buildDescription(Request req, String exitCause, String key, String writeTime) {
        String sessionText = String.isBlank(key) ? 'builder preview (no session ID)' : key;
        List<String> lines = new List<String>();
        lines.add('INTERNAL RECORD FOR THE SERVICE REP. Do not show this text to the customer.');
        lines.add('Servicing Agent (demo): a prototype in a Developer Edition org. The client systems are stubs that return test data.');
        lines.add('');
        lines.add('1. Exit cause (examine this first): ' + exitCause + ' - ' + exitSentence(exitCause));
        lines.add('2. Change: ' + changeBlock(req));
        lines.add('3. Identity: ' + identityBlock(req));
        lines.add('4. Live status (DEMO STUB for the live read through the interface layer): '
            + mark(req.statusResult, req.statusCause, req.statusValue, req.statusDataTime, false));
        lines.add('5. History (DEMO STUB for the nightly copy, Data 360 Zero Copy to Snowflake): '
            + mark(req.historyResult, req.historyCause, req.historyValue, req.historyDataTime, true));
        lines.add('5b. Appointment in the same nightly copy: ' + copyBlock(req));
        lines.add('6. Open cases (Salesforce, real query, public notes only): '
            + mark(req.casesResult, req.casesCause, req.casesValue, '', false));
        String policyValue = ServicingDemoResult.safe(req.policyValue)
            + (String.isBlank(req.policyVersion) ? '' : ' (version ' + req.policyVersion + ')');
        lines.add('7. Policy (DEMO STUB for the retriever on the search index): '
            + mark(req.policyResult, req.policyCause, policyValue, '', false));
        lines.add('8. The text that the AI agent gave the customer: see the conversation of session ' + sessionText
            + '. The values that the answer used are the lines above.');
        lines.add('9. Summary of the AI agent. Not verified: '
            + (String.isBlank(req.summaryText) ? '(empty: the demo writes no model summary)' : req.summaryText));
        lines.add('');
        lines.add('Written by code at ' + writeTime + '. Session: ' + sessionText + '.');
        return String.join(lines, '\n');
    }

    @TestVisible
    static String exitSentence(String exitCause) {
        if (exitCause == 'JOB_FOR_PERSONS') {
            return 'A job for persons. A planned exit, not a failure.';
        }
        if (exitCause == 'CUSTOMER_REQUEST') {
            return 'The customer asked for a person or a case.';
        }
        if (exitCause == 'SOURCE_FAILED_LIVE_READ') {
            return 'The live read of the appointment did not give a usable result.';
        }
        if (exitCause == 'SOURCE_FAILED_HISTORY') {
            return 'The read of the bills did not give a usable result.';
        }
        if (exitCause == 'NO_POLICY') {
            return 'No approved policy text for the question of the customer.';
        }
        if (exitCause == 'CHANGE_NOT_CONFIRMED') {
            return 'A change of the appointment was sent and is not confirmed. Do not book a second time. Examine the appointment first.';
        }
        if (exitCause == 'IDENTITY_NOT_PROVEN') {
            return 'The identity of the customer is not proven.';
        }
        return 'A cause that the demo does not name.';
    }

    @TestVisible
    static String identityBlock(Request req) {
        if (req.identityResult == ServicingDemoResult.FOUND && String.isNotBlank(req.customerId)) {
            return 'customer ID ' + req.customerId.trim() + ', proven by the login (demo: read from the demo setting).';
        }
        return 'Identity not proven: verify before any account detail. (result '
            + (String.isBlank(req.identityResult) ? 'not asked' : req.identityResult)
            + (String.isBlank(req.identityCause) ? '' : ', cause ' + req.identityCause) + ')';
    }

    @TestVisible
    static String changeBlock(Request req) {
        String state = ServicingDemoResult.safe(req.changeResult);
        String details = 'request key ' + orNone(req.changeRequestKey)
            + '; time before: ' + orNone(req.changeTimeBefore)
            + '; time wanted: ' + orNone(req.changeTimeWanted)
            + '; confirmation: ' + orNone(req.changeConfirmation);
        if (String.isBlank(state)) {
            return 'not asked';
        }
        if (state == ServicingDemoResult.NOT_CONFIRMED) {
            return 'NOT CONFIRMED. Do not book a second time. Examine the appointment first. ' + details
                + '; read after the change: ' + orNone(req.changeReadAfter) + '.';
        }
        if (state == ServicingDemoResult.FOUND) {
            return 'complete and stored. ' + details + '.';
        }
        if (state == ServicingDemoResult.REFUSED) {
            return 'refused, nothing changed (' + orNone(req.changeCause) + '). ' + details + '.';
        }
        if (state == ServicingDemoResult.NOT_AVAILABLE) {
            return 'not sent, nothing changed (could not look: ' + orNone(req.changeCause) + ').';
        }
        if (state == ServicingDemoResult.HELD_BACK) {
            return 'held back, not sent (' + orNone(req.changeCause) + ').';
        }
        return state + ' (' + orNone(req.changeCause) + ').';
    }

    @TestVisible
    static String copyBlock(Request req) {
        String state = ServicingDemoResult.safe(req.historyResult);
        if (String.isBlank(state)) {
            return 'not asked';
        }
        if (state == ServicingDemoResult.NOT_AVAILABLE || state == ServicingDemoResult.HELD_BACK) {
            return mark(state, req.historyCause, '', req.historyDataTime, true);
        }
        if (String.isBlank(req.historyAppointmentCopy)) {
            return 'nothing there in the nightly copy of ' + orNone(req.historyDataTime);
        }
        return 'old (from the nightly copy of ' + orNone(req.historyDataTime) + '): ' + req.historyAppointmentCopy.trim();
    }

    /** The state of one fact. No fact is blank. */
    @TestVisible
    static String mark(String result, String cause, String value, String dataTime, Boolean isCopy) {
        String r = ServicingDemoResult.safe(result);
        if (String.isBlank(r)) {
            return 'not asked';
        }
        if (r == ServicingDemoResult.FOUND) {
            if (isCopy) {
                return 'old (from the nightly copy of ' + orNone(dataTime) + '): ' + orNone(value);
            }
            return 'found: ' + orNone(value) + (String.isBlank(dataTime) ? '' : ' (time of the data ' + dataTime + ')');
        }
        if (r == ServicingDemoResult.NOTHING_THERE) {
            return isCopy
                ? 'nothing there in the nightly copy of ' + orNone(dataTime) + ' (a newer record can be missing from the copy)'
                : 'nothing there (the source answered; it has no such record)';
        }
        if (r == ServicingDemoResult.NOT_AVAILABLE) {
            return 'could not look: ' + orNone(cause);
        }
        if (r == ServicingDemoResult.HELD_BACK) {
            return 'held back: ' + orNone(cause);
        }
        return r + ': ' + orNone(cause);
    }

    private static String orNone(String value) {
        return String.isBlank(value) ? 'none' : value.trim();
    }

    private static Id cachedQueueId;
    private static Boolean queueLooked = false;

    /** The Id of the queue "Servicing Demo Case Queue", or null if it is not there. */
    private static Id caseQueueId() {
        if (!queueLooked) {
            queueLooked = true;
            List<Group> queues = [
                SELECT Id FROM Group
                WHERE Type = 'Queue' AND DeveloperName = 'Servicing_Demo_Case_Queue'
                LIMIT 1
            ];
            cachedQueueId = queues.isEmpty() ? null : queues[0].Id;
        }
        return cachedQueueId;
    }
}