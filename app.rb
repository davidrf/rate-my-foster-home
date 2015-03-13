require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'date'
require 'json'
require 'pg'
require 'openssl'

require_relative 'models/homes'
require_relative 'models/questions'
require_relative 'models/reviewers'
require_relative 'models/reviews'
require_relative 'models/users'

use Rack::Session::Cookie, {
  secret: ENV["COOKIE_SECRET"] || "secret"
}

configure :development, :test do
  require 'pry'
  require 'faker'
end

Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
  require file
  also_reload file
end

def db_connection
  connection_settings = { dbname: ENV["DATABASE_NAME"] || "foster_homes" }

  if ENV["DATABASE_HOST"]
    connection_settings[:host] = ENV["DATABASE_HOST"]
  end

  if ENV["DATABASE_USER"]
    connection_settings[:user] = ENV["DATABASE_USER"]
  end

  if ENV["DATABASE_PASS"]
    connection_settings[:password] = ENV["DATABASE_PASS"]
  end

  begin
    connection = PG.connect(connection_settings)
    yield(connection)
  ensure
    connection.close
  end
end

def get_user_info(username)
  sql_query = "SELECT * FROM users WHERE username = $1"
  info = nil
  db_connection do |conn|
    info = conn.exec_params(sql_query, [username])
  end
  info.to_a[0]
end

def valid_sign_in?(input, user)
  return false if input.values.include?("") || user.nil?
  sha256 = OpenSSL::Digest::SHA256.new
  encrypted_password = [sha256.digest(input[:password])].pack('m')
  input[:username] == user["username"] && encrypted_password == user["password"]
end

def valid_registration?(input)
  if input.values.include?("") || get_user_info(input[:username])
    return false
  end
  input[:password] == input[:confirm_password]
end

def add_user(info)
  sha256 = OpenSSL::Digest::SHA256.new
  encrypted_password = [sha256.digest(info[:password])].pack('m')
  sql_query = "INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id"
  user_id = nil
  db_connection do |conn|
    user_id = conn.exec_params(sql_query, [info[:username], encrypted_password])
  end
  user_id = user_id.to_a[0]["id"]
  [1, 2, 3, 4].each { |home| assign_home(user_id, home) }
  user_id
end

def retrieve_homes_for(user_id)
  sql_query = "SELECT homes.id, homes.name FROM user_homes
  JOIN homes ON user_homes.home_id = homes.id
  WHERE user_homes.user_id = $1"
  homes = nil
  db_connection do |conn|
    homes = conn.exec_params(sql_query, [user_id])
  end
  homes.to_a
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

def assign_home(user_id, home_id)
  sql_query = "INSERT INTO user_homes (user_id, home_id) SELECT $1, $2
  WHERE NOT EXISTS(SELECT 1 FROM user_homes WHERE user_id = $1 AND home_id = $2)"
  db_connection { |conn| conn.exec_params(sql_query, [user_id, home_id]) }
end

def get_reviews(home_id)
  sql_query = "SELECT reviews.review_date, reviews.rating,
  reviews.review, reviewers.name FROM reviews
  JOIN reviewers ON reviews.reviewer_id = reviewers.id
  JOIN homes ON reviews.home_id = homes.id
  WHERE homes.id = $1 ORDER BY reviews.review_date DESC, ts DESC"
  reviews = nil
  db_connection do |conn|
    reviews = conn.exec_params(sql_query, [home_id])
  end
  reviews.to_a
end

def home_ratings_for(id)
  reviews = get_reviews(id)
  reviews = reviews.sort_by { |review| review["review_date"] }

  dates = reviews.inject([]) do |dates, review|
    dates << review["review_date"] unless dates.include?(review["review_date"])
    dates
  end

  scores = reviews.inject({}) do |scores, review|
    scores[review["name"]] = {} unless scores[review["name"]]
    scores[review["name"]][review["review_date"]] = review["rating"].to_i
    scores
  end

  data = scores.inject([]) do |data, (reviewer, scores_hash)|
    reviewer_data = [reviewer]
    dates.each { |date| reviewer_data << scores_hash[date] }
    data << reviewer_data
  end

  data.unshift(['Dates', dates].flatten)
  data.transpose
