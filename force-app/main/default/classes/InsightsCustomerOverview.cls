/**
 * Customer Insights (demo), action "Get a customer overview".
 *
 * Seven fixed Data 360 queries for one customer, across all eight source tables:
 * the CRM record, the orders with their products, the support tickets, the returns,
 * the reviews and the survey answers. The result is one text that the model can
 * summarise. It never throws.
 */
public with sharing class InsightsCustomerOverview {

    public class Request {
        @InvocableVariable(label='Customer' description='The customer, for example "1", "Customer 1", "C01" or "customer one"' required=true)
        public String customer;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE, REFUSED or ERROR')
        public String resultCode;
        @InvocableVariable(label='Customer ID' description='The customer ID, for example C01')
        public String customerId;
        @InvocableVariable(label='Customer name' description='The name of the customer')
        public String customerName;
        @InvocableVariable(label='Overview' description='The customer record, orders, tickets, returns, reviews and surveys as text')
        public String overviewText;
        @InvocableVariable(label='Sources used' description='The source systems that the overview used')
        public String sourcesUsed;
        @InvocableVariable(label='Error text' description='The error, when the result code is REFUSED or ERROR')
        public String errorText;
    }

    @InvocableMethod(label='Get a customer overview' description='Reads everything about one customer from the eight Insights tables.')
    public static List<Response> run(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request r : requests) {
            responses.add(overview(r == null ? null : r.customer));
        }
        return responses;
    }

    @TestVisible
    static Response overview(String customer) {
        Response out = new Response();
        out.customerName = '';
        out.overviewText = '';
        out.sourcesUsed = '';
        out.errorText = '';
        String cid = InsightsData360.customerId(customer);
        out.customerId = cid == null ? '' : cid;
        if (cid == null) {
            out.resultCode = 'REFUSED';
            out.errorText = 'The customer must be one of Customer 1 to Customer 10.';
            return out;
        }
        String w = ' = \'' + cid + '\'';
        try {
            InsightsData360.Result c = InsightsData360.query(
                'SELECT customer_name__c, city__c, joined_date__c, loyalty_tier__c, marketing_opt_in__c, preferred_channel__c'
                + ' FROM Insights_Customers__dll WHERE customer_id__c' + w);
            if (c.rows.isEmpty()) {
                out.resultCode = 'NOTHING_THERE';
                out.errorText = 'No customer ' + cid + ' in the CRM table.';
                return out;
            }
            InsightsData360.Result orders = InsightsData360.query(
                'SELECT order_id__c, order_date__c, order_status__c, carrier__c, promised_date__c, delivered_date__c, order_total__c'
                + ' FROM Insights_Orders__dll WHERE customer_id__c' + w + ' ORDER BY order_date__c');
            InsightsData360.Result lines = InsightsData360.query(
                'SELECT l.order_id__c, p.product_name__c, l.quantity__c'
                + ' FROM Insights_Order_Lines__dll l JOIN Insights_Products__dll p ON p.product_id__c = l.product_id__c'
                + ' WHERE l.customer_id__c' + w + ' ORDER BY l.line_id__c');
            InsightsData360.Result tickets = InsightsData360.query(
                'SELECT ticket_id__c, opened_date__c, ticket_category__c, subject__c, priority__c, ticket_status__c, resolved_date__c, csat_score__c'
                + ' FROM Insights_Tickets__dll WHERE customer_id__c' + w + ' ORDER BY opened_date__c');
            InsightsData360.Result returns = InsightsData360.query(
                'SELECT r.return_id__c, r.requested_date__c, p.product_name__c, r.return_reason__c, r.return_status__c, r.refund_amount__c'
                + ' FROM Insights_Returns__dll r JOIN Insights_Products__dll p ON p.product_id__c = r.product_id__c'
                + ' WHERE r.customer_id__c' + w + ' ORDER BY r.requested_date__c');
            InsightsData360.Result reviews = InsightsData360.query(
                'SELECT v.review_date__c, p.product_name__c, v.rating__c, v.review_title__c'
                + ' FROM Insights_Reviews__dll v JOIN Insights_Products__dll p ON p.product_id__c = v.product_id__c'
                + ' WHERE v.customer_id__c' + w + ' ORDER BY v.review_date__c');
            InsightsData360.Result surveys = InsightsData360.query(
                'SELECT response_date__c, nps_score__c, survey_comment__c'
                + ' FROM Insights_Surveys__dll WHERE customer_id__c' + w + ' ORDER BY response_date__c');

            out.customerName = val(c, 0, 'customer_name__c');
            List<String> text = new List<String>();
            text.add(out.customerName + ' (' + cid + '), ' + val(c, 0, 'city__c')
                + '. Customer since ' + val(c, 0, 'joined_date__c')
                + '. Loyalty tier ' + val(c, 0, 'loyalty_tier__c')
                + '. Marketing opt-in ' + val(c, 0, 'marketing_opt_in__c')
                + '. Prefers the ' + val(c, 0, 'preferred_channel__c') + '. [CRM]');

            Map<String, List<String>> productsByOrder = new Map<String, List<String>>();
            for (Integer i = 0; i < lines.rows.size(); i++) {
                String oid = val(lines, i, 'order_id__c');
                if (!productsByOrder.containsKey(oid)) {
                    productsByOrder.put(oid, new List<String>());
                }
                productsByOrder.get(oid).add(val(lines, i, 'product_name__c') + ' x' + val(lines, i, 'quantity__c'));
            }
            Decimal spend = 0;
            Integer late = 0;
            text.add('');
            text.add('Orders (' + orders.rows.size() + ') [Web shop]:');
            for (Integer i = 0; i < orders.rows.size(); i++) {
                String oid = val(orders, i, 'order_id__c');
                String status = val(orders, i, 'order_status__c');
                String promised = val(orders, i, 'promised_date__c');
                String delivered = val(orders, i, 'delivered_date__c');
                String total = val(orders, i, 'order_total__c');
                if (status != 'Cancelled' && String.isNotBlank(total)) {
                    spend += Decimal.valueOf(total);
                }
                String delivery = String.isBlank(delivered) ? 'not delivered' : 'delivered ' + delivered;
                if (String.isNotBlank(delivered) && delivered > promised) {
                    late++;
                    delivery += ', LATE';
                }
                List<String> items = productsByOrder.get(oid);
                text.add('- ' + oid + ' on ' + val(orders, i, 'order_date__c') + ': ' + status
                    + ', ' + val(orders, i, 'carrier__c') + ', promised ' + promised + ', ' + delivery
                    + ', total ' + total + '. Products: ' + (items == null ? '-' : String.join(items, ', ')));
            }
            text.add('Total spend (not counting cancelled orders): ' + InsightsData360.cell(spend) + '. Late deliveries: ' + late + '.');

            Integer open = 0;
            text.add('');
            text.add('Support tickets (' + tickets.rows.size() + ') [Help desk]:');
            for (Integer i = 0; i < tickets.rows.size(); i++) {
                String status = val(tickets, i, 'ticket_status__c');
                if (status != 'Resolved') {
                    open++;
                }
                String csat = val(tickets, i, 'csat_score__c');
                text.add('- ' + val(tickets, i, 'ticket_id__c') + ' on ' + val(tickets, i, 'opened_date__c')
                    + ': ' + val(tickets, i, 'ticket_category__c') + ', "' + val(tickets, i, 'subject__c') + '"'
                    + ', priority ' + val(tickets, i, 'priority__c') + ', ' + status
                    + (String.isBlank(val(tickets, i, 'resolved_date__c')) ? '' : ' on ' + val(tickets, i, 'resolved_date__c'))
                    + (String.isBlank(csat) ? '' : ', CSAT ' + csat));
            }
            text.add('Tickets not resolved: ' + open + '.');

            text.add('');
            text.add('Returns (' + returns.rows.size() + ') [Warehouse returns system]:');
            for (Integer i = 0; i < returns.rows.size(); i++) {
                String refund = val(returns, i, 'refund_amount__c');
                text.add('- ' + val(returns, i, 'return_id__c') + ' on ' + val(returns, i, 'requested_date__c')
                    + ': ' + val(returns, i, 'product_name__c') + ', "' + val(returns, i, 'return_reason__c') + '", '
                    + val(returns, i, 'return_status__c') + (String.isBlank(refund) ? '' : ', refund ' + refund));
            }

            text.add('');
            text.add('Reviews (' + reviews.rows.size() + ') [Review site]:');
            for (Integer i = 0; i < reviews.rows.size(); i++) {
                text.add('- ' + val(reviews, i, 'review_date__c') + ': ' + val(reviews, i, 'product_name__c')
                    + ', ' + val(reviews, i, 'rating__c') + ' of 5, "' + val(reviews, i, 'review_title__c') + '"');
            }

            text.add('');
            text.add('Survey answers (' + surveys.rows.size() + ') [Survey tool]:');
            for (Integer i = 0; i < surveys.rows.size(); i++) {
                text.add('- ' + val(surveys, i, 'response_date__c') + ': NPS ' + val(surveys, i, 'nps_score__c')
                    + ', "' + val(surveys, i, 'survey_comment__c') + '"');
            }

            out.overviewText = String.join(text, '\n');
            out.sourcesUsed = 'CRM, Web shop, Product catalog, Help desk, Warehouse returns system, Review site, Survey tool';
            out.resultCode = 'FOUND';
        } catch (Exception e) {
            out.resultCode = 'ERROR';
            out.errorText = InsightsData360.errorText(e);
        }
        return out;
    }

    /** The value of one column in one row, or an empty text. */
    @TestVisible
    static String val(InsightsData360.Result r, Integer row, String column) {
        Integer i = -1;
        for (Integer k = 0; k < r.columns.size(); k++) {
            String name = r.columns[k];
            if (name != null && (name.equalsIgnoreCase(column) || name.equalsIgnoreCase(column.removeEnd('__c')))) {
                i = k;
                break;
            }
        }
        if (i < 0 || row >= r.rows.size() || i >= r.rows[row].size()) {
            return '';
        }
        String v = r.rows[row][i];
        return v == null ? '' : v;
    }
}