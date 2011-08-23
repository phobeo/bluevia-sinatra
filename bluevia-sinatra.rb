require "rubygems"
require "sinatra"
require "oauth"
require "oauth/consumer"
require "bluevia"
include Bluevia

enable :sessions
# you can disable these in production to allow the error handling
# for dev we leave the ugly, yet verbosely useful error screen
#disable :raise_errors, :show_exceptions

CONSUMER_KEY = ENV['BLUEVIA_KEY']
CONSUMER_SECRET = ENV['BLUEVIA_SECRET']
MSG_PREFIX = ENV['BLUEVIA_PREFIX']
# remember to set the env variables before executing the script!
if CONSUMER_KEY.nil? or CONSUMER_SECRET.nil? or MSG_PREFIX.nil? 
  puts "Environment variables BLUEVIA_KEY, BLUEVIA_SECRET or BLUEVIA_PREFIX are not defined!"
  puts "Please make sure you have setup your environment variables before executing"
  puts "(see sample instructions at https://github.com/phobeo/bluevia-sinatra)"
  exit
end

UK_SHORTCODE = "5480605"

before do
  session[:oauth] ||= {}  
  @consumer ||= OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, {
      :request_token_url => "https://api.bluevia.com/services/REST/Oauth/getRequestToken/",
      :access_token_url  => "https://api.bluevia.com/services/REST/Oauth/getAccessToken/",
      :authorize_url     => "https://connect.bluevia.com/authorise/"
     })
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
    # once we have a token, create the authorised BlueviaClient object
    @bc = BlueviaClient.new(
       { :consumer_key   => CONSUMER_KEY,
         :consumer_secret=> CONSUMER_SECRET,
         :token          => @access_token.token,
         :token_secret   => @access_token.secret,
         :uri            => "https://api.bluevia.com"
       })
  end
end

error do
  'Sorry there was a nasty error - ' + env['sinatra.error']
end

get "/" do
  if @access_token
    erb :authorised
  else
    erb :start
  end
end

get "/request" do
  if(params[:method]=="oob") then
    # if oauth_callback is not specified, library assumes out of band 
    # (see http://oauth.rubyforge.org/rdoc/classes/OAuth/Consumer.html#M000109)
    callback = nil
  else 
    callback = "#{request.url.sub(/\/request/,"/callback")}"
    puts "using callback #{callback}"
  end
  @request_token = @consumer.get_request_token({:oauth_callback => callback})
  session[:oauth][:request_token] = @request_token.token
  session[:oauth][:request_token_secret] = @request_token.secret
  # for oob, we need to open page in new window, for callback, just redirect
  if(params[:method] == "oob") then
    erb :pinentry
  else
    redirect @request_token.authorize_url
  end
end

get "/callback" do
  #verifier will have come from form for PIN entry in the case of oob auth 
  # or straight from server in the callback case
  puts "using verifier #{params[:oauth_verifier]}"
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end

get "/smssend" do
  if @access_token
    @sms = @bc.get_service(:Sms)
    recipients=[UK_SHORTCODE]
    @resp = @sms.send(recipients, "#{SANDBOX_PREFIX} hello world!")
    erb :sms
  else
    redirect "/"
  end
end

get "/smsstatus" do
  if @access_token and params[:identifier]
    identifier = params[:identifier]
    @sms = @bc.get_service(:Sms)
    @info = @sms.get_delivery_status(identifier)
    erb :smsstatus
  else 
    redirect "/"
  end
end

__END__

@@ start
<a href="/request">start callback flow</a>
<br/>
<a href="/request?method=oob">start oob flow</a>

@@ authorised
<p>authorised succesfully! your token is <%= @access_token.token %> with secret <%= @access_token.secret %></p>
<br/>
<p><a href="/smssend">test send sms</a></p>
<a href="/logout">logout</a>

@@ pinentry
<a href="<%= @request_token.authorize_url %>" target="_blank">get pin (opens in separate window)</a>
<br/>
<form action="/callback" method="get">
  <input type="text" name="oauth_verifier" value="enter pin here"></input>
  <input type="submit"></input>
</form>

@@ sms
<p>sms send response (status)</p>
<p><%= @resp.to_s %></p>
<p><a href="/smsstatus?identifier=<%= @resp.to_s %>">check status</a></p>

@@ smsstatus
<p>status is <%= @info %></p>
<a href="/">back to start page</a>
