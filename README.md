# bluevia-sinatra

A minimal example of using the Telefonica Bluevia API (http://bluevia.com) from a Sinatra app

It allows you to test OAuth login (both via callback and entering oob pin), and then uses the token to send a SMS to the sandbox and check the delivery status

# Usage

You will need the following gems (apart from anything needed to run sinatra, of course): ruby oauth (http://oauth.rubyforge.org/) and bluevia ruby library (i used version 1.1 from https://bluevia.com/en/knowledge/sdks.Ruby) 

    gem install ruby-oauth
    wget https://bluevia.com/resources/files/f75/f75a71a3649785a39d08c47adfd7382c/bluevia-sdk-ruby-v1.1.zip
    unzip bluevia-sdk-ruby-v1.1.zip
    gem install bluevia-sdk-ruby-v1.1/bluevia-1.1.gem

Also, you need to export environment variables with your Bluevia key and secret, as well as the prefix you defined for your sandbox. These should be available from from the bluevia portal at https://bluevia.com/en/my-apps/api-keys in the "View details" section. The sandbox prefix is labeled "Sandbox MO keyword"

    export CONSUMER_KEY="your consumer key"
    export CONSUMER_SECRET="your consumer secret"
    export SANDBOX_PREFIX="your MO keyword"

Once you have done all of the above, just run

    ruby bluevia-sinatra.rb
    
# FAQ

* *oops, I'm getting an Oauth::Unauthorized error. What went wrong?*

If you see a message like "OAuth::Unauthorized at /request 400 Bad Request" the more probable cause is that you are not using a valid consumer key and secret. Please make sure that your consumer key and secret values are correct and that they are exported into the correct environment variables (as explained in the Usage section above) Alternatively, feel free to overwrite the CONSUMER_KEY and CONSUMER_SECRET variables at the top of the file. 