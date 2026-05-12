
package main.java.veracity;

import java.sql.SQLException;
import java.util.*;

public class ResultsetVeracity {

    private static final double MISSING = -9999.0;

    public int nbr_of_matches;
    public int nbr_of_false_negative;
    public int nbr_of_false_positive;

    public List<Double> SSE;
    public List<Double> RMSE;
    public List<Double> R_squared;

    @Override
    public String toString() {
        return "ResultsetVeracity [" +
                "matches=" + nbr_of_matches +
                ", false_negatives=" + nbr_of_false_negative +
                ", false_positives=" + nbr_of_false_positive +
                ", SSE=" + SSE +
                ", RMSE=" + RMSE +
                ", R^2=" + R_squared +
                "]";
    }
	
    public String toCSV() {
        return "" + nbr_of_matches + ","
                + nbr_of_false_negative + ","
                + nbr_of_false_positive +  ","
                + SSE +  ","
                + RMSE +  ","
                + R_squared ;
    }
    public ResultsetVeracity() {}

    public void compute_metrics(
            HashMap<String, List<Object>> accurate_rs_map,
            HashMap<String, List<Object>> approximate_rs_map,
	    List<Integer> list_of_feature_columns,	
            List<Integer> list_of_target_columns,
            boolean numerical_veracity)
            throws SQLException {

        int T = numerical_veracity ? list_of_target_columns.size() : 1;

        this.SSE = new ArrayList<>(Collections.nCopies(T, 0.0));
        this.RMSE = new ArrayList<>(Collections.nCopies(T, 0.0));
        this.R_squared = new ArrayList<>(Collections.nCopies(T, Double.NaN));

        List<Double> SST = new ArrayList<>(Collections.nCopies(T, 0.0));
        List<Double> means = new ArrayList<>(Collections.nCopies(T, 0.0));
        List<Integer> Nvalid = new ArrayList<>(Collections.nCopies(T, 0));

        nbr_of_matches = 0;
        nbr_of_false_negative = 0;
        nbr_of_false_positive = 0;
	

        /* -------------------------------------------------
           PASS 0: count false negatives and false positives
           ------------------------------------------------- */
        for (String key : accurate_rs_map.keySet()) {
            if (!approximate_rs_map.containsKey(key))
                nbr_of_false_negative++;
        }

        for (String key : approximate_rs_map.keySet()) {
            if (!accurate_rs_map.containsKey(key))
                nbr_of_false_positive++;
        }

        /* -------------------------------------------------
           PASS 1: compute means (accurate values only) 
           ------------------------------------------------- */
        for (String key : accurate_rs_map.keySet()) {

			// if false negative, ignore	
            if (!approximate_rs_map.containsKey(key))
                continue;

            List<Object> acc = accurate_rs_map.get(key);
            List<Object> app = approximate_rs_map.get(key);

            if (numerical_veracity) {
                for (int j = 0; j < T; j++) {
                    int col = list_of_target_columns.get(j);
                    Double v = extractValidNumber(acc.get(j));
                    Double w = extractValidNumber(app.get(j));
                    if (v == null || w == null) continue;

                    means.set(j, means.get(j) + v);
                    Nvalid.set(j, Nvalid.get(j) + 1);
                }
            } else { //means over lon and lat .....>NA
		Nvalid.set(0, Nvalid.get(0) + 1);
            }
        }

        for (int j = 0; j < T; j++) {
            if (Nvalid.get(j) > 0)
		means.set(j, means.get(j) / Nvalid.get(j)); 
        }

        /* -------------------------------------------------
           PASS 2: SSE + SST
           ------------------------------------------------- */
        for (String key : accurate_rs_map.keySet()) {
			// ignore false negative
            if (!approximate_rs_map.containsKey(key))
                continue;

            List<Object> acc = accurate_rs_map.get(key);
            List<Object> app = approximate_rs_map.get(key);

            nbr_of_matches++;

            if (numerical_veracity) {
                for (int j = 0; j < T; j++) {
                    int col = list_of_target_columns.get(j);

                    Double v = extractValidNumber(acc.get(j));
                    Double w = extractValidNumber(app.get(j));
                    if (v == null || w == null) continue;

                    double diff = v - w;
                    SSE.set(j, SSE.get(j) + diff * diff);

                    double dev = v - means.get(j);
                    SST.set(j, SST.get(j) + dev * dev);
                }
            } else { //veracity over spatial data : calculate spatial distance between 2 points
                Double d = spatialDistance(acc, app, list_of_target_columns);
                if (d == null) continue;
		SSE.set(0, SSE.get(0) + d * d);
		//SST NA
            }
        }

        /* -------------------------------------------------
           FINAL: RMSE and R^2
           ------------------------------------------------- */
        for (int j = 0; j < T; j++) {
            int n = Nvalid.get(j);
            if (n == 0) continue;

            RMSE.set(j, Math.sqrt(SSE.get(j) / n));
	    if (numerical_veracity) {
            	if (SST.get(j) > 0)	R_squared.set(j, 1.0 - (SSE.get(j) / SST.get(j)));
	    	else System.out.println("SST = 0, cannot calculate R^2.");
	    }	
	    // R^2 not defined when SST is 0
        }

	 /* -------------------------------------------------
           PRINT
           ------------------------------------------------- */
	    System.out.println("number of valid rows: " + Nvalid);
	    if (numerical_veracity) System.out.println("SST: " + SST); else System.out.println("SST NA spatial coordinates"); 
	    System.out.println("SSE: " + this.SSE);
	    System.out.println("RMSE: " + this.RMSE);
	    if (numerical_veracity) System.out.println("R^2: " + this.R_squared); else System.out.println("R_squared NA spatial coordinates"); 
	    System.out.println("Matches: " + this.nbr_of_matches);
	    System.out.println("False negatives: " + this.nbr_of_false_negative);
	    System.out.println("False positives: " + this.nbr_of_false_positive);
    }


    private static Double extractValidNumber(Object o) {
        if (o == null) return null;
        double v = ((Number) o).doubleValue();
        if (Double.isNaN(v) || v == MISSING) return null;
        return v;
    }

    private static Double spatialDistance(
            List<Object> acc,
            List<Object> app,
            List<Integer> cols) { 

        //int lonCol = cols.get(0);
        //int latCol = cols.get(1);
	int lonCol = 0;
        int latCol = 1;
        Double lon1 = extractValidNumber(acc.get(lonCol));
        Double lat1 = extractValidNumber(acc.get(latCol));
        Double lon2 = extractValidNumber(app.get(lonCol));
        Double lat2 = extractValidNumber(app.get(latCol));

        if (lon1 == null || lat1 == null || lon2 == null || lat2 == null)
            return null;

        return haversine(lat1, lon1, lat2, lon2);
    }

    private static double haversine(double lat1, double lon1,
                                    double lat2, double lon2) {

        //double R = 6371000.0; // result in meter
	double R = 6371.0 ; // result in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        lat1 = Math.toRadians(lat1);
        lat2 = Math.toRadians(lat2);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(lat1) * Math.cos(lat2)
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
