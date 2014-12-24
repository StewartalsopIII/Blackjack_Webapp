require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get '/test' do 
  erb :test
end

get '/nested_template' do 
  erb :"/users/profile"
end




