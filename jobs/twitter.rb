require 'net/http'
require 'json'
require 'yaml'

APP_CONFIG ||= YAML.load_file( File.join(Sinatra::Application.root, 'config.yml') )

search_term = URI::encode("#{APP_CONFIG['twitterTag']}")

SCHEDULER.every '10m', :first_in => 0 do |job|
  http = Net::HTTP.new('search.twitter.com')
  response = http.request(Net::HTTP::Get.new("/search.json?q=#{search_term}"))
  tweets = JSON.parse(response.body)["results"]
  if tweets
    tweets.map! do |tweet|
      { name: tweet['from_user'], body: tweet['text'], avatar: tweet['profile_image_url_https'] }
    end

    send_event('twitter_mentions', comments: tweets, moreinfo: "Tweets tagged with #{APP_CONFIG['twitterTag']}")
  end
end
