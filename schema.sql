CREATE TABLE lists (
	id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	name text NOT NULL UNIQUE
);

CREATE TABLE todos (
	id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	name text NOT NULL UNIQUE,
	completed boolean NOT NULL DEFAULT false,
	list_id integer NOT NULL REFERENCES lists(id)
);