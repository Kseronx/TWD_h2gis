-- =========================================
-- H2GIS benchmark schema initialization
-- PostgreSQL/PostGIS equivalent
-- =========================================

-- =========================================
-- CREATE TABLES
-- =========================================

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
    tz_zone_polygon GEOMETRY(POLYGON, 4326),
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
    tz_zone_polygon GEOMETRY(POLYGON, 4326),
    tz_sum_sog DOUBLE,
    tz_count_nn_sog INT,
    tz_sum_cog DOUBLE,
    tz_count_nn_cog INT
);

CREATE TABLE dimdate (
    d_date_sk INT PRIMARY KEY,
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
    m_geom GEOMETRY
);

CREATE TABLE dimsport (
    p_id INT,
    p_region VARCHAR(60),
    p_name VARCHAR(60),
    p_country VARCHAR(60),
    p_harbor_size VARCHAR(20),
    p_geom GEOMETRY(POINT, 4326)
);

CREATE TABLE dimtime (
    ti_time_sk INT PRIMARY KEY,
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
    v_mmsi BIGINT PRIMARY KEY,
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

-- =========================================
-- IMPORT DATA FROM CSV
-- Adjust paths if needed
-- =========================================

INSERT INTO trippoints
SELECT
    tp_trip_sk,
    tp_point_offset,
    tp_date,
    tp_time,
    ST_GeomFromText(tp_geopoint, 4326),
    tp_cog,
    tp_sog,
    tp_heading
FROM CSVREAD('./csv/trippoints.csv');

INSERT INTO tripzones_polygons5
SELECT
    tz_trip_sk,
    tz_zone_number,
    tz_entrance_date,
    tz_quit_date,
    tz_entrance_time,
    tz_quit_time,
    tz_elapsed_time,
    tz_avg_cog,
    tz_avg_sog,
    tz_avg_heading,
    tz_count_ais_events,
    ST_GeomFromText(tz_zone_polygon, 4326),
    tz_sum_sog,
    tz_count_nn_sog,
    tz_sum_cog,
    tz_count_nn_cog
FROM CSVREAD('./csv/tripzones_polygons5.csv');

INSERT INTO tripzones_polygons6
SELECT
    tz_trip_sk,
    tz_zone_number,
    tz_entrance_date,
    tz_quit_date,
    tz_entrance_time,
    tz_quit_time,
    tz_elapsed_time,
    tz_avg_cog,
    tz_avg_sog,
    tz_avg_heading,
    tz_count_ais_events,
    ST_GeomFromText(tz_zone_polygon, 4326),
    tz_sum_sog,
    tz_count_nn_sog,
    tz_sum_cog,
    tz_count_nn_cog
FROM CSVREAD('./csv/tripzones_polygons6.csv');

INSERT INTO dimdate
SELECT * FROM CSVREAD('./csv/dimdate.csv');

INSERT INTO dimsmarine
SELECT
    m_id,
    m_featureclass,
    m_name,
    ST_GeomFromText(m_geom, 4326)
FROM CSVREAD('./csv/dimsmarine.csv');

INSERT INTO dimsport
SELECT
    p_id,
    p_region,
    p_name,
    p_country,
    p_harbor_size,
    ST_GeomFromText(p_geom, 4326)
FROM CSVREAD('./csv/dimsport.csv');

INSERT INTO dimtime
SELECT * FROM CSVREAD('./csv/dimtime.csv');

INSERT INTO dimvessel
SELECT * FROM CSVREAD('./csv/dimvessel.csv');

INSERT INTO trips
SELECT * FROM CSVREAD('./csv/trips.csv');

-- =========================================
-- SPATIAL INDEXES
-- =========================================

CREATE SPATIAL INDEX trippoints_rtree_idx
ON trippoints(tp_geopoint);

CREATE SPATIAL INDEX tripzones_rtree_idx5
ON tripzones_polygons5(tz_zone_polygon);

CREATE SPATIAL INDEX tripzones_rtree_idx6
ON tripzones_polygons6(tz_zone_polygon);

CREATE SPATIAL INDEX dimmarine_rtree_idx
ON dimsmarine(m_geom);

CREATE SPATIAL INDEX dimsport_rtree_idx
ON dimsport(p_geom);

-- =========================================
-- B-TREE INDEXES
-- =========================================

CREATE INDEX idx_trips_vessel
ON trips(t_vessel);

CREATE INDEX idx_trips_departure_date
ON trips(t_departure_date);

CREATE INDEX idx_trippoints_trip
ON trippoints(tp_trip_sk);

CREATE INDEX idx_trippoints_date
ON trippoints(tp_date);

CREATE INDEX idx_trippoints_time
ON trippoints(tp_time);

CREATE INDEX idx_tripzones5_trip
ON tripzones_polygons5(tz_trip_sk);

CREATE INDEX idx_tripzones6_trip
ON tripzones_polygons6(tz_trip_sk);

-- =========================================
-- UPDATE STATISTICS
-- =========================================

ANALYZE;

-- =========================================
-- FLUSH DATABASE TO DISK
-- =========================================

CHECKPOINT;