end

def get_question_for(person)
  sql_query = "SELECT question FROM questions WHERE person = $1"
  question = nil
  db_connection do |conn|
    question = conn.exec_params(sql_query, [person])
  end
  question.to_a[0]["question"]
end

def valid_review?
  !params["reviewer"].empty? && !params["review_date"].empty?
end

def add_reviewer(reviewer_name)
  sql_query = "INSERT INTO reviewers (name) SELECT $1::varchar
  WHERE NOT EXISTS(SELECT 1 FROM reviewers WHERE name = $1)"
  db_connection { |conn| conn.exec_params(sql_query, [reviewer_name]) }
end

def get_reviewer_id(reviewer_name)
  sql_query = "SELECT id FROM reviewers WHERE name = $1"
  id = nil
  db_connection do |conn|
    id = conn.exec_params(sql_query, [reviewer_name])
  end
  id.to_a[0]["id"]
end

def store_review(review, person)
  reviewer = review["reviewer"] + " (#{person})"
  add_reviewer(reviewer)
  reviewer_id = get_reviewer_id(reviewer)

  sql_query1 = "DELETE FROM reviews WHERE review_date = $1 AND reviewer_id = $2
  AND home_id = $3"
  data1 = [review["review_date"], reviewer_id, review["id"]]

  sql_query2 = "INSERT INTO reviews (review_date, rating, review, reviewer_id, home_id)
  VALUES ($1, $2, $3, $4, $5) "
  data2 = [review["review_date"], review["rating"], review["explanation"], reviewer_id, review["id"]]

  db_connection do |conn|
    conn.exec_params(sql_query1, data1)
    conn.exec_params(sql_query2, data2)
  end
end

get '/' do
  redirect('/sign_in')
end

get '/sign_in' do
  @input = Hash.new("")
  erb :sign_in
end

post '/sign_in' do
  user_info = get_user_info(params[:username])
  if valid_sign_in?(params, user_info)
    session[:user_id] = user_info["id"]
    redirect('/foster_homes')
  else
    @input = params
    erb :sign_in
  end
end

get '/register' do
  @input = Hash.new("")
  erb :register
end

post '/register' do
  if valid_registration?(params)
    session[:user_id] = add_user(params)
    redirect('/sign_in')
  else
    @input = params
    erb :register
  end
end

get '/sign_out' do
  session[:user_id] = nil
  redirect('/')
end

get '/foster_homes' do
  delete(params["home"]) if params["home"]
  @homes = retrieve_homes_for(session[:user_id])
  erb :'foster_homes/index'
end

post '/foster_homes' do
  unless params[:home].empty?
    add_home(params[:home])
    home_id = get_home_id(params[:home])
    assign_home(session[:user_id], home_id)
  end
  redirect('/foster_homes')
end

get '/foster_homes/:id' do |id|
  @reviews = get_reviews(id)
  erb :'foster_homes/show'
end

get '/foster_homes/:id/data.json' do |id|
  content_type :json
  { data: home_ratings_for(id) }.to_json
end

get '/foster_homes/:id/review' do |id|
  @home_id = id
  erb :'foster_homes/review/index'
end

get '/foster_homes/:id/review/:person' do |id, person|
  @home_id = id
  @person = person
  @survey_question = get_question_for(person)
  @input = Hash.new("")
  erb :'foster_homes/review/show'
end

post '/foster_homes/:id/review/:person' do |id, person|
  if valid_review?
    store_review(params, person)
    redirect("/foster_homes/#{id}/review_submitted")
  else
    redirect(request.path)
  end
end

get '/foster_homes/:id/review_submitted' do |id|
  @id = id
  erb :'foster_homes/review_submitted/index'
end

get '/admin_home'
  erb :'admins/index'
end
