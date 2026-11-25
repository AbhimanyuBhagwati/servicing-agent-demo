/**
 * Tests of the Customer Insights (demo) actions, with a fake Data 360 runner.
 */
@IsTest
private class InsightsDemoTest {

    /** Gives canned rows for each kind of query; throws for SQL that contains BOOM. */
    private class FakeRunner implements InsightsData360.Runner {
        public List<String> seen = new List<String>();
        public InsightsData360.Result run(String sql) {
            seen.add(sql);
            if (sql.contains('BOOM')) {
                throw new IllegalArgumentException('Data 360 SQL error: BOOM');
            }
            InsightsData360.Result r = new InsightsData360.Result();
            if (sql.contains('COUNT(*)')) {
                r.columns = new List<String>{ 'row_count' };
                r.rows.add(new List<String>{ '10' });
            } else if (sql.contains('FROM Insights_Customers__dll WHERE')) {
                if (sql.contains('C09')) {
                    return r;
                }
                r.columns = new List<String>{ 'customer_name__c', 'city__c', 'joined_date__c', 'loyalty_tier__c', 'marketing_opt_in__c', 'preferred_channel__c' };
                r.rows.add(new List<String>{ 'Customer 1', 'Austin', '2024-03-12', 'Gold', 'Yes', 'App' });
            } else if (sql.contains('FROM Insights_Orders__dll')) {
                r.columns = new List<String>{ 'order_id__c', 'order_date__c', 'order_status__c', 'carrier__c', 'promised_date__c', 'delivered_date__c', 'order_total__c' };
                r.rows.add(new List<String>{ 'O1001', '2026-01-15', 'Delivered', 'ParcelPro', '2026-01-18', '2026-01-18', '293' });
                r.rows.add(new List<String>{ 'O1003', '2026-05-20', 'Delivered', 'QuickShip', '2026-05-23', '2026-05-26', '59' });
                r.rows.add(new List<String>{ 'O1009', '2026-07-30', 'Cancelled', 'ParcelPro', '2026-08-02', '', '25' });
            } else if (sql.contains('FROM Insights_Order_Lines__dll')) {
                r.columns = new List<String>{ 'order_id__c', 'product_name__c', 'quantity__c' };
                r.rows.add(new List<String>{ 'O1001', 'Barista Coffee Machine', '1' });
                r.rows.add(new List<String>{ 'O1003', 'Volt Wireless Earbuds', '1' });
            } else if (sql.contains('FROM Insights_Tickets__dll')) {
                r.columns = new List<String>{ 'ticket_id__c', 'opened_date__c', 'ticket_category__c', 'subject__c', 'priority__c', 'ticket_status__c', 'resolved_date__c', 'csat_score__c' };
                r.rows.add(new List<String>{ 'T01', '2026-06-10', 'Product defect', 'Left earbud does not charge', 'High', 'Resolved', '2026-06-11', '5' });
                r.rows.add(new List<String>{ 'T99', '2026-11-01', 'Billing', 'Wrong charge', 'Medium', 'Open', '', '' });
            } else if (sql.contains('FROM Insights_Returns__dll')) {
                r.columns = new List<String>{ 'return_id__c', 'requested_date__c', 'product_name__c', 'return_reason__c', 'return_status__c', 'refund_amount__c' };
                r.rows.add(new List<String>{ 'R01', '2026-06-11', 'Volt Wireless Earbuds', 'Battery does not charge', 'Refunded', '59' });
            } else if (sql.contains('FROM Insights_Reviews__dll')) {
                r.columns = new List<String>{ 'review_date__c', 'product_name__c', 'rating__c', 'review_title__c' };
                r.rows.add(new List<String>{ '2026-06-12', 'Volt Wireless Earbuds', '1', 'Stopped charging' });
            } else if (sql.contains('FROM Insights_Surveys__dll')) {
                r.columns = new List<String>{ 'response_date__c', 'nps_score__c', 'survey_comment__c' };
                r.rows.add(new List<String>{ '2026-10-20', '9', 'Fast help' });
            } else {
                r.columns = new List<String>{ 'ticket_category__c', 'n' };
                r.rows.add(new List<String>{ 'Late delivery', '6' });
                r.rows.add(new List<String>{ 'Product defect', '5' });
            }
            return r;
        }
    }

