package main.java.connect;

import org.h2.tools.RunScript;

import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class InitH2GIS {

    public static String JDBC_DRIVER = "org.h2.Driver";
    public static String db = "jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000";
    public static String user = "sa";
    public static String pwd = "";

    public static void main(String[] args) {
        try {
            Class.forName(JDBC_DRIVER);

            try (Connection conn = DriverManager.getConnection(db, user, pwd);
                 Statement stmt = conn.createStatement()) {

                System.out.println("Connected to H2 database");
                System.out.println("Working directory: " + System.getProperty("user.dir"));

                stmt.execute("CREATE ALIAS IF NOT EXISTS H2GIS_SPATIAL FOR \"org.h2gis.functions.factory.H2GISFunctions.load\";");
                stmt.execute("CALL H2GIS_SPATIAL();");
                System.out.println("H2GIS spatial functions loaded");

                RunScript.execute(conn, new FileReader("init_h2gis_import_existing_csv.sql"));
                //RunScript.execute(conn, new FileReader("add_h2gis_benchmark_indexes_optional.sql"));
                System.out.println("init_h2gis_import_existing_csv.sql executed successfully");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
