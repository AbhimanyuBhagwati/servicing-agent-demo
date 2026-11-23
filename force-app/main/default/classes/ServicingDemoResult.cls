/**
 * REAL (shared helper, no system behind it).
 *
 * The result contract of design/06_explicit_approach.md section 5, shared by
 * the eight actions of the Servicing Agent (demo):
 *   - the six result values: FOUND, NOTHING_THERE, NOT_AVAILABLE, REFUSED,
 *     NOT_CONFIRMED, HELD_BACK;
 *   - one time format for "the time of the data" and "the time of the read";
 *   - a cause code that is ours and never the error text of another system
 *     (that text can contain personal data, R48);
 *   - the read of the demo settings (Servicing_Demo_Settings__c).
 *
 * Each action catches its own errors and returns NOT_AVAILABLE with a cause
 * code. No action throws: the Agent Script specification leaves the behaviour
 * after a thrown error "undefined" (R02).
 */
public with sharing class ServicingDemoResult {

    public static final String FOUND = 'FOUND';
    public static final String NOTHING_THERE = 'NOTHING_THERE';
    public static final String NOT_AVAILABLE = 'NOT_AVAILABLE';
    public static final String REFUSED = 'REFUSED';
    public static final String NOT_CONFIRMED = 'NOT_CONFIRMED';
    public static final String HELD_BACK = 'HELD_BACK';

    /** Times are in the time zone of the user that runs the action. */
    public static final String TIME_FORMAT = 'yyyy-MM-dd HH:mm z';

    /** Used by the tests to drive the catch blocks. Never set outside a test. */
    public class DemoException extends Exception {}

    public static String timeText(Datetime value) {
        if (value == null) {
            return '';
        }
        return value.format(TIME_FORMAT);
    }

    public static String nowText() {
        return timeText(Datetime.now());
    }

    public static String dateText(Date value) {
        if (value == null) {
            return '';
        }
        return Datetime.newInstance(value, Time.newInstance(12, 0, 0, 0)).format('yyyy-MM-dd');
    }

    /**
     * A short cause code from an exception: its type only, for example
     * APEX_QUERYEXCEPTION. The message is not used.
     */
    public static String causeFrom(Exception e) {
        if (e == null) {
            return 'APEX_UNKNOWN_ERROR';
        }
        String typeName = e.getTypeName();
        String shortName = typeName == null ? '' : typeName.substringAfterLast('.');
        if (String.isBlank(shortName)) {
            shortName = String.isBlank(typeName) ? 'UNKNOWN_ERROR' : typeName;
        }
        return 'APEX_' + shortName.toUpperCase();
    }

    public static String safe(String value) {
        return value == null ? '' : value;
    }

    /** Cuts a text to a maximum length, so that action outputs stay small. */
    public static String cut(String value, Integer maxLength) {
        String v = safe(value).replace('\r', ' ').replace('\n', ' ').trim();
        if (v.length() <= maxLength) {
            return v;
        }
        return v.substring(0, maxLength - 3) + '...';
    }

    // ---- The demo settings (a hierarchy custom setting) ----

    public static Servicing_Demo_Settings__c settings() {
        Servicing_Demo_Settings__c s = Servicing_Demo_Settings__c.getInstance();
        if (s == null) {
            s = new Servicing_Demo_Settings__c();
        }
        return s;
    }

    public static String loggedInCustomerId() {
        return safe(settings().Logged_In_Customer_Id__c).trim();
    }

    public static Boolean liveReadDown() {
        return settings().Live_Read_Down__c == true;
    }

    public static Boolean changeNoReply() {
        return settings().Change_No_Reply__c == true;
    }
}
