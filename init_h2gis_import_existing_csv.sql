-- H2GIS schema + import from existing CSV files
-- Version: as close as practical to the original PostgreSQL/PostGIS TDWbench schema.
--
-- Important differences forced by H2/H2GIS:
-- 1) PostgreSQL casts like ::geometry are removed.
-- 2) PostGIS geometry columns are represented as H2GIS GEOMETRY.
-- 3) WKT geometry from CSV is loaded with ST_GeomFromText(..., 4326).
-- 4) PostgreSQL SERIAL / sequences are approximated with H2 SEQUENCE + DEFAULT NEXT VALUE.
-- 5) PostgreSQL GiST spatial indexes are approximated with H2GIS spatial indexes.
--
-- CSV assumptions:
-- 1) CSV files are in ./csv/ relative to Java working directory.
-- 2) CSV files have a header row with names matching the column names below.
-- 3) Geometry columns are WKT, for example POINT(...), POLYGON(...), MULTIPOLYGON(...).
-- 4) WKT geometries containing commas must be quoted in CSV.
-- 5) Empty cells are converted to NULL with NULLIF(..., '').

CREATE ALIAS IF NOT EXISTS H2GIS_SPATIAL FOR "org.h2gis.functions.factory.H2GISFunctions.load";
CALL H2GIS_SPATIAL();

-- =================
-- Drop old objects
-- =================

DROP TABLE IF EXISTS tripzones_polygons6;
DROP TABLE IF EXISTS tripzones_polygons5;
DROP TABLE IF EXISTS trippoints;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS dimvessel;
DROP TABLE IF EXISTS dimsport;
DROP TABLE IF EXISTS dimsmarine;
DROP TABLE IF EXISTS dimtime;
DROP TABLE IF EXISTS dimdate;

DROP SEQUENCE IF EXISTS dimdate_d_date_sk_seq;
DROP SEQUENCE IF EXISTS dimtime_ti_time_sk_seq;

-- =================
-- Sequences
-- =================

CREATE SEQUENCE dimdate_d_date_sk_seq START WITH 1827 INCREMENT BY 1;
CREATE SEQUENCE dimtime_ti_time_sk_seq START WITH 1 INCREMENT BY 1;

-- =================
-- Dimension tables
-- =================

CREATE TABLE dimdate (
                         d_date_sk INTEGER NOT NULL DEFAULT NEXT VALUE FOR dimdate_d_date_sk_seq,
                         d_date_value DATE,
                         d_date_desc VARCHAR(20),
                         d_calendar_year_id NUMERIC(4,0),
                         d_calendar_year_desc VARCHAR(20),
                         d_calendar_qtr_id NUMERIC(5,0),
                         d_calendar_qtr_desc VARCHAR(20),
                         d_calendar_month_id NUMERIC(6,0),
                         d_calendar_month_desc VARCHAR(20),
                         d_calendar_week_id NUMERIC(6,0),
                         d_calendar_week_desc VARCHAR(20),
                         d_day_of_week_num NUMERIC(1,0),
                         d_day_of_week_desc VARCHAR(10),
                         d_fiscal_year_id NUMERIC(4,0),
                         d_fiscal_year_desc VARCHAR(20),
                         d_fiscal_qtr_id NUMERIC(5,0),
                         d_fiscal_qtr_desc VARCHAR(20),
                         d_holiday_flag BOOLEAN,
                         CONSTRAINT dimdate_pkey PRIMARY KEY (d_date_sk)
);

CREATE TABLE dimtime (
                         ti_time_sk INTEGER NOT NULL DEFAULT NEXT VALUE FOR dimtime_ti_time_sk_seq,
                         ti_timevalue VARCHAR(12),
                         ti_hourid NUMERIC(2,0),
                         ti_hourdesc VARCHAR(20),
                         ti_minuteid NUMERIC(2,0),
                         ti_minutedesc VARCHAR(20),
                         ti_secondid NUMERIC(2,0),
                         ti_seconddesc VARCHAR(20),
                         ti_markethoursflag BOOLEAN,
                         ti_officehoursflag BOOLEAN,
                         CONSTRAINT dimtime_pkey PRIMARY KEY (ti_time_sk)
);

