CREATE TABLE stops (
    stop_id TEXT PRIMARY KEY,
    stop_name TEXT,
    stop_lon REAL,
    stop_lat REAL,
	stop_types TEXT,
    stop_main_type TEXT,
    stop_address TEXT
);