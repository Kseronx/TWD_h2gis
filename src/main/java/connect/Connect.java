package main.java.connect;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Properties;

import main.java.perf.Performance;
import main.java.veracity.ResultsetVeracity;

public class Connect {

    public static String JDBC_DRIVER = "org.h2.Driver";

    public static String db = "jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000;IFEXISTS=TRUE";
    public static String memoryDb = "jdbc:h2:mem:vesselstraj;DB_CLOSE_DELAY=-1;LOCK_TIMEOUT=600000";
    public static String user = "sa";
    public static String pwd = "";

    public static Properties point_sch_workload_prop = new Properties();
    public static Properties shape5_sch_workload_prop = new Properties();
    public static Properties shape6_sch_workload_prop = new Properties();
    public static ArrayList<String> point_queries_ids;
    public static ArrayList<String> shape5_queries_ids;
    public static ArrayList<String> shape6_queries_ids;

    static Connection conn = null;
    static Statement stmt = null;
    static FileWriter perf_file;
    static FileWriter scale_file;
    static PrintStream log_file;
    static List<Integer> empty = Arrays.asList();
    static List<Integer> one = Arrays.asList(1);
    static List<Integer> two = Arrays.asList(2);
    static List<Integer> three_four = Arrays.asList(3, 4);
    static List<Integer> one_two = Arrays.asList(1, 2);
    static List<Integer> two_three = Arrays.asList(2, 3);
    static List<Integer> one_to_four = Arrays.asList(1, 2, 3, 4);
    static List<Integer> five = Arrays.asList(5);

    private static final String[] BATCH_PATTERNS = {
            "all",
            "SpatialJoin_Group_NumAgg",
            "SpatialJoin_Group_SpatialAgg",
            "SpatialJoin_NoGroup_NoAgg",
            "SpatialJoin_NoGroup_NumAgg",
            "SpatialJoin_NoGroup_SpatialAgg",
            "EquiJoin_Group_NumAgg",
            "EquiJoin_Group_SpatialAgg",
            "EquiJoin_NoGroup_NoAgg",
            "EquiJoin_NoGroup_NumAgg",
            "EquiJoin_NoGroup_SpatialAgg",
            "NoJoin_NoGroup_NumAgg",
            "NoJoin_NoGroup_SpatialAgg"
    };