CREATE TABLE dimsmarine (
                            m_id INTEGER,
                            m_featureclass VARCHAR(20),
                            m_name VARCHAR(40),
                            m_geom GEOMETRY
);

CREATE TABLE dimsport (
                          p_id INTEGER,
                          p_region VARCHAR(60),
                          p_name VARCHAR(60),
                          p_country VARCHAR(60),
                          p_harbor_size VARCHAR(20),
                          p_geom GEOMETRY
);

CREATE TABLE dimvessel (
                           v_mmsi BIGINT NOT NULL,
                           v_imo VARCHAR,
                           v_name VARCHAR,
                           v_ship_type VARCHAR,
                           v_cargo_type VARCHAR,
                           v_width VARCHAR,
                           v_length VARCHAR,
                           v_size_a VARCHAR,
                           v_size_b VARCHAR,
                           v_size_c VARCHAR,
                           v_size_d VARCHAR,
                           v_callsign VARCHAR,
                           CONSTRAINT dimvessel_pkey PRIMARY KEY (v_mmsi)
);

-- =================
-- Fact tables
-- =================

CREATE TABLE trips (
                       t_trip_sk BIGINT,
                       t_departure_port INTEGER,
                       t_arrival_port INTEGER,
                       t_departure_date INTEGER,
                       t_arrival_date INTEGER,
                       t_arrival_time INTEGER,
                       t_departure_time INTEGER,
                       t_vessel BIGINT,
                       t_type_of_mobile VARCHAR(100),
                       t_type_of_pos_fix_device VARCHAR(100),
                       t_elapsed_time BIGINT,
                       t_draught_departure DOUBLE,
                       t_draught_arrival DOUBLE,
                       t_navig_status VARCHAR(100),
                       t_speed DOUBLE,
                       t_distance DOUBLE,
                       t_count_ais_events BIGINT,
                       t_departure_ts TIMESTAMP,
                       t_arrival_ts TIMESTAMP
);

CREATE TABLE trippoints (
                            tp_trip_sk BIGINT,
                            tp_point_offset INTEGER,
                            tp_date INTEGER,
                            tp_time INTEGER,
                            tp_geopoint GEOMETRY,
                            tp_cog DOUBLE,
                            tp_sog DOUBLE,
                            tp_heading DOUBLE
);

CREATE TABLE tripzones_polygons5 (
                                     tz_trip_sk BIGINT,
                                     tz_zone_number INTEGER,
                                     tz_entrance_date INTEGER,
                                     tz_quit_date INTEGER,
                                     tz_entrance_time INTEGER,
                                     tz_quit_time INTEGER,
                                     tz_elapsed_time BIGINT,
                                     tz_avg_cog DOUBLE,
                                     tz_avg_sog DOUBLE,
                                     tz_avg_heading DOUBLE,
                                     tz_count_ais_events DOUBLE,
                                     tz_zone_polygon GEOMETRY,
                                     tz_sum_sog DOUBLE,
                                     tz_count_nn_sog INTEGER,
                                     tz_sum_cog DOUBLE,
                                     tz_count_nn_cog INTEGER
);

CREATE TABLE tripzones_polygons6 (
                                     tz_trip_sk BIGINT,
                                     tz_zone_number INTEGER,
                                     tz_entrance_date INTEGER,
                                     tz_quit_date INTEGER,
                                     tz_entrance_time INTEGER,
                                     tz_quit_time INTEGER,
                                     tz_elapsed_time BIGINT,
                                     tz_avg_cog DOUBLE,
                                     tz_avg_sog DOUBLE,
                                     tz_avg_heading DOUBLE,
                                     tz_count_ais_events DOUBLE,
                                     tz_zone_polygon GEOMETRY,
                                     tz_sum_sog DOUBLE,
                                     tz_count_nn_sog INTEGER,
                                     tz_sum_cog DOUBLE,
                                     tz_count_nn_cog INTEGER
);

-- =======================
-- Import dimension tables
-- =======================

