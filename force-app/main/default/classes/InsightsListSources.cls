/**
 * Customer Insights (demo), action "List the data sources".
 *
 * For each of the eight source tables: the source system that it stands for, the
 * Data 360 table, what it holds, the number of rows (a Data 360 count) and the time
 * of the last load (DataStream.LastRefreshDate). It never throws.
 */
public with sharing class InsightsListSources {

    public class Request {
        @InvocableVariable(label='Topic' description='Optional: what the user wants to know about the sources' required=false)
        public String topic;
    }

    public class Response {
        @InvocableVariable(label='Result code' description='FOUND or ERROR')
        public String resultCode;
        @InvocableVariable(label='Sources' description='One line for each source table: system, table, contents, rows, last load')
        public String sourcesText;
        @InvocableVariable(label='Error text' description='The error, when the result code is ERROR')
        public String errorText;
    }

    @InvocableMethod(label='List the data sources' description='Lists the eight source tables of the Insights demo in Data 360, with row counts and load times.')
    public static List<Response> run(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response one = listSources();
        for (Integer i = 0; i < (requests == null ? 1 : Math.max(1, requests.size())); i++) {
            responses.add(one);
        }
        return responses;
    }

    @TestVisible
    static Response listSources() {
        Response out = new Response();
        out.errorText = '';
        try {
            Map<String, Datetime> loads = loadTimes();
            List<String> lines = new List<String>();
            for (InsightsData360.SourceTable t : InsightsData360.TABLES) {
                InsightsData360.Result r = InsightsData360.query('SELECT COUNT(*) AS row_count FROM ' + t.dlo);
                String rows = r.rows.isEmpty() || r.rows[0].isEmpty() ? '?' : r.rows[0][0];
                Datetime loaded = loads.get(t.streamName);
                lines.add('- ' + t.sourceSystem + ': table ' + t.dlo + ' (data stream "' + t.streamName + '"), '
                    + t.holds + '. Rows: ' + rows + '. Last load: '
                    + (loaded == null ? 'unknown' : loaded.formatGmt('yyyy-MM-dd HH:mm') + ' UTC') + '.');
            }
            out.sourcesText = String.join(lines, '\n');
            out.resultCode = 'FOUND';
        } catch (Exception e) {
            out.resultCode = 'ERROR';
            out.sourcesText = '';
            out.errorText = InsightsData360.errorText(e);
        }
        return out;
    }

    /** The last refresh of each data stream, by data stream name. */
    static Map<String, Datetime> loadTimes() {
        Map<String, Datetime> out = new Map<String, Datetime>();
        List<String> names = new List<String>();
        for (InsightsData360.SourceTable t : InsightsData360.TABLES) {
            names.add(t.streamName);
        }
        try {
            for (SObject s : Database.query('SELECT Name, LastRefreshDate FROM DataStream WHERE Name IN :names')) {
                out.put((String) s.get('Name'), (Datetime) s.get('LastRefreshDate'));
            }
        } catch (Exception e) {
            // No DataStream object (for example in a test): the load times stay unknown.
        }
        return out;
    }
}