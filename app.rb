require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'date'
require 'json'
require 'pg'
require 'openssl'

require_relative 'modules/database'
require_relative 'models/home'
require_relative 'models/form'
require_relative 'models/reviewer'
require_relative 'models/review'
require_relative 'models/user'

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

helpers do
  def admin?
    if session[:admin] == "t"
      "/admin"
    else
      "/foster_home"
    end
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
  if User.valid_sign_in?(params)
    user = User.find_by(params["username"])
    session[:user_id] = user.id
    session[:admin] = user.admin_status
    if user.admin_status == "t"
      redirect('/admin')
    else
      redirect('/foster_home')
    end
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
  if User.valid_registration?(params)
    user = User.add(params)
    redirect('/sign_in')
  else
    @input = params
    erb :register
  end
end

get '/sign_out' do
  session[:user_id] = nil
  session[:admin] = nil
  redirect('/')
end

get '/foster_home' do
  @homes = Home.all(session[:user_id])
  erb :'foster_home/index'
end

get '/foster_home/:home_id' do |home_id|
  @home = Home.find(home_id)
  erb :'foster_home/show'
end

get '/foster_home/:home_id/data.json' do |home_id|
  content_type :json
  { data: Home.find_data(home_id) }.to_json
end

get '/foster_home/:home_id/form' do |home_id|
  @forms = Form.all
  erb :'foster_home/form/index'
end

get '/foster_home/:home_id/form/:form_id' do |home_id, form_id|
  @form = Form.find(form_id)
  @input = Hash.new("")
  erb :'foster_home/form/show'
end

post '/foster_home/:home_id/form/:form_id' do |home_id, form_id|
  if Form.valid_submission?(params)
    params["reviewer_id"] = Reviewer.add(params).id
    Review.add(params)
    redirect(request.path + "/submitted")
  else
    redirect(request.path)
  end
end

get '/foster_home/:home_id/form/:form_id/submitted' do |home_id, form_id|
  erb :'foster_home/form/submitted/index'
end

get '/admin' do
  @users = User.all
  erb :'admin/index'
end

get '/admin/data.json' do
  content_type :json
  { data: Home.all_data(params["user_id"]) }.to_json
end

get '/admin/manage' do
  @homes = Home.all
  @users = User.all
  erb :'admin/manage/index'
end

get '/admin/manage/data.json' do
  content_type :json
  { data: Home.all_data(params["user_id"]) }.to_json
end

post '/admin/manage' do
  if params["action"] == "Add Home"
    Home.add(params) unless params["home_name"].empty?
  elsif params["action"] == "Delete Home"
    Home.delete(params)
  elsif params["action"] == "Assign Home"
    User.assign_home(params)
  elsif params["action"] == "Unassign Home"
    User.unassign_home(params)
  end
  redirect('/admin/manage')
end