INSERT INTO dimdate (
    d_date_sk, d_date_value, d_date_desc, d_calendar_year_id, d_calendar_year_desc,
    d_calendar_qtr_id, d_calendar_qtr_desc, d_calendar_month_id, d_calendar_month_desc,
    d_calendar_week_id, d_calendar_week_desc, d_day_of_week_num, d_day_of_week_desc,
    d_fiscal_year_id, d_fiscal_year_desc, d_fiscal_qtr_id, d_fiscal_qtr_desc, d_holiday_flag
)
SELECT
    CAST(NULLIF(d_date_sk, '') AS INTEGER),
    CAST(NULLIF(d_date_value, '') AS DATE),
    NULLIF(d_date_desc, ''),
    CAST(NULLIF(d_calendar_year_id, '') AS NUMERIC(4,0)),
    NULLIF(d_calendar_year_desc, ''),
    CAST(NULLIF(d_calendar_qtr_id, '') AS NUMERIC(5,0)),
    NULLIF(d_calendar_qtr_desc, ''),
    CAST(NULLIF(d_calendar_month_id, '') AS NUMERIC(6,0)),
    NULLIF(d_calendar_month_desc, ''),
    CAST(NULLIF(d_calendar_week_id, '') AS NUMERIC(6,0)),
    NULLIF(d_calendar_week_desc, ''),
    CAST(NULLIF(d_day_of_week_num, '') AS NUMERIC(1,0)),
    NULLIF(d_day_of_week_desc, ''),
    CAST(NULLIF(d_fiscal_year_id, '') AS NUMERIC(4,0)),
    NULLIF(d_fiscal_year_desc, ''),
    CAST(NULLIF(d_fiscal_qtr_id, '') AS NUMERIC(5,0)),
    NULLIF(d_fiscal_qtr_desc, ''),
    CAST(NULLIF(d_holiday_flag, '') AS BOOLEAN)
FROM CSVREAD('./csv/dimdate.csv');

INSERT INTO dimtime (
    ti_time_sk, ti_timevalue, ti_hourid, ti_hourdesc, ti_minuteid, ti_minutedesc,
    ti_secondid, ti_seconddesc, ti_markethoursflag, ti_officehoursflag
)
SELECT
    CAST(NULLIF(ti_time_sk, '') AS INTEGER),
    NULLIF(ti_timevalue, ''),
    CAST(NULLIF(ti_hourid, '') AS NUMERIC(2,0)),
    NULLIF(ti_hourdesc, ''),
    CAST(NULLIF(ti_minuteid, '') AS NUMERIC(2,0)),
    NULLIF(ti_minutedesc, ''),
    CAST(NULLIF(ti_secondid, '') AS NUMERIC(2,0)),
    NULLIF(ti_seconddesc, ''),
    CAST(NULLIF(ti_markethoursflag, '') AS BOOLEAN),
    CAST(NULLIF(ti_officehoursflag, '') AS BOOLEAN)
FROM CSVREAD('./csv/dimtime.csv');

INSERT INTO dimsmarine (m_id, m_featureclass, m_name, m_geom)
SELECT
    CAST(NULLIF(m_id, '') AS INTEGER),
    NULLIF(m_featureclass, ''),
    NULLIF(m_name, ''),
    CASE WHEN NULLIF(m_geom, '') IS NULL THEN NULL ELSE ST_GeomFromText(m_geom, 4326) END
FROM CSVREAD('./csv/dimsmarine.csv');

INSERT INTO dimsport (p_id, p_region, p_name, p_country, p_harbor_size, p_geom)
SELECT
    CAST(NULLIF(p_id, '') AS INTEGER),
    NULLIF(p_region, ''),
    NULLIF(p_name, ''),
    NULLIF(p_country, ''),
    NULLIF(p_harbor_size, ''),
    CASE WHEN NULLIF(p_geom, '') IS NULL THEN NULL ELSE ST_GeomFromText(p_geom, 4326) END
FROM CSVREAD('./csv/dimsport.csv');

INSERT INTO dimvessel (
    v_mmsi, v_imo, v_name, v_ship_type, v_cargo_type, v_width, v_length,
    v_size_a, v_size_b, v_size_c, v_size_d, v_callsign
)
SELECT
    CAST(NULLIF(v_mmsi, '') AS BIGINT),
    NULLIF(v_imo, ''),
    NULLIF(v_name, ''),
    NULLIF(v_ship_type, ''),
    NULLIF(v_cargo_type, ''),
    NULLIF(v_width, ''),
    NULLIF(v_length, ''),
    NULLIF(v_size_a, ''),
    NULLIF(v_size_b, ''),
    NULLIF(v_size_c, ''),
    NULLIF(v_size_d, ''),
    NULLIF(v_callsign, '')
