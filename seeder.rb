require 'pg'
require 'pry'
require 'faker'
require 'date'

DATABASE = "foster_homes"

def db_connection
  begin
    connection = PG.connect(dbname: DATABASE)
    yield(connection)
  ensure
    connection.close
  end
end

def add_questions
  youth_question = "On a scale of 0-10, where 0 is not likely and 10 is extremely likely how likely are you to recommend your foster home to a friend in the foster care system?"
  parent_question = "On a scale of 0-10, where 0 is not likely and 10 is extremely likely, how likely are you to recommend this foster home to another foster parent?"
  worker_question = "On a scale of 0-10, where 0 is not likely and 10 is extremely likely, how likely are you to recommend this foster home?"

  questions = { "youth" => youth_question, "parent" => parent_question, "worker" => worker_question }
  sql_query = "INSERT INTO questions (person, question) VALUES ($1, $2)"

  db_connection do |conn|
    questions.each do |person, question|
      conn.exec_params(sql_query, [person, question])
    end
  end
end

def add_homes
  homes = ["Good Home", "Average Home", "Bad Home", "Chaotic Home"]
  ids = []
  sql_query = "INSERT INTO homes (name) VALUES ($1) RETURNING id"
  db_connection do |conn|
    homes.each do |name|
      id = conn.exec_params(sql_query, [name])
      ids << id.to_a[0]["id"]
    end
  end
  ids
end

def add_reviewers
  reviewers = ["Youth 1", "Youth 2", "Parent", "Worker"]
  ids = []
  sql_query = "INSERT INTO reviewers (name) VALUES ($1) RETURNING id"
  db_connection do |conn|
    reviewers.each do |name|
      id = conn.exec_params(sql_query, [name])
      ids << id.to_a[0]["id"]
    end
  end
  ids
end

def add_reviews
    home_ids = add_homes
    reviewer_ids = add_reviewers
    (1..11).each do |month|
    start_day = Date.today - 30 * month
    end_day = Date.today - 29 * month
    date = Faker::Date.between(start_day, end_day).to_s
    reviewer_ids.each do |person|
      review = Faker::Lorem.paragraph

      good_rating = [8, 9, 10].sample
      good_review = [date, good_rating, review , person, home_ids[0]]

      average_rating = [5, 6, 7].sample
      average_review = [date, average_rating, review , person, home_ids[1]]

      bad_rating = rand(5)
      bad_review = [date, bad_rating, review , person, home_ids[2]]

      chaotic_rating = rand(11)
      chaotic_review = [date, chaotic_rating, review , person, home_ids[3]]

      sql_query = "INSERT INTO reviews (review_date, rating, review, reviewer_id, home_id) VALUES ($1, $2, $3, $4, $5)"
      db_connection do |conn|
        conn.exec_params(sql_query, good_review)
        conn.exec_params(sql_query, average_review)
        conn.exec_params(sql_query, bad_review)
        conn.exec_params(sql_query, chaotic_review)
      end
    end
  end
end

add_questions
add_reviews
