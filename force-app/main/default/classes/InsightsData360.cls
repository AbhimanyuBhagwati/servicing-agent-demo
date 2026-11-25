/**
 * Customer Insights (demo): the shared Data 360 code of the three insight actions.
 *
 * The data is invented test data: 10 customers of an invented online store, in eight
 * Data 360 data streams (file uploads, see data360/insights/). Each data stream
 * stands for one source system of the store: CRM, product catalog, web shop (two
 * tables), help desk, warehouse returns, review site and survey tool.
 *
 * The queries are Data 360 SQL (ANSI SQL) through ConnectApi.CdpQuery.queryAnsiSqlV2.
 * A Data 360 query is read only. Apex tests cannot query Data 360, so the tests set a
 * fake runner (testRunner).
 */
public with sharing class InsightsData360 {

    /** One source table: a Data 360 data lake object, filled by one data stream. */
    public class SourceTable {
        public String dlo;
        public String sourceSystem;
        public String streamName;
        public String holds;
        public SourceTable(String dlo, String sourceSystem, String streamName, String holds) {
            this.dlo = dlo;
            this.sourceSystem = sourceSystem;
            this.streamName = streamName;
            this.holds = holds;
        }
    }

    public static final List<SourceTable> TABLES = new List<SourceTable>{
        new SourceTable('Insights_Customers__dll', 'CRM', 'Insights Customers', 'the 10 customers: name, city, joined date, loyalty tier'),
        new SourceTable('Insights_Products__dll', 'Product catalog', 'Insights Products', 'the 12 products: name, category, supplier, price'),
        new SourceTable('Insights_Orders__dll', 'Web shop', 'Insights Orders', 'the orders: date, status, carrier, promised and delivered date, total'),
        new SourceTable('Insights_Order_Lines__dll', 'Web shop', 'Insights Order Lines', 'the products in each order: quantity and price'),
        new SourceTable('Insights_Tickets__dll', 'Help desk', 'Insights Tickets', 'the support tickets: category, subject, priority, status, resolution, CSAT'),
        new SourceTable('Insights_Returns__dll', 'Warehouse returns system', 'Insights Returns', 'the returns: reason, status, refund'),
        new SourceTable('Insights_Reviews__dll', 'Review site', 'Insights Reviews', 'the product reviews: rating 1 to 5, title, text'),
        new SourceTable('Insights_Surveys__dll', 'Survey tool', 'Insights Surveys', 'the NPS survey answers: score 0 to 10, comment')
    };

    /** The rows of one query, as text. */
    public class Result {
        public List<String> columns = new List<String>();
        public List<List<String>> rows = new List<List<String>>();
    }

    public interface Runner {
        Result run(String sql);
    }

    /** Test only: a fake runner in place of Data 360. */
    @TestVisible
    static Runner testRunner;

    public static Result query(String sql) {
        return (testRunner != null ? testRunner : new Data360Runner()).run(sql);
    }

    /** The real runner: Data 360. */
    public class Data360Runner implements Runner {
        public Result run(String sql) {
            ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
            input.sql = sql;
            ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(input);
            Result result = new Result();
            Integer width = output.metadata == null ? 0 : output.metadata.size();
            List<String> names = new List<String>();
            for (Integer i = 0; i < width; i++) {
                names.add('');
            }
            if (output.metadata != null) {
                for (String name : output.metadata.keySet()) {
                    Integer place = output.metadata.get(name).placeInOrder;
                    if (place != null && place < width) {
                        names[place] = name;
                    }
                }
            }
            result.columns = names;
            if (output.data != null) {
                for (ConnectApi.CdpQueryV2Row row : output.data) {
                    List<String> cells = new List<String>();
                    for (Object value : row.rowData) {
                        cells.add(cell(value));
                    }
                    result.rows.add(cells);
                }
            }
            return result;
        }
    }

    /** One value as text: no trailing zeros and no exponent on numbers, empty for null. */
    public static String cell(Object value) {
        if (value == null) {
            return '';
        }
        if (value instanceof Decimal) {
            return plain((Decimal) value);
        }
        String s = String.valueOf(value).trim();
        if (Pattern.matches('-?[0-9]+(\\.[0-9]+)?([eE][-+]?[0-9]+)?', s) && (s.contains('.') || s.containsIgnoreCase('e'))) {
            try {
                return plain(Decimal.valueOf(s));
            } catch (Exception e) {
                return s;
            }
        }
        return s;
    }

    /** A number as plain text: 5 for 5.000, 162.5 for 162.500, 0 for 0E-18. */
    static String plain(Decimal d) {
        if (d == 0) {
            return '0';
        }
        Decimal x = d.stripTrailingZeros();
        if (x.scale() < 0) {
            x = x.setScale(0);
        }
        return x.toPlainString();
    }

    /** The rows as a text table: a header line, then one line for each row. */
    public static String toText(Result result, Integer maxRows) {
        List<String> lines = new List<String>();
        lines.add(String.join(shortNames(result.columns), ' | '));
        Integer n = 0;
        for (List<String> row : result.rows) {
            if (n == maxRows) {
                lines.add('(' + (result.rows.size() - maxRows) + ' more rows not shown)');
                break;
            }
            lines.add(String.join(row, ' | '));
            n++;
        }
        return String.join(lines, '\n');
    }

    /** Column names without the __c of Data 360, for the reader. */
    static List<String> shortNames(List<String> columns) {
        List<String> out = new List<String>();
        for (String c : columns) {
            out.add(c == null ? '' : c.removeEndIgnoreCase('__c'));
        }
        return out;
    }

    /** The data lake object names in a SQL text, lower case. */
    public static Set<String> tablesIn(String sql) {
        Set<String> found = new Set<String>();
        Matcher m = Pattern.compile('(?i)\\b([A-Za-z0-9_]+__dl[lm])\\b').matcher(sql == null ? '' : sql);
        while (m.find()) {
            found.add(m.group(1).toLowerCase());
        }
        return found;
    }

    /** The source systems of the tables in a SQL text, for example "Help desk (Insights_Tickets)". */
    public static String sourcesIn(String sql) {
        Set<String> used = tablesIn(sql);
        List<String> out = new List<String>();
        for (SourceTable t : TABLES) {
            if (used.contains(t.dlo.toLowerCase())) {
                out.add(t.sourceSystem + ' (' + t.dlo.removeEnd('__dll') + ')');
            }
        }
        return String.join(out, ', ');
    }

    /** True when each table in the SQL text is one of the eight source tables. */
    public static Boolean onlyKnownTables(String sql) {
        Set<String> known = new Set<String>();
        for (SourceTable t : TABLES) {
            known.add(t.dlo.toLowerCase());
        }
        Set<String> used = tablesIn(sql);
        return !used.isEmpty() && known.containsAll(used);
    }

    private static final Map<String, Integer> NUMBER_WORDS = new Map<String, Integer>{
        'one' => 1, 'two' => 2, 'three' => 3, 'four' => 4, 'five' => 5,
        'six' => 6, 'seven' => 7, 'eight' => 8, 'nine' => 9, 'ten' => 10
    };

    /** "1", "Customer 1", "C01", "c1" or "customer one" as the customer ID "C01". Null when it is not 1 to 10. */
    public static String customerId(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim().toLowerCase();
        Integer n;
        Matcher digits = Pattern.compile('([0-9]{1,3})').matcher(s);
        if (digits.find()) {
            n = Integer.valueOf(digits.group(1));
        } else {
            for (String word : NUMBER_WORDS.keySet()) {
                if (Pattern.compile('\\b' + word + '\\b').matcher(s).find()) {
                    n = NUMBER_WORDS.get(word);
                    break;
                }
            }
        }
        if (n == null || n < 1 || n > 10) {
            return null;
        }
        return 'C' + String.valueOf(n).leftPad(2, '0');
    }

    /** The error text of an exception, short. */
    public static String errorText(Exception e) {
        String text = e.getTypeName() + ': ' + e.getMessage();
        return text.length() > 600 ? text.left(600) + '...' : text;
    }
}
