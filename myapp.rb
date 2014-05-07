# myapp.rb
require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'oauth'
require 'rubygems'
require 'twitter'
set :server, 'webrick' 
set :bind, '0.0.0.0'
set :environment, :production

ActiveRecord::Base.establish_connection(
    "adapter"  => "sqlite3",
    "database" => "./bbs.db"
)

class Comment < ActiveRecord::Base
end

# validation Session
enable :sessions
 
# Set up Twitter API
YOUR_CONSUMER_KEY    = "YVNVCrq9Q0O2bXyVcQ5Rw"
YOUR_CONSUMER_SECRET = "dqBJcs2YxiiodtN32KTaZlcTWHiThDHwfkryos8ilo"
 
def oauth_consumer
  return OAuth::Consumer.new(YOUR_CONSUMER_KEY, YOUR_CONSUMER_SECRET, :site => "https://api.twitter.com")
end
 
# top page
get '/' do
  "<html><body><a href='/twitter/auth'>Twitter access start!!</a></body></html>"
end

get '/top' do
   @comments = Comment.order("id desc").all
   erb :index
end

post '/new' do
   Comment.create({body: params[:test]})
   #Comment.create({:name => hoge})
   redirect '/top'
end

post '/delete' do
   Comment.find(params[:id]).destroy
end

# Twitter Request authentication
get '/twitter/auth' do
  # Appointname callback URL
  callback_url = "http://133.13.60.165:4567/twitter/callback"
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
    user = client.user
    user_name = user.name
    comment = Comment.new
    comment.username = user_name
    comment.save
    puts user.name
    puts access_token.secret 
    puts "---------------"

    puts "Finish!"
    redirect '/top'
end
