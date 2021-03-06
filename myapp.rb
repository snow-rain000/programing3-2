# -*- coding: utf-8 -*-
# myapp.rb
require 'sqlite3'
require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'oauth'
require 'rubygems'
require 'twitter'
require 'pp'
set :server, 'webrick' 
set :bind, '0.0.0.0'
set :environment, :production

ActiveRecord::Base.establish_connection(
    "adapter"  => "sqlite3",
    "database" => "./bbs.db"
)

class Comment < ActiveRecord::Base
end

class Follower < ActiveRecord::Base
end

# make instance of database
#db = SQLite3::Database.new("bbs.db")
db = SQLite3::Database.new("follower.db")

# validation Session
use Rack::Session::Cookie, :secret => SecureRandom.hex(32),
                  :expire_after => 60*60 # 1 min
 
# Set up Twitter API
YOUR_CONSUMER_KEY    = "your consumer key"
YOUR_CONSUMER_SECRET = "your consumer secret"
 
def oauth_consumer
  return OAuth::Consumer.new(YOUR_CONSUMER_KEY, YOUR_CONSUMER_SECRET, :site => "https://api.twitter.com")
end
 
# top page
get '/' do
#   "<html><body><a href='/twitter/auth'>Twitter access start!!</a></body></html>"
  if session[:AcountName].nil? then
    erb :testIndex
  else
  "<html><body><a href='/top'>JUMP BBS</a></body></html>"
  end
end

get '/top' do
if session[:AcountName].nil? then
  "<html><body><a href='/'>JUMP access page</a></body></html>"
else
  @comments = Comment.order("id desc").all
  @followers = Follower.all
  @write_user = session[:AcountName]
  erb :bbs
end
end

get '/follower' do
  erb :follower_all
end

get '/search' do
  @comments = Comment.order("id desc").all
  @followers = Follower.all
  @write_user = session[:AcountName]
  erb :test_link1
end

post '/new' do
   Comment.create({body: params[:test]})
   redirect '/top'
end

post '/chat' do
   Comment.create({chat: params[:message]})
   redirect '/search'
end

post '/delete' do
   Comment.find(params[:id]).destroy
end

post '/usearch' do
   redirect '/search'
end

# Twitter Request authentication
get '/twitter/auth' do
  # Appointname callback URL
  callback_url = "http://e125721.st.ie.u-ryukyu.ac.jp:4567/twitter/callback"
  request_token = oauth_consumer.get_request_token(oauth_callback: callback_url)
 
  # セッションにトークンを保存
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url
end
 
# Take toke and etc.. from Twitter
get '/twitter/callback' do
  request_token = OAuth::RequestToken.new(oauth_consumer, session[:request_token], session[:request_token_secret])
 
  # OAuthで渡されたtoken, verifierを使って、tokenとtoken_secretを取得
  access_token = nil
  begin
    access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier])
  rescue OAuth::Unauthorized => @exception
    # 本来はエラー画面を表示したほうが良いが、今回はSinatra標準のエラー画面を表示
    raise
  end

# login
    client = Twitter::REST::Client.new do |config|
        config.consumer_key        = YOUR_CONSUMER_KEY
        config.consumer_secret     = YOUR_CONSUMER_SECRET
        config.access_token        = access_token.token
        config.access_token_secret = access_token.secret
    end

    puts "---------------"
    
    if session[:AcountName].nil? then
      uid = client.user
      session[:AcountName] = uid.name

      followers = []
      begin
        user_name = uid.name
        follower_ids = client.follower_ids("#{uid.screen_name}").to_a
        loop_count = (follower_ids.size - 1) / 100 + 1
        loop_count.times do
          ids = follower_ids.pop(100)
          accounts_temp = client.users(ids)
          followers.concat(accounts_temp)
        end

        followers.each_with_index{ |follower, i|
#          puts Comment.where(["username = ? and follower = ?", user_name, user.name ]).empty?
#          puts Comment.where(["username = ? and follower = ?", user_name, user.name ]).nil?
          if Follower.where(["username = ? and follower = ?", user_name, follower.name ]).empty? then
            userid = Follower.new
            userid.username = user_name
            userid.follower = follower.name
            userid.save
          end
        }
      rescue Twitter::Error::TooManyRequests => error
         sleep error.rate_limit.reset_in
         retry
      end
    else
      redirect '/top'
    end

    puts uid.name
    puts access_token.secret 
    puts "---------------"

    puts "Finish!"
    redirect '/top'
end
