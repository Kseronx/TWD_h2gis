-- ============================================================
-- init_h2gis.sql
-- H2GIS initialization script for TDW benchmark
-- PostgreSQL/PostGIS dump equivalent adapted for H2GIS
--
-- Purpose:
-- 1. Create H2GIS-compatible schema
-- 2. Import CSV data exported from PostgreSQL/PostGIS
-- 3. Convert WKT geometry columns to H2GIS GEOMETRY
-- 4. Create spatial and analytical indexes
-- 5. Analyze and checkpoint database
--
-- Expected CSV directory structure, relative to project root:
-- ./csv/trippoints.csv
-- ./csv/tripzones_polygons5.csv
-- ./csv/tripzones_polygons6.csv
-- ./csv/dimdate.csv
-- ./csv/dimsmarine.csv
-- ./csv/dimsport.csv
-- ./csv/dimtime.csv
-- ./csv/dimvessel.csv
-- ./csv/trips.csv
--
-- Geometry columns in CSV must be exported as WKT, for example:
-- POINT(11.128125 57.321205)
-- POLYGON((...))
-- ============================================================

-- ============================================================
-- Clean old benchmark tables if database already exists
-- ============================================================

DROP TABLE IF EXISTS trippoints;
DROP TABLE IF EXISTS tripzones_polygons5;
DROP TABLE IF EXISTS tripzones_polygons6;
DROP TABLE IF EXISTS dimdate;
DROP TABLE IF EXISTS dimsmarine;
DROP TABLE IF EXISTS dimsport;
DROP TABLE IF EXISTS dimtime;
DROP TABLE IF EXISTS dimvessel;
DROP TABLE IF EXISTS trips;

-- ============================================================
-- Create benchmark tables
-- ============================================================

CREATE TABLE trippoints (
    tp_trip_sk BIGINT,
    tp_point_offset INT,
    tp_date INT,
    tp_time INT,
    tp_geopoint GEOMETRY(POINT, 4326),
    tp_cog DOUBLE,
    tp_sog DOUBLE,
    tp_heading DOUBLE
);

CREATE TABLE tripzones_polygons5 (
    tz_trip_sk BIGINT,
    tz_zone_number INT,
    tz_entrance_date INT,
    tz_quit_date INT,
    tz_entrance_time INT,
    tz_quit_time INT,
    tz_elapsed_time BIGINT,
    tz_avg_cog DOUBLE,
    tz_avg_sog DOUBLE,
    tz_avg_heading DOUBLE,
    tz_count_ais_events DOUBLE,
    tz_zone_polygon GEOMETRY(GEOMETRY, 4326),
    tz_sum_sog DOUBLE,
    tz_count_nn_sog INT,
    tz_sum_cog DOUBLE,
    tz_count_nn_cog INT
);

CREATE TABLE tripzones_polygons6 (
    tz_trip_sk BIGINT,
    tz_zone_number INT,
    tz_entrance_date INT,
    tz_quit_date INT,
    tz_entrance_time INT,
    tz_quit_time INT,
    tz_elapsed_time BIGINT,
    tz_avg_cog DOUBLE,
    tz_avg_sog DOUBLE,
    tz_avg_heading DOUBLE,
    tz_count_ais_events DOUBLE,
    tz_zone_polygon GEOMETRY(GEOMETRY, 4326),
    tz_sum_sog DOUBLE,
    tz_count_nn_sog INT,
    tz_sum_cog DOUBLE,
    tz_count_nn_cog INT
);

CREATE TABLE dimdate (
    d_date_sk INT NOT NULL,
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
    d_holiday_flag BOOLEAN
);

CREATE TABLE dimsmarine (
    m_id INT,
    m_featureclass VARCHAR(20),
    m_name VARCHAR(40),
    m_geom GEOMETRY(GEOMETRY, 4326)
);

CREATE TABLE dimsport (
    p_id INT,
    p_region VARCHAR(60),
    p_name VARCHAR(60),
    p_country VARCHAR(60),
    p_harbor_size VARCHAR(20),
    p_geom GEOMETRY(GEOMETRY, 4326)
);

