-- ============================================================
-- add_h2gis_indexes.sql
-- Run this if the H2GIS database already exists and you do not want to reimport CSV files.
-- It only adds extra benchmark indexes and refreshes statistics.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_trippoints_trip_offset
ON trippoints(tp_trip_sk, tp_point_offset);

CREATE INDEX IF NOT EXISTS idx_trippoints_time_trip
ON trippoints(tp_time, tp_trip_sk);

CREATE INDEX IF NOT EXISTS idx_trippoints_date_time
ON trippoints(tp_date, tp_time);

CREATE INDEX IF NOT EXISTS idx_trips_departure_port
ON trips(t_departure_port);

CREATE INDEX IF NOT EXISTS idx_trips_arrival_port
ON trips(t_arrival_port);

CREATE INDEX IF NOT EXISTS idx_trips_departure_arrival
ON trips(t_departure_port, t_arrival_port);

CREATE INDEX IF NOT EXISTS idx_dimsport_id
ON dimsport(p_id);

CREATE INDEX IF NOT EXISTS idx_tripzones5_trip_zone
ON tripzones_polygons5(tz_trip_sk, tz_zone_number);

CREATE INDEX IF NOT EXISTS idx_tripzones6_trip_zone
ON tripzones_polygons6(tz_trip_sk, tz_zone_number);

CREATE INDEX IF NOT EXISTS idx_tripzones5_time_trip_zone
ON tripzones_polygons5(tz_entrance_time, tz_quit_time, tz_trip_sk, tz_zone_number);

CREATE INDEX IF NOT EXISTS idx_tripzones6_time_trip_zone
ON tripzones_polygons6(tz_entrance_time, tz_quit_time, tz_trip_sk, tz_zone_number);

ANALYZE;
CHECKPOINT;
