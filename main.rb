require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/player_new'
  end
end

get '/player_new' do
  erb :player_new
end

post '/player_new' do 
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do

  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end

