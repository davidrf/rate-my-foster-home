require 'pg'
require 'pry'
require 'faker'

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

def add_home(home_name)
  sql_query = "INSERT INTO homes (name) SELECT $1::varchar
  WHERE NOT EXISTS(SELECT 1 FROM homes WHERE name = $1)"
  db_connection { |conn| conn.exec_params(sql_query, [home_name]) }
end

def get_home_id(home_name)
  sql_query = "SELECT id FROM homes WHERE name = $1"
  id = nil
  db_connection do |conn|
    id = conn.exec_params(sql_query, [home_name])
  end
  id.to_a[0]["id"]
end

def store_review(review)
  add_reviewer(review["reviewer"])
  reviewer_id = get_reviewer_id(review["reviewer"])

  date = Time.now.to_date.strftime("%Y-%m-%d")

  sql_query1 = "DELETE FROM reviews WHERE review_date = $1 AND reviewer_id = $2
  AND home_id = $3"
  data1 = [date, reviewer_id, review["id"]]

  sql_query2 = "INSERT INTO reviews (review_date, rating, review, reviewer_id, home_id)
  VALUES ($1, $2, $3, $4, $5) "
  data2 = [date, review["rating"], review["explanation"], reviewer_id, review["id"]]

  db_connection do |conn|
    conn.exec_params(sql_query1, data1)
    conn.exec_params(sql_query2, data2)
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


add_questions
