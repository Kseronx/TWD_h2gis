package main.java.connect;

import org.h2.tools.RunScript;

import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class InitH2GIS {

    public static String JDBC_DRIVER = "org.h2.Driver";
    public static String db = "jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000";
    public static String sqlScript = "init_h2gis_import_existing_csv.sql";
    public static String user = "sa";
    public static String pwd = "";

    public static void main(String[] args) {
        String dbUrl = args.length >= 1 && !args[0].trim().isEmpty() ? args[0].trim() : db;
        String scriptPath = args.length >= 2 && !args[1].trim().isEmpty() ? args[1].trim() : sqlScript;

        try {
            Class.forName(JDBC_DRIVER);

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pwd)) {

                System.out.println("Connected to H2 database");
                System.out.println("Database URL: " + dbUrl);
                System.out.println("Working directory: " + System.getProperty("user.dir"));
                initialize(conn, scriptPath);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    public static void initialize(Connection conn, String scriptPath) throws Exception {
        try (Statement stmt = conn.createStatement()) {
            System.out.println("SQL script: " + scriptPath);
            stmt.execute("CREATE ALIAS IF NOT EXISTS H2GIS_SPATIAL FOR \"org.h2gis.functions.factory.H2GISFunctions.load\";");
            stmt.execute("CALL H2GIS_SPATIAL();");
            System.out.println("H2GIS spatial functions loaded");
        }

        RunScript.execute(conn, new FileReader(scriptPath));
        System.out.println(scriptPath + " executed successfully");
    }
}