    private static FakeRunner useFake() {
        FakeRunner f = new FakeRunner();
        InsightsData360.testRunner = f;
        return f;
    }

    @IsTest
    static void queryRunsAndAddsLimit() {
        FakeRunner f = useFake();
        InsightsRunQuery.Request req = new InsightsRunQuery.Request();
        req.sqlQuery = 'SELECT ticket_category__c, COUNT(*) n FROM Insights_Tickets__dll GROUP BY ticket_category__c;';
        req.question = 'Tickets by category';
        InsightsRunQuery.Response res = InsightsRunQuery.run(new List<InsightsRunQuery.Request>{ req })[0];
        System.assertEquals('FOUND', res.resultCode);
        System.assertEquals('1', res.rowCount);
        System.assert(res.sqlRun.endsWith('LIMIT 200'), res.sqlRun);
        System.assert(!res.sqlRun.contains(';'), res.sqlRun);
        System.assertEquals('Help desk (Insights_Tickets)', res.sourcesUsed);
        System.assert(res.resultTable.startsWith('row_count'), res.resultTable);
        System.assertEquals(1, f.seen.size());
    }

    @IsTest
    static void queryKeepsItsOwnLimitAndJoinsSources() {
        useFake();
        InsightsRunQuery.Response res = InsightsRunQuery.runOne(
            'select r.return_id__c, p.product_name__c from Insights_Returns__dll r join Insights_Products__dll p on p.product_id__c = r.product_id__c limit 5');
        System.assertEquals('FOUND', res.resultCode);
        System.assert(res.sqlRun.endsWith('limit 5'), res.sqlRun);
        System.assertEquals('Product catalog (Insights_Products), Warehouse returns system (Insights_Returns)', res.sourcesUsed);
    }

    @IsTest
    static void queryRefusesOtherStatementsAndTables() {
        FakeRunner f = useFake();
        System.assertEquals('REFUSED', InsightsRunQuery.runOne('DELETE FROM Insights_Tickets__dll').resultCode);
        System.assertEquals('REFUSED', InsightsRunQuery.runOne('SELECT 1 FROM Insights_Tickets__dll; SELECT 2 FROM Insights_Tickets__dll').resultCode);
        InsightsRunQuery.Response other = InsightsRunQuery.runOne('SELECT * FROM Billing_History_Demo__dll');
        System.assertEquals('REFUSED', other.resultCode);
        System.assert(other.errorText.contains('Insights_Customers__dll'), other.errorText);
        System.assertEquals('REFUSED', InsightsRunQuery.runOne('SELECT 1').resultCode);
        System.assertEquals('REFUSED', InsightsRunQuery.runOne('  ').resultCode);
        System.assertEquals(0, f.seen.size());
    }

    @IsTest
    static void queryErrorComesBackAsResult() {
        useFake();
        InsightsRunQuery.Response res = InsightsRunQuery.runOne('SELECT BOOM FROM Insights_Orders__dll');
        System.assertEquals('ERROR', res.resultCode);
        System.assert(res.errorText.contains('BOOM'), res.errorText);
    }

    @IsTest
    static void queryWithNoRows() {
        InsightsData360.testRunner = new EmptyRunner();
        InsightsRunQuery.Response res = InsightsRunQuery.runOne('SELECT * FROM Insights_Returns__dll WHERE return_status__c = \'Lost\'');
        System.assertEquals('NOTHING_THERE', res.resultCode);
        System.assertEquals('0', res.rowCount);
    }

    private class EmptyRunner implements InsightsData360.Runner {
        public InsightsData360.Result run(String sql) {
            InsightsData360.Result r = new InsightsData360.Result();
            r.columns = new List<String>{ 'return_id__c' };
            return r;
        }
    }

    @IsTest
    static void customerIdForms() {
        System.assertEquals('C01', InsightsData360.customerId('1'));
        System.assertEquals('C01', InsightsData360.customerId('Customer 1'));
        System.assertEquals('C01', InsightsData360.customerId('C01'));
        System.assertEquals('C07', InsightsData360.customerId('customer seven'));
        System.assertEquals('C10', InsightsData360.customerId('Customer 10'));
        System.assertEquals(null, InsightsData360.customerId('Customer 11'));
        System.assertEquals(null, InsightsData360.customerId('nobody'));
        System.assertEquals(null, InsightsData360.customerId(null));
    }

