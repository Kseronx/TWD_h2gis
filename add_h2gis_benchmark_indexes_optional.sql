-- =====================================================================
-- add_h2gis_benchmark_indexes_optional.sql
-- Optional indexes for benchmark speed.
-- These are NOT present in the provided PostgreSQL dump, so do not use them
-- if you want the strictest schema equivalence. Use them only if you also
-- create comparable indexes in PostgreSQL/DuckDB or clearly describe this
-- as an optimized setup.
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_trippoints_trip_sk ON trippoints(tp_trip_sk);
CREATE INDEX IF NOT EXISTS idx_trippoints_time ON trippoints(tp_time);
CREATE INDEX IF NOT EXISTS idx_trippoints_trip_offset ON trippoints(tp_trip_sk, tp_point_offset);
CREATE INDEX IF NOT EXISTS idx_trippoints_offset_trip ON trippoints(tp_point_offset, tp_trip_sk);

CREATE INDEX IF NOT EXISTS idx_trips_trip_sk ON trips(t_trip_sk);
CREATE INDEX IF NOT EXISTS idx_trips_vessel ON trips(t_vessel);
CREATE INDEX IF NOT EXISTS idx_trips_departure_port ON trips(t_departure_port);
CREATE INDEX IF NOT EXISTS idx_trips_arrival_port ON trips(t_arrival_port);

CREATE INDEX IF NOT EXISTS idx_dimsport_id ON dimsport(p_id);
CREATE INDEX IF NOT EXISTS idx_dimvessel_mmsi ON dimvessel(v_mmsi);

CREATE INDEX IF NOT EXISTS idx_tripzones5_trip_sk ON tripzones_polygons5(tz_trip_sk);
CREATE INDEX IF NOT EXISTS idx_tripzones5_trip_zone ON tripzones_polygons5(tz_trip_sk, tz_zone_number);
CREATE INDEX IF NOT EXISTS idx_tripzones5_time ON tripzones_polygons5(tz_entrance_time, tz_quit_time);

CREATE INDEX IF NOT EXISTS idx_tripzones6_trip_sk ON tripzones_polygons6(tz_trip_sk);
CREATE INDEX IF NOT EXISTS idx_tripzones6_trip_zone ON tripzones_polygons6(tz_trip_sk, tz_zone_number);
CREATE INDEX IF NOT EXISTS idx_tripzones6_time ON tripzones_polygons6(tz_entrance_time, tz_quit_time);

ANALYZE;
CHECKPOINT;
