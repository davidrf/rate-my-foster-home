DROP TABLE IF EXISTS forms, reviews, reviewers, user_homes, homes, users;

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username varchar(100) NOT NULL UNIQUE,
  password varchar(100) NOT NULL
);

CREATE TABLE homes (
  id SERIAL PRIMARY KEY,
  name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE user_homes (
  id SERIAL PRIMARY KEY,
  user_id integer NOT NULL REFERENCES users(id),
  home_id integer NOT NULL REFERENCES homes(id)
);

CREATE TABLE reviewers (
  id SERIAL PRIMARY KEY,
  name varchar(255) NOT NULL UNIQUE,
  type varchar(255) NOT NULL
);

CREATE TABLE reviews (
  id SERIAL PRIMARY KEY,
  review_date date NOT NULL,
  rating integer NOT NULL,
  comment text,
  ts timestamp DEFAULT CURRENT_TIMESTAMP,
  reviewer_id integer NOT NULL REFERENCES reviewers(id),
  home_id integer NOT NULL REFERENCES homes(id)
);

CREATE TABLE forms (
  id SERIAL PRIMARY KEY,
  name varchar(255),
  question text
);
