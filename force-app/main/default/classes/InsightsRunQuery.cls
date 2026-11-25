/**
 * Customer Insights (demo), action "Run a data query".
 *
 * The model writes one Data 360 SQL SELECT on the eight source tables of the demo.
 * This action runs it (read only) and gives back the rows as a text table, the source
 * systems that the query used, and the SQL that ran. It never throws: an error comes
 * back as resultCode ERROR with the error text, so the model can correct the SQL.
 *
 * Checks: one statement, SELECT or WITH only, only the eight source tables, and at
 * most 200 rows (a LIMIT is added when the SQL has none).
 */
public with sharing class InsightsRunQuery {

    public static final Integer MAX_ROWS = 200;

    public class Request {
        @InvocableVariable(label='SQL query' description='One Data 360 SQL SELECT statement on the eight Insights tables' required=true)
        public String sqlQuery;
        @InvocableVariable(label='Question' description='The question of the user, in words' required=false)
        public String question;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND, NOTHING_THERE, REFUSED or ERROR')
        public String resultCode;
        @InvocableVariable(label='Row count' description='The number of rows')
        public String rowCount;
        @InvocableVariable(label='Result table' description='The rows as a text table, with a header line')
        public String resultTable;
        @InvocableVariable(label='Sources used' description='The source systems of the tables that the query used')
        public String sourcesUsed;
        @InvocableVariable(label='SQL run' description='The SQL that ran')
        public String sqlRun;
        @InvocableVariable(label='Error text' description='The error, when the result code is REFUSED or ERROR')
        public String errorText;
    }

    @InvocableMethod(label='Run a data query' description='Runs one Data 360 SQL SELECT on the eight Insights tables and gives back the rows.')
    public static List<Response> run(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request r : requests) {
            responses.add(runOne(r == null ? null : r.sqlQuery));
        }
        return responses;
    }

    @TestVisible
    static Response runOne(String rawSql) {
        Response out = new Response();
        out.rowCount = '0';
        out.resultTable = '';
        out.sourcesUsed = '';
        out.errorText = '';
        String sql = clean(rawSql);
        out.sqlRun = sql;

        String refusal = refusalFor(sql);
        if (refusal != null) {
            out.resultCode = 'REFUSED';
            out.errorText = refusal;
            return out;
        }
        if (!Pattern.compile('(?is)\\blimit\\s+[0-9]+\\s*$').matcher(sql).find()) {
            sql = sql + ' LIMIT ' + MAX_ROWS;
        }
        out.sqlRun = sql;
        out.sourcesUsed = InsightsData360.sourcesIn(sql);
        try {
            InsightsData360.Result result = InsightsData360.query(sql);
            out.rowCount = String.valueOf(result.rows.size());
            out.resultCode = result.rows.isEmpty() ? 'NOTHING_THERE' : 'FOUND';
            out.resultTable = InsightsData360.toText(result, MAX_ROWS);
        } catch (Exception e) {
            out.resultCode = 'ERROR';
            out.errorText = InsightsData360.errorText(e);
        }
        return out;
    }

    /** The SQL without spaces at the ends and without one final semicolon. */
    @TestVisible
    static String clean(String sql) {
        String s = sql == null ? '' : sql.trim();
        if (s.endsWith(';')) {
            s = s.removeEnd(';').trim();
        }
        return s;
    }

    /** The cause of a refusal, or null when the SQL can run. */
    @TestVisible
    static String refusalFor(String sql) {
        if (String.isBlank(sql)) {
            return 'No SQL was given.';
        }
        if (!Pattern.compile('(?is)^\\s*(select|with)\\b').matcher(sql).find()) {
            return 'Only one SELECT statement (or WITH ... SELECT) can run.';
        }
        if (sql.contains(';')) {
            return 'Only one statement can run. Remove the semicolons.';
        }
        if (!InsightsData360.onlyKnownTables(sql)) {
            List<String> names = new List<String>();
            for (InsightsData360.SourceTable t : InsightsData360.TABLES) {
                names.add(t.dlo);
            }
            return 'Use only these tables: ' + String.join(names, ', ') + '.';
        }
        return null;
    }
}