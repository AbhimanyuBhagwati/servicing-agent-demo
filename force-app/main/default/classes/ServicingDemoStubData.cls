/**
 * DEMO STUB DATA: invented test data for the stubs that replace the client's
 * systems in the Servicing Agent (demo):
 *   - the live read of the technician appointment through the client's
 *     interface layer (action 2) and the change of the appointment (action 6);
 *   - the nightly copy of the bills and of the appointment in Snowflake, read
 *     through Data 360 Zero Copy query federation (action 3);
 *   - the approved policy texts in the search index (action 5).
 * Nothing here is read from a real system. Customer IDs 1001 and 1002 only.
 * All values are invented for the demo [A].
 */
public with sharing class ServicingDemoStubData {

    public class Appointment {
        public String appointmentId;
        public String customerId;
        public String kind;
        public String slotCode;
        public String slotText;
        public String status;
    }

    public class Slot {
        public String code;
        public String text;
    }

    public class Bill {
        public String customerId;
        public String period;
        public String amount;
        public String status;
        public String dueDate;
    }

    public class Policy {
        public String policyId;
        public String title;
        public String version;
        public String startDate;
        public String text;
        public List<String> keywords;
    }

    /** The age limit for the nightly copy, in hours. In production the data platform owner sets it. */
    public static final Integer COPY_AGE_LIMIT_HOURS = 26;

    /** Test only: a load time in place of the last 02:00. */
    @TestVisible
    static Datetime loadTimeOverride;

    /** Test only: puts a different customer ID on the stub rows, to show HELD_BACK. */
    @TestVisible
    static String rowCustomerIdOverride;

    private static final List<String> DAY_NAMES = new List<String>{
        'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    };

    // ---- Dates for the slots (always in the future) ----

    /** 0 = Sunday ... 6 = Saturday. 1900-01-07 was a Sunday. */
    public static Integer dayOfWeek(Date d) {
        return Math.mod(Date.newInstance(1900, 1, 7).daysBetween(d), 7);
    }

    public static Date nextDay(Integer targetDay) {
        Date today = Date.today();
        for (Integer i = 1; i <= 7; i++) {
            Date candidate = today.addDays(i);
            if (dayOfWeek(candidate) == targetDay) {
                return candidate;
            }
        }
        return today.addDays(7);
    }

    public static String slotText(Integer targetDay, String fromTo) {
        return DAY_NAMES[targetDay] + ' ' + ServicingDemoResult.dateText(nextDay(targetDay)) + ', ' + fromTo;
    }

    private static String rowCustomerId(String customerId) {
        return rowCustomerIdOverride != null ? rowCustomerIdOverride : customerId;
    }

    // ---- The appointment (live read and nightly copy) ----

    public static Appointment appointmentFor(String customerId) {
        if (customerId == '1001') {
            Appointment a = new Appointment();
            a.appointmentId = 'WO-1001-01';
            a.customerId = rowCustomerId(customerId);
            a.kind = 'Technician visit: check of the internet line';
            a.slotCode = 'THU-1400';
            a.slotText = slotText(4, '14:00-16:00');
            a.status = 'Scheduled';
            return a;
        }
        return null;
    }

    public static String appointmentText(Appointment a) {
        if (a == null) {
            return '';
        }
        return a.kind + ', ' + a.slotText + ', status ' + a.status + ' (work order ' + a.appointmentId + ')';
    }

    public static List<Slot> freeSlots() {
        List<Slot> slots = new List<Slot>();
        slots.add(newSlot('FRI-1000', slotText(5, '10:00-12:00')));
        slots.add(newSlot('FRI-1400', slotText(5, '14:00-16:00')));
        slots.add(newSlot('MON-0800', slotText(1, '08:00-10:00')));
        return slots;
    }

    public static String freeSlotsText() {
        List<String> parts = new List<String>();
        for (Slot s : freeSlots()) {
            parts.add(s.code + ' = ' + s.text);
        }
        return String.join(parts, '; ');
    }

    /** Finds a free slot from the code that the model gives, for example "FRI-1000" or "fri 1000". */
    public static Slot findFreeSlot(String wanted) {
        String w = normalize(wanted);
        if (String.isBlank(w)) {
            return null;
        }
        for (Slot s : freeSlots()) {
            String code = normalize(s.code);
            if (w == code || w.contains(code)) {
                return s;
            }
        }
        // A looser match on the customer's words, for example "Friday at 10": the day and the start hour.
        for (Slot s : freeSlots()) {
            String day = s.code.substring(0, 3);
            String hour = String.valueOf(Integer.valueOf(s.code.substring(4, 6)));
            if (w.contains(day) && w.contains(hour)) {
                return s;
            }
        }
        return null;
    }

    public static String normalize(String value) {
        return ServicingDemoResult.safe(value).toUpperCase().replace('-', '').replace(' ', '').replace(':', '');
    }

    private static Slot newSlot(String code, String text) {
        Slot s = new Slot();
        s.code = code;
        s.text = text;
        return s;
    }

    // ---- The nightly copy: bills ----

    /** The most recent 02:00 in the time zone of the running user. */
    public static Datetime loadTime() {
        if (loadTimeOverride != null) {
            return loadTimeOverride;
        }
        Datetime todayAtTwo = Datetime.newInstance(Date.today(), Time.newInstance(2, 0, 0, 0));
        if (Datetime.now() < todayAtTwo) {
            return todayAtTwo.addDays(-1);
        }
        return todayAtTwo;
    }

    public static List<Bill> billsFor(String customerId) {
        List<Bill> bills = new List<Bill>();
        Date firstOfMonth = Date.today().toStartOfMonth();
        if (customerId == '1001') {
            bills.add(newBill(customerId, firstOfMonth.addMonths(-2), '49.00 USD', 'Paid', ''));
            bills.add(newBill(customerId, firstOfMonth.addMonths(-1), '49.00 USD', 'Paid', ''));
            bills.add(newBill(customerId, firstOfMonth, '64.50 USD', 'Open',
                ServicingDemoResult.dateText(firstOfMonth.addMonths(1).addDays(4))));
        } else if (customerId == '1002') {
            bills.add(newBill(customerId, firstOfMonth, '39.00 USD', 'Paid', ''));
        }
        return bills;
    }

    private static Bill newBill(String customerId, Date period, String amount, String status, String dueDate) {
        Bill b = new Bill();
        b.customerId = rowCustomerId(customerId);
        b.period = Datetime.newInstance(period, Time.newInstance(12, 0, 0, 0)).format('yyyy-MM');
        b.amount = amount;
        b.status = status;
        b.dueDate = dueDate;
        return b;
    }

    public static String billText(Bill b) {
        String t = 'Bill ' + b.period + ': ' + b.amount + ', ' + b.status;
        if (String.isNotBlank(b.dueDate)) {
            t += ', due ' + b.dueDate;
        }
        return t;
    }

    // ---- The policy index: two approved texts ----

    public static List<Policy> policies() {
        List<Policy> result = new List<Policy>();
        result.add(newPolicy(
            'POL-EQUIP-01', 'Equipment return policy', '4', '2026-09-01',
            'A customer who ends the service returns the router within 30 days. '
            + 'The customer gets a prepaid return label. '
            + 'A router that does not come back is charged at the price in the price list.',
            new List<String>{ 'router', 'modem', 'equipment', 'return', 'device' }
        ));
        result.add(newPolicy(
            'POL-PLAN-02', 'Plan change policy', '2', '2026-06-15',
            'A customer can change to a different plan one time in a billing period. '
            + 'The new price starts on the first day of the next billing period. '
            + 'There is no fee for the change.',
            new List<String>{ 'plan', 'package', 'upgrade', 'downgrade', 'tariff' }
        ));
        return result;
    }

    public static Policy findPolicy(String questionText) {
        String q = ServicingDemoResult.safe(questionText).toLowerCase();
        if (String.isBlank(q)) {
            return null;
        }
        for (Policy p : policies()) {
            for (String keyword : p.keywords) {
                if (q.contains(keyword)) {
                    return p;
                }
            }
        }
        return null;
    }

    private static Policy newPolicy(String policyId, String title, String version, String startDate, String text, List<String> keywords) {
        Policy p = new Policy();
        p.policyId = policyId;
        p.title = title;
        p.version = version;
        p.startDate = startDate;
        p.text = text;
        p.keywords = keywords;
        return p;
    }
}