    public static void main(String[] args) {
        boolean numerical_veracity = true;
        boolean logging_to_file = true;
        boolean database_1month = false;

        String workload = "", database = "";
        try {
            RunOptions options = parseRunOptions(args);
            String selectedBatch = getSelectedBatch(options.batchNumber);
            workload = getWorkloadSuffix(options.batchNumber) + "_" + options.storageMode;
            if (database_1month) database = "_1month"; else database = "_1day";
            load_property_files();

            perf_file = new FileWriter("perf_file" + workload + database + ".csv");
            scale_file = new FileWriter("scale_file" + workload + database + ".csv");
            if (logging_to_file) {
                log_file = new PrintStream(new File("log_file" + workload + database + ".txt"));
                System.setOut(log_file);
                System.setErr(log_file);
            }

            Class.forName(JDBC_DRIVER);

            String dbUrl = options.dbUrl != null ? options.dbUrl : getDefaultDbUrl(options.storageMode);
            String initDbUrl = toInitH2Url(dbUrl);
            conn = DriverManager.getConnection(initDbUrl, user, pwd);

            System.out.println("connected");
            System.out.println("Storage mode: " + options.storageMode);
            System.out.println("Database URL: " + initDbUrl);
            System.out.println("Working directory: " + System.getProperty("user.dir"));
            System.out.println("Initializing fresh H2GIS database");
            InitH2GIS.initialize(conn, InitH2GIS.sqlScript);

            stmt = conn.createStatement();
            System.out.println("Selected batch: " + options.batchNumber + " (" + BATCH_PATTERNS[options.batchNumber] + ")");

            int nbr_series = point_queries_ids.size();
            String[] patterns;
            String five_patterns, three_patterns;

            for (int i = 0; i < nbr_series; i++) {
                System.out.println("Serie: " + i + " on: " + nbr_series);
                patterns = point_queries_ids.get(i).split("_");

                five_patterns = String.join("_", patterns[0], patterns[1], patterns[2], patterns[3], patterns[4]);
                three_patterns = String.join("_", patterns[0], patterns[1], patterns[2]);
                System.out.println("PATTERN 5 PREFIX: " + five_patterns);

                if (selectedBatch != null && !three_patterns.equals(selectedBatch)) {
                    continue;
                }

                if (three_patterns.equals("SpatialJoin_Group_NumAgg")
                        || three_patterns.equals("SpatialJoin_Group_SpatialAgg")) {
                    executeQuery(point_sch_workload_prop.getProperty(point_queries_ids.get(i)),
                            shape5_sch_workload_prop.getProperty(shape5_queries_ids.get(i)),
                            shape6_sch_workload_prop.getProperty(shape6_queries_ids.get(i)),
                            five_patterns,
                            one,
                            two,
                            numerical_veracity);
                } else if (three_patterns.equals("EquiJoin_Group_SpatialAgg")) {
                    executeQuery(point_sch_workload_prop.getProperty(point_queries_ids.get(i)),
                            shape5_sch_workload_prop.getProperty(shape5_queries_ids.get(i)),
                            shape6_sch_workload_prop.getProperty(shape6_queries_ids.get(i)),
                            five_patterns,
                            one_to_four,
                            five,
                            numerical_veracity);
                } else if (three_patterns.equals("SpatialJoin_NoGroup_NumAgg")
                        || three_patterns.equals("EquiJoin_NoGroup_NumAgg")
                        || three_patterns.equals("EquiJoin_NoGroup_SpatialAgg")
                        || three_patterns.equals("NoJoin_NoGroup_SpatialAgg")
                        || three_patterns.equals("SpatialJoin_NoGroup_SpatialAgg")) {
                    executeQuery(point_sch_workload_prop.getProperty(point_queries_ids.get(i)),
                            shape5_sch_workload_prop.getProperty(shape5_queries_ids.get(i)),
                            shape6_sch_workload_prop.getProperty(shape6_queries_ids.get(i)),
                            five_patterns,
                            empty,
                            one,
                            numerical_veracity);
                } else if (three_patterns.equals("NoJoin_NoGroup_NumAgg")) {
                    executeQuery(point_sch_workload_prop.getProperty(point_queries_ids.get(i)),
                            shape5_sch_workload_prop.getProperty(shape5_queries_ids.get(i)),
                            shape6_sch_workload_prop.getProperty(shape6_queries_ids.get(i)),
                            five_patterns,
                            empty,
                            one_two,
                            numerical_veracity);
                } else if (three_patterns.equals("EquiJoin_Group_NumAgg")) {
                    executeQuery(point_sch_workload_prop.getProperty(point_queries_ids.get(i)),
                            shape5_sch_workload_prop.getProperty(shape5_queries_ids.get(i)),
                            shape6_sch_workload_prop.getProperty(shape6_queries_ids.get(i)),
                            five_patterns,
                            one,
                            two_three,
                            numerical_veracity);
                } else if (three_patterns.equals("SpatialJoin_NoGroup_NoAgg")
                        || three_patterns.equals("EquiJoin_NoGroup_NoAgg")) {
                    executeQuery(point_sch_workload_prop.getProperty(point_queries_ids.get(i)),
                            shape5_sch_workload_prop.getProperty(shape5_queries_ids.get(i)),
                            shape6_sch_workload_prop.getProperty(shape6_queries_ids.get(i)),
                            five_patterns,
                            one,
                            three_four,
                            !numerical_veracity);
                }
            }

            stmt.close();
            conn.close();
            perf_file.close();
            scale_file.close();

        } catch (SQLException se) {
            se.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (stmt != null) stmt.close();
            } catch (SQLException se2) {
            }
            try {
                if (conn != null) conn.close();
            } catch (SQLException se) {
                se.printStackTrace();
            }
            if (log_file != null) {
                log_file.flush();
                log_file.close();
            }
        }
    }

    private static RunOptions parseRunOptions(String[] args) {
        RunOptions options = new RunOptions();
        options.batchNumber = 0;
        options.storageMode = "file";

        if (args.length >= 1 && args[0] != null && !args[0].trim().isEmpty()) {
            String batchArg = args[0].trim();
            if (!isInteger(batchArg)) {
                throw new IllegalArgumentException("First argument must be a batch number between 0 and 12. Got: " + batchArg);
            }
            int batchNumber = Integer.parseInt(batchArg);
            if (batchNumber < 0 || batchNumber >= BATCH_PATTERNS.length) {
                throw new IllegalArgumentException("Batch number must be between 0 and 12. Got: " + batchArg);
            }
            options.batchNumber = batchNumber;
        }

        if (args.length >= 2 && args[1] != null && !args[1].trim().isEmpty()) {
            options.storageMode = normalizeStorageMode(args[1].trim());
        }

        if (args.length >= 3 && args[2] != null && !args[2].trim().isEmpty()) {
            options.dbUrl = normalizeH2Url(args[2].trim());
        }

        if (args.length > 3) {
            throw new IllegalArgumentException("Usage: Connect [batch_number] [file|memory] [jdbc_h2_url]");
        }

        return options;
    }

    private static String normalizeStorageMode(String value) {
        String lower = value.toLowerCase();
        if (lower.equals("file")) {
            return "file";
        }
        if (lower.equals("memory") || lower.equals("mem") || lower.equals("in-memory") || lower.equals("inmemory")) {
            return "memory";
        }
        throw new IllegalArgumentException("Second argument must be file or memory. Got: " + value);
    }

    private static boolean isInteger(String value) {
        try {
            Integer.parseInt(value);
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    private static String normalizeH2Url(String value) {
        if (value == null || value.trim().isEmpty()) {
            return db;
        }
        String trimmed = value.trim();
        if (trimmed.startsWith("jdbc:h2:")) {
            return trimmed;
        }
        return "jdbc:h2:" + trimmed;
    }

    private static String getDefaultDbUrl(String storageMode) {
        return storageMode.equals("memory") ? memoryDb : db;
    }

    private static String toInitH2Url(String dbUrl) {
        return dbUrl.replaceAll("(?i);IFEXISTS=TRUE", "");
    }

    private static class RunOptions {
        int batchNumber;
        String storageMode;
        String dbUrl;
    }

    private static String getSelectedBatch(int batchNumber) {
        return batchNumber == 0 ? null : BATCH_PATTERNS[batchNumber];
    }

    private static String getWorkloadSuffix(int batchNumber) {
        if (batchNumber == 0) {
            return "_all";
        }
        return "_batch" + String.format("%02d", batchNumber) + "_" + BATCH_PATTERNS[batchNumber];
    }

    public static void load_property_files() {
        try {
            InputStream input_point = new FileInputStream("point_sch_workload.properties");
            InputStream input_shape5 = new FileInputStream("shape5_sch_workload.properties");
            InputStream input_shape6 = new FileInputStream("shape6_sch_workload.properties");

            point_sch_workload_prop.load(input_point);
            shape5_sch_workload_prop.load(input_shape5);
            shape6_sch_workload_prop.load(input_shape6);

            point_queries_ids = new ArrayList<>(point_sch_workload_prop.stringPropertyNames());
            Collections.sort(point_queries_ids);

            shape5_queries_ids = new ArrayList<>(shape5_sch_workload_prop.stringPropertyNames());
            Collections.sort(shape5_queries_ids);

            shape6_queries_ids = new ArrayList<>(shape6_sch_workload_prop.stringPropertyNames());
            Collections.sort(shape6_queries_ids);

            input_point.close();
            input_shape5.close();
            input_shape6.close();

        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }

    public static void executeQuery(String query_statement_point,
                                    String query_statement_shape5,
                                    String query_statement_shape6,
                                    String query_pattern,
                                    List<Integer> list_of_feature_columns,
                                    List<Integer> list_of_target_columns,
                                    boolean numerical_veracity) {

        long start, finish;
        long time_elapsed_point, time_elapsed_shape5, time_elapsed_shape6;
        Performance query_perf;
        ResultsetVeracity rv = null;

        System.out.println("Query pattern: " + query_pattern);
        try {
            System.out.println("RUN " + query_statement_point);
            start = System.currentTimeMillis();
            ResultSet rs_point = stmt.executeQuery(query_statement_point);
            finish = System.currentTimeMillis();
            time_elapsed_point = finish - start;
            query_perf = new Performance(query_pattern, "point", time_elapsed_point, null);
            perf_file.write(query_perf.toCSV() + "\n");
            perf_file.flush();

            HashMap<String, List<Object>> point_rs_map = resultSetToMap(rs_point,
                    list_of_feature_columns,
                    list_of_target_columns);

            System.out.println("RUN " + query_statement_shape5);
            start = System.currentTimeMillis();
            ResultSet rs_shape = stmt.executeQuery(query_statement_shape5);
            finish = System.currentTimeMillis();
            time_elapsed_shape5 = finish - start;

            HashMap<String, List<Object>> shape_rs_map = resultSetToMap(rs_shape,
                    list_of_feature_columns,
                    list_of_target_columns);
            rv = new ResultsetVeracity();
            rv.compute_metrics(point_rs_map, shape_rs_map, list_of_target_columns, numerical_veracity);

            query_perf = new Performance(query_pattern, "shape5", time_elapsed_shape5, rv);
            perf_file.write(query_perf.toCSV() + "\n");
            perf_file.flush();

            System.out.println("RUN " + query_statement_shape6);
            start = System.currentTimeMillis();
            rs_shape = stmt.executeQuery(query_statement_shape6);
            finish = System.currentTimeMillis();
            time_elapsed_shape6 = finish - start;

            shape_rs_map = resultSetToMap(rs_shape,
                    list_of_feature_columns,
                    list_of_target_columns);
            rv = new ResultsetVeracity();
            rv.compute_metrics(point_rs_map, shape_rs_map, list_of_target_columns, numerical_veracity);

            query_perf = new Performance(query_pattern, "shape6", time_elapsed_shape6, rv);
            perf_file.write(query_perf.toCSV() + "\n");
            perf_file.flush();

            scale_file.write(query_pattern + "," +
                    (double) time_elapsed_point / time_elapsed_shape5 + "," +
                    (double) time_elapsed_point / time_elapsed_shape6 + "," +
                    (double) time_elapsed_shape6 / time_elapsed_shape5 + "," +
                    (1 - (double) time_elapsed_point / time_elapsed_shape5) * 100 + "," +
                    (1 - (double) time_elapsed_point / time_elapsed_shape6) * 100 + "," +
                    (1 - (double) time_elapsed_shape6 / time_elapsed_shape5) * 100 + "\n");
            scale_file.flush();
            rs_shape.close();
            rs_point.close();

        } catch (SQLException se) {
            System.out.println("ERROR: " + query_pattern);
            se.printStackTrace();
        } catch (Exception e) {
            System.out.println("ERROR: " + query_pattern);
            e.printStackTrace();
        }
    }

    public static HashMap<String, List<Object>> resultSetToMap(ResultSet rs,
                                                                List<Integer> list_of_feature_columns,
                                                                List<Integer> list_of_target_columns) throws SQLException {

        HashMap<String, List<Object>> map = new HashMap<>();
        List<Object> list_of_values;
        String key;
        ResultSetMetaData metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();

        if (list_of_feature_columns.isEmpty()) {
            key = "dummy";
            while (rs.next()) {
                list_of_values = new ArrayList<Object>();
                for (int i = 1; i <= columnCount; i++) {
                    if (list_of_target_columns.contains(i)) {
                        list_of_values.add(rs.getObject(i));
                    }
                }
                map.put(key, list_of_values);
            }
        } else {
            while (rs.next()) {
                list_of_values = new ArrayList<Object>();
                key = "";
                for (int i = 1; i <= columnCount; i++) {
                    if (list_of_feature_columns.contains(i)) {
                        key += rs.getObject(i);
                    } else if (list_of_target_columns.contains(i)) {
                        list_of_values.add(rs.getObject(i));
                    }
                }
                map.put(key, list_of_values);
            }
        }
        return map;
    }
}
