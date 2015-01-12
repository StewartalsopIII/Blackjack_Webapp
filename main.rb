require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_AMOUNT = 17
INITIAL_POT_AMOUNT = 500

helpers do 
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @winner = "<strong>#{session[:player_name].capitalize} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>#{session[:player_name].capitalize} loses!</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong>Its a tie!</strong> #{msg}"
  end
end


before do
  @show_hit_or_stay_buttons = true 
  @play_again = false
end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/player_new'
  end
end

get '/player_new' do
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :player_new
end

post '/player_new' do 
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:player_new)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do 
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do 
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be more than what you have ($#{session[:player_pot]})"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
  session[:turn] = session[:player_name]

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

post '/game/player/hit' do 
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name].capitalize} hit blackjack.")  
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:player_name].capitalize} busts with #{player_total}")
  end

  erb :game, layout: false
end

post '/game/player/stay' do 
  @success = "You have chosen to stay"
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"

  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hits blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busts")
  elsif dealer_total >= DEALER_HIT_AMOUNT
    #dealer stays
    redirect '/game/compare'
  else dealer_total < DEALER_HIT_AMOUNT
    #deal the dealer another card
    @show_dealer_hit_button = true
  end
  
  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do 
  @show_hit_or_stay_buttons = false
  
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])

  if dealer_total < player_total
    winner!("#{session[:player_name].capitalize} has #{player_total} and Dealer has #{dealer_total}")
  elsif dealer_total > player_total
    loser!("#{session[:player_name].capitalize} has #{player_total} and Dealer has #{dealer_total}")
  else dealer_total == player_total
    tie!("Dealer has #{dealer_total} and #{session[:player_name].capitalize} has #{player_total}")
  end

  erb :game, layout: false
end

get '/game_over' do 
  erb :game_over
end