    @IsTest
    static void cellFormats() {
        System.assertEquals('5', InsightsData360.cell('5.000000000000000000'));
        System.assertEquals('162.5', InsightsData360.cell('162.500000000000000000'));
        System.assertEquals('100', InsightsData360.cell('100.000'));
        System.assertEquals('', InsightsData360.cell(null));
        System.assertEquals('2026-05-25', InsightsData360.cell('2026-05-25'));
        System.assertEquals('0', InsightsData360.cell('0E-18'));
        System.assertEquals('0', InsightsData360.cell(Decimal.valueOf('0.000000000000000000')));
        System.assertEquals('2.5', InsightsData360.cell(Decimal.valueOf('2.500')));
        System.assertEquals('C01', InsightsData360.cell('C01'));
    }

    @IsTest
    static void textTableCutsLongResults() {
        InsightsData360.Result r = new InsightsData360.Result();
        r.columns = new List<String>{ 'a__c', 'b__c' };
        for (Integer i = 0; i < 5; i++) {
            r.rows.add(new List<String>{ String.valueOf(i), 'x' });
        }
        String t = InsightsData360.toText(r, 3);
        System.assert(t.startsWith('a | b'), t);
        System.assert(t.contains('(2 more rows not shown)'), t);
    }

    @IsTest
    static void overviewBuildsTheWholePicture() {
        FakeRunner f = useFake();
        InsightsCustomerOverview.Request req = new InsightsCustomerOverview.Request();
        req.customer = 'customer one';
        InsightsCustomerOverview.Response res = InsightsCustomerOverview.run(new List<InsightsCustomerOverview.Request>{ req })[0];
        System.assertEquals('FOUND', res.resultCode, res.errorText);
        System.assertEquals('C01', res.customerId);
        System.assertEquals('Customer 1', res.customerName);
        System.assert(res.overviewText.contains('Total spend (not counting cancelled orders): 352'), res.overviewText);
        System.assert(res.overviewText.contains('Late deliveries: 1'), res.overviewText);
        System.assert(res.overviewText.contains('Tickets not resolved: 1'), res.overviewText);
        System.assert(res.overviewText.contains('Barista Coffee Machine x1'), res.overviewText);
        System.assert(res.overviewText.contains('NPS 9'), res.overviewText);
        System.assert(res.sourcesUsed.contains('Survey tool'), res.sourcesUsed);
        System.assertEquals(7, f.seen.size());
    }

    @IsTest
    static void overviewRefusesAndFindsNothing() {
        useFake();
        System.assertEquals('REFUSED', InsightsCustomerOverview.overview('Customer 42').resultCode);
        System.assertEquals('NOTHING_THERE', InsightsCustomerOverview.overview('Customer 9').resultCode);
    }

    @IsTest
    static void overviewErrorComesBackAsResult() {
        InsightsData360.testRunner = new ThrowingRunner();
        InsightsCustomerOverview.Response res = InsightsCustomerOverview.overview('2');
        System.assertEquals('ERROR', res.resultCode);
        System.assert(res.errorText.contains('down'), res.errorText);
    }

    private class ThrowingRunner implements InsightsData360.Runner {
        public InsightsData360.Result run(String sql) {
            throw new IllegalArgumentException('Data 360 is down');
        }
    }

    @IsTest
    static void sourcesListsEightTables() {
        useFake();
        InsightsListSources.Response res = InsightsListSources.run(new List<InsightsListSources.Request>{ new InsightsListSources.Request() })[0];
        System.assertEquals('FOUND', res.resultCode, res.errorText);
        System.assertEquals(8, res.sourcesText.split('\n').size());
        System.assert(res.sourcesText.contains('Help desk: table Insights_Tickets__dll'), res.sourcesText);
        System.assert(res.sourcesText.contains('Rows: 10'), res.sourcesText);
    }

    @IsTest
    static void sourcesErrorComesBackAsResult() {
        InsightsData360.testRunner = new ThrowingRunner();
        InsightsListSources.Response res = InsightsListSources.listSources();
        System.assertEquals('ERROR', res.resultCode);
    }
}