FROM CSVREAD('./csv/dimvessel.csv');

-- ==================
-- Import fact tables
-- ==================

INSERT INTO trips (
    t_trip_sk, t_departure_port, t_arrival_port, t_departure_date, t_arrival_date,
    t_arrival_time, t_departure_time, t_vessel, t_type_of_mobile, t_type_of_pos_fix_device,
    t_elapsed_time, t_draught_departure, t_draught_arrival, t_navig_status, t_speed,
    t_distance, t_count_ais_events, t_departure_ts, t_arrival_ts
)
SELECT
    CAST(NULLIF(t_trip_sk, '') AS BIGINT),
    CAST(NULLIF(t_departure_port, '') AS INTEGER),
    CAST(NULLIF(t_arrival_port, '') AS INTEGER),
    CAST(NULLIF(t_departure_date, '') AS INTEGER),
    CAST(NULLIF(t_arrival_date, '') AS INTEGER),
    CAST(NULLIF(t_arrival_time, '') AS INTEGER),
    CAST(NULLIF(t_departure_time, '') AS INTEGER),
    CAST(NULLIF(t_vessel, '') AS BIGINT),
    NULLIF(t_type_of_mobile, ''),
    NULLIF(t_type_of_pos_fix_device, ''),
    CAST(NULLIF(t_elapsed_time, '') AS BIGINT),
    CAST(NULLIF(t_draught_departure, '') AS DOUBLE),
    CAST(NULLIF(t_draught_arrival, '') AS DOUBLE),
    NULLIF(t_navig_status, ''),
    CAST(NULLIF(t_speed, '') AS DOUBLE),
    CAST(NULLIF(t_distance, '') AS DOUBLE),
    CAST(NULLIF(t_count_ais_events, '') AS BIGINT),
    CAST(NULLIF(t_departure_ts, '') AS TIMESTAMP),
    CAST(NULLIF(t_arrival_ts, '') AS TIMESTAMP)
FROM CSVREAD('./csv/trips.csv');

INSERT INTO trippoints (
    tp_trip_sk, tp_point_offset, tp_date, tp_time, tp_geopoint, tp_cog, tp_sog, tp_heading
)
SELECT
    CAST(NULLIF(tp_trip_sk, '') AS BIGINT),
    CAST(NULLIF(tp_point_offset, '') AS INTEGER),
    CAST(NULLIF(tp_date, '') AS INTEGER),
    CAST(NULLIF(tp_time, '') AS INTEGER),
    CASE WHEN NULLIF(tp_geopoint, '') IS NULL THEN NULL ELSE ST_GeomFromText(tp_geopoint, 4326) END,
    CAST(NULLIF(tp_cog, '') AS DOUBLE),
    CAST(NULLIF(tp_sog, '') AS DOUBLE),
    CAST(NULLIF(tp_heading, '') AS DOUBLE)
FROM CSVREAD('./csv/trippoints.csv');

INSERT INTO tripzones_polygons5 (
    tz_trip_sk, tz_zone_number, tz_entrance_date, tz_quit_date, tz_entrance_time, tz_quit_time,
    tz_elapsed_time, tz_avg_cog, tz_avg_sog, tz_avg_heading, tz_count_ais_events,
    tz_zone_polygon, tz_sum_sog, tz_count_nn_sog, tz_sum_cog, tz_count_nn_cog
)
SELECT
    CAST(NULLIF(tz_trip_sk, '') AS BIGINT),
    CAST(NULLIF(tz_zone_number, '') AS INTEGER),
    CAST(NULLIF(tz_entrance_date, '') AS INTEGER),
    CAST(NULLIF(tz_quit_date, '') AS INTEGER),
    CAST(NULLIF(tz_entrance_time, '') AS INTEGER),
    CAST(NULLIF(tz_quit_time, '') AS INTEGER),
    CAST(NULLIF(tz_elapsed_time, '') AS BIGINT),
    CAST(NULLIF(tz_avg_cog, '') AS DOUBLE),
    CAST(NULLIF(tz_avg_sog, '') AS DOUBLE),
    CAST(NULLIF(tz_avg_heading, '') AS DOUBLE),
    CAST(NULLIF(tz_count_ais_events, '') AS DOUBLE),
    CASE WHEN NULLIF(tz_zone_polygon, '') IS NULL THEN NULL ELSE ST_GeomFromText(tz_zone_polygon, 4326) END,
    CAST(NULLIF(tz_sum_sog, '') AS DOUBLE),
    CAST(NULLIF(tz_count_nn_sog, '') AS INTEGER),
    CAST(NULLIF(tz_sum_cog, '') AS DOUBLE),
    CAST(NULLIF(tz_count_nn_cog, '') AS INTEGER)