CREATE TABLE dimtime (
    ti_time_sk INT NOT NULL,
    ti_timevalue VARCHAR(12),
    ti_hourid NUMERIC(2,0),
    ti_hourdesc VARCHAR(20),
    ti_minuteid NUMERIC(2,0),
    ti_minutedesc VARCHAR(20),
    ti_secondid NUMERIC(2,0),
    ti_seconddesc VARCHAR(20),
    ti_markethoursflag BOOLEAN,
    ti_officehoursflag BOOLEAN
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
    v_callsign VARCHAR
);

CREATE TABLE trips (
    t_trip_sk BIGINT,
    t_departure_port INT,
    t_arrival_port INT,
    t_departure_date INT,
    t_arrival_date INT,
    t_arrival_time INT,
    t_departure_time INT,
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

-- ============================================================
-- Primary keys equivalent to PostgreSQL dump constraints
-- ============================================================

ALTER TABLE dimdate ADD CONSTRAINT dimdate_pkey PRIMARY KEY (d_date_sk);
ALTER TABLE dimtime ADD CONSTRAINT dimtime_pkey PRIMARY KEY (ti_time_sk);
ALTER TABLE dimvessel ADD CONSTRAINT dimvessel_pkey PRIMARY KEY (v_mmsi);

-- ============================================================
-- Import data from CSV files
--
-- Important:
-- CSVREAD reads all columns as strings first, so values are inserted
-- through explicit SELECT mapping. Geometry WKT is converted using
-- ST_GeomFromText(..., 4326).
-- ============================================================

INSERT INTO trippoints
SELECT
    CAST(tp_trip_sk AS BIGINT),
    CAST(tp_point_offset AS INT),
    CAST(tp_date AS INT),
    CAST(tp_time AS INT),
    ST_GeomFromText(tp_geopoint, 4326),
    CAST(tp_cog AS DOUBLE),
    CAST(tp_sog AS DOUBLE),
    CAST(tp_heading AS DOUBLE)
FROM CSVREAD('./csv/trippoints.csv');

INSERT INTO tripzones_polygons5
SELECT
    CAST(tz_trip_sk AS BIGINT),
    CAST(tz_zone_number AS INT),
    CAST(tz_entrance_date AS INT),
    CAST(tz_quit_date AS INT),
    CAST(tz_entrance_time AS INT),
    CAST(tz_quit_time AS INT),
    CAST(tz_elapsed_time AS BIGINT),
    CAST(tz_avg_cog AS DOUBLE),
    CAST(tz_avg_sog AS DOUBLE),
    CAST(tz_avg_heading AS DOUBLE),
    CAST(tz_count_ais_events AS DOUBLE),
    ST_GeomFromText(tz_zone_polygon, 4326),
    CAST(tz_sum_sog AS DOUBLE),
    CAST(tz_count_nn_sog AS INT),
    CAST(tz_sum_cog AS DOUBLE),
    CAST(tz_count_nn_cog AS INT)
FROM CSVREAD('./csv/tripzones_polygons5.csv');

INSERT INTO tripzones_polygons6
SELECT
    CAST(tz_trip_sk AS BIGINT),
    CAST(tz_zone_number AS INT),
    CAST(tz_entrance_date AS INT),
    CAST(tz_quit_date AS INT),
    CAST(tz_entrance_time AS INT),
    CAST(tz_quit_time AS INT),
    CAST(tz_elapsed_time AS BIGINT),
    CAST(tz_avg_cog AS DOUBLE),
    CAST(tz_avg_sog AS DOUBLE),
    CAST(tz_avg_heading AS DOUBLE),
    CAST(tz_count_ais_events AS DOUBLE),
    ST_GeomFromText(tz_zone_polygon, 4326),
    CAST(tz_sum_sog AS DOUBLE),
    CAST(tz_count_nn_sog AS INT),
    CAST(tz_sum_cog AS DOUBLE),
    CAST(tz_count_nn_cog AS INT)
FROM CSVREAD('./csv/tripzones_polygons6.csv');

INSERT INTO dimdate
SELECT
    CAST(d_date_sk AS INT),
    CAST(d_date_value AS DATE),
    d_date_desc,
    CAST(d_calendar_year_id AS NUMERIC(4,0)),
    d_calendar_year_desc,
    CAST(d_calendar_qtr_id AS NUMERIC(5,0)),
    d_calendar_qtr_desc,
    CAST(d_calendar_month_id AS NUMERIC(6,0)),
    d_calendar_month_desc,
    CAST(d_calendar_week_id AS NUMERIC(6,0)),
    d_calendar_week_desc,
    CAST(d_day_of_week_num AS NUMERIC(1,0)),
    d_day_of_week_desc,
    CAST(d_fiscal_year_id AS NUMERIC(4,0)),
    d_fiscal_year_desc,
    CAST(d_fiscal_qtr_id AS NUMERIC(5,0)),
    d_fiscal_qtr_desc,
    CAST(d_holiday_flag AS BOOLEAN)
FROM CSVREAD('./csv/dimdate.csv');

INSERT INTO dimsmarine
SELECT
    CAST(m_id AS INT),
    m_featureclass,
    m_name,
    ST_GeomFromText(m_geom, 4326)
FROM CSVREAD('./csv/dimsmarine.csv');

INSERT INTO dimsport
SELECT
    CAST(p_id AS INT),
    p_region,
    p_name,
    p_country,
    p_harbor_size,
    ST_GeomFromText(p_geom, 4326)
FROM CSVREAD('./csv/dimsport.csv');

INSERT INTO dimtime
SELECT
    CAST(ti_time_sk AS INT),
    ti_timevalue,
    CAST(ti_hourid AS NUMERIC(2,0)),
    ti_hourdesc,
    CAST(ti_minuteid AS NUMERIC(2,0)),
    ti_minutedesc,
    CAST(ti_secondid AS NUMERIC(2,0)),
    ti_seconddesc,
    CAST(ti_markethoursflag AS BOOLEAN),
    CAST(ti_officehoursflag AS BOOLEAN)
FROM CSVREAD('./csv/dimtime.csv');

INSERT INTO dimvessel
SELECT
    CAST(v_mmsi AS BIGINT),
    v_imo,
    v_name,
    v_ship_type,
    v_cargo_type,
    v_width,
    v_length,
    v_size_a,
    v_size_b,
    v_size_c,
    v_size_d,
    v_callsign
FROM CSVREAD('./csv/dimvessel.csv');

INSERT INTO trips
SELECT
    CAST(t_trip_sk AS BIGINT),
    CAST(t_departure_port AS INT),
    CAST(t_arrival_port AS INT),
    CAST(t_departure_date AS INT),
    CAST(t_arrival_date AS INT),
    CAST(t_arrival_time AS INT),
    CAST(t_departure_time AS INT),
    CAST(t_vessel AS BIGINT),
    t_type_of_mobile,
    t_type_of_pos_fix_device,
    CAST(t_elapsed_time AS BIGINT),
    CAST(t_draught_departure AS DOUBLE),
    CAST(t_draught_arrival AS DOUBLE),
    t_navig_status,
    CAST(t_speed AS DOUBLE),
    CAST(t_distance AS DOUBLE),
    CAST(t_count_ais_events AS BIGINT),
    CAST(t_departure_ts AS TIMESTAMP),
    CAST(t_arrival_ts AS TIMESTAMP)
FROM CSVREAD('./csv/trips.csv');

-- ============================================================
-- Spatial indexes: H2GIS equivalent of PostGIS GiST indexes
-- ============================================================

CREATE SPATIAL INDEX dimmarine_rtree_idx
ON dimsmarine(m_geom);

CREATE SPATIAL INDEX trippoints_rtree_idx
ON trippoints(tp_geopoint);

CREATE SPATIAL INDEX tripzones_rtree_idx5
ON tripzones_polygons5(tz_zone_polygon);

CREATE SPATIAL INDEX tripzones_rtree_idx6
ON tripzones_polygons6(tz_zone_polygon);

-- PostgreSQL dump did not define this index, but it is useful if queries use ports spatially.
-- Keep it only if you want a richer H2GIS spatial setup.
CREATE SPATIAL INDEX dimsport_rtree_idx
ON dimsport(p_geom);

-- ============================================================
-- Additional analytical indexes useful for benchmark joins/filters
-- These did not exist in the original dump, so if you want the closest
-- possible PostgreSQL equivalence, comment this whole section out.
-- ============================================================

--CREATE INDEX idx_trippoints_trip
--ON trippoints(tp_trip_sk);

--CREATE INDEX idx_trippoints_time
--ON trippoints(tp_time);

--CREATE INDEX idx_trippoints_date
--ON trippoints(tp_date);

--CREATE INDEX idx_trips_trip
--ON trips(t_trip_sk);

--CREATE INDEX idx_trips_vessel
--ON trips(t_vessel);

--CREATE INDEX idx_trips_departure_port
--ON trips(t_departure_port);

--CREATE INDEX idx_trips_arrival_port
--ON trips(t_arrival_port);

--CREATE INDEX idx_tripzones5_trip
--ON tripzones_polygons5(tz_trip_sk);

--CREATE INDEX idx_tripzones6_trip
--ON tripzones_polygons6(tz_trip_sk);


CREATE INDEX IF NOT EXISTS idx_trippoints_trip_sk ON trippoints(tp_trip_sk);
CREATE INDEX IF NOT EXISTS idx_trippoints_time ON trippoints(tp_time);
CREATE INDEX IF NOT EXISTS idx_trips_trip_sk ON trips(t_trip_sk);
CREATE INDEX IF NOT EXISTS idx_trips_vessel ON trips(t_vessel);
CREATE INDEX IF NOT EXISTS idx_dimvessel_mmsi ON dimvessel(v_mmsi);

CREATE INDEX IF NOT EXISTS idx_tripzones5_trip_sk ON tripzones_polygons5(tz_trip_sk);
CREATE INDEX IF NOT EXISTS idx_tripzones6_trip_sk ON tripzones_polygons6(tz_trip_sk);
CREATE INDEX IF NOT EXISTS idx_tripzones5_time ON tripzones_polygons5(tz_entrance_time, tz_quit_time);
CREATE INDEX IF NOT EXISTS idx_tripzones6_time ON tripzones_polygons6(tz_entrance_time, tz_quit_time);

-- ============================================================
-- Extra H2GIS benchmark indexes
-- Added for H2GIS optimizer and heavy TDW self-joins.
-- These are regular relational indexes, not spatial indexes.
-- They are intentionally portable: DuckDB can get analogous btree-style
-- indexes or rely on its columnar scans for the same join/filter columns.
-- ============================================================

-- Point schema: joins Trips <-> TripPoints and ordered first-point queries
CREATE INDEX IF NOT EXISTS idx_trippoints_trip_offset
ON trippoints(tp_trip_sk, tp_point_offset);

CREATE INDEX IF NOT EXISTS idx_trippoints_time_trip
ON trippoints(tp_time, tp_trip_sk);

CREATE INDEX IF NOT EXISTS idx_trippoints_date_time
ON trippoints(tp_date, tp_time);

-- Trips and ports
CREATE INDEX IF NOT EXISTS idx_trips_departure_port
ON trips(t_departure_port);

CREATE INDEX IF NOT EXISTS idx_trips_arrival_port
ON trips(t_arrival_port);

CREATE INDEX IF NOT EXISTS idx_trips_departure_arrival
ON trips(t_departure_port, t_arrival_port);

CREATE INDEX IF NOT EXISTS idx_dimsport_id
ON dimsport(p_id);

-- Shape schemas: very important for tz1/tz2 self-joins such as
-- tz1.tz_trip_sk = tz2.tz_trip_sk AND tz2.tz_zone_number = tz1.tz_zone_number + 1/2
CREATE INDEX IF NOT EXISTS idx_tripzones5_trip_zone
ON tripzones_polygons5(tz_trip_sk, tz_zone_number);

CREATE INDEX IF NOT EXISTS idx_tripzones6_trip_zone
ON tripzones_polygons6(tz_trip_sk, tz_zone_number);

CREATE INDEX IF NOT EXISTS idx_tripzones5_time_trip_zone
ON tripzones_polygons5(tz_entrance_time, tz_quit_time, tz_trip_sk, tz_zone_number);

CREATE INDEX IF NOT EXISTS idx_tripzones6_time_trip_zone
ON tripzones_polygons6(tz_entrance_time, tz_quit_time, tz_trip_sk, tz_zone_number);

-- ============================================================
-- Optimizer statistics and disk flush
-- ============================================================

ANALYZE;
CHECKPOINT;
