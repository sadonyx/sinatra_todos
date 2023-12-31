CREATE TABLE lists (
	id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	name text NOT NULL UNIQUE,
  all_completed boolean NOT NULL DEFAULT false
);

CREATE TABLE todos (
	id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	name text NOT NULL UNIQUE,
	completed boolean NOT NULL DEFAULT false,
	list_id integer NOT NULL REFERENCES lists(id) ON DELETE CASCADE
);