FROM CSVREAD('./csv/tripzones_polygons5.csv');

INSERT INTO tripzones_polygons6 (
    tz_trip_sk, tz_zone_number, tz_entrance_date, tz_quit_date, tz_entrance_time, tz_quit_time,
    tz_elapsed_time, tz_avg_cog, tz_avg_sog, tz_avg_heading, tz_count_ais_events,
    tz_zone_polygon, tz_sum_sog, tz_count_nn_sog, tz_sum_cog, tz_count_nn_cog
)
SELECT
    CAST(NULLIF(tz_trip_sk, '') AS BIGINT),
    CAST(NULLIF(tz_zone_number, '') AS INTEGER),
    CAST(NULLIF(tz_entrance_date, '') AS INTEGER),
    CAST(NULLIF(tz_quit_date, '') AS INTEGER),
    CAST(NULLIF(tz_entrance_time, '') AS INTEGER),
    CAST(NULLIF(tz_quit_time, '') AS INTEGER),
    CAST(NULLIF(tz_elapsed_time, '') AS BIGINT),
    CAST(NULLIF(tz_avg_cog, '') AS DOUBLE),
    CAST(NULLIF(tz_avg_sog, '') AS DOUBLE),
    CAST(NULLIF(tz_avg_heading, '') AS DOUBLE),
    CAST(NULLIF(tz_count_ais_events, '') AS DOUBLE),
    CASE WHEN NULLIF(tz_zone_polygon, '') IS NULL THEN NULL ELSE ST_GeomFromText(tz_zone_polygon, 4326) END,
    CAST(NULLIF(tz_sum_sog, '') AS DOUBLE),
    CAST(NULLIF(tz_count_nn_sog, '') AS INTEGER),
    CAST(NULLIF(tz_sum_cog, '') AS DOUBLE),
    CAST(NULLIF(tz_count_nn_cog, '') AS INTEGER)
FROM CSVREAD('./csv/tripzones_polygons6.csv');

-- ==============================
-- Indexes matching the PostgreSQL dump
-- ==============================
-- Spatial indexes correspond to the PostGIS GiST indexes in dump.sql.

CREATE SPATIAL INDEX dimmarine_rtree_idx ON dimsmarine(m_geom);
CREATE SPATIAL INDEX trippoints_rtree_idx ON trippoints(tp_geopoint);
CREATE SPATIAL INDEX tripzones_rtree_idx5 ON tripzones_polygons5(tz_zone_polygon);
CREATE SPATIAL INDEX tripzones_rtree_idx6 ON tripzones_polygons6(tz_zone_polygon);

-- ==============================
-- Optional row-count check
-- ==============================

SELECT 'dimdate' AS table_name, COUNT(*) AS rows_count FROM dimdate;
SELECT 'dimtime' AS table_name, COUNT(*) AS rows_count FROM dimtime;
SELECT 'dimsmarine' AS table_name, COUNT(*) AS rows_count FROM dimsmarine;
SELECT 'dimsport' AS table_name, COUNT(*) AS rows_count FROM dimsport;
SELECT 'dimvessel' AS table_name, COUNT(*) AS rows_count FROM dimvessel;
SELECT 'trips' AS table_name, COUNT(*) AS rows_count FROM trips;
SELECT 'trippoints' AS table_name, COUNT(*) AS rows_count FROM trippoints;
SELECT 'tripzones_polygons5' AS table_name, COUNT(*) AS rows_count FROM tripzones_polygons5;
SELECT 'tripzones_polygons6' AS table_name, COUNT(*) AS rows_count FROM tripzones_polygons6;
