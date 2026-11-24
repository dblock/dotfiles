# Usage: publisher.rb create|list OTP. Configures or lists strava-ruby-client's RubyGems trusted publishers.
# Reads the API key from ~/.config/rubygems/trusted_publishers_key and never prints it.
require 'json'
require 'net/http'

action, otp = ARGV
abort 'Usage: publisher.rb create|list OTP.' unless %w[create list].include?(action) && otp.to_s.match?(/\A\d{6}\z/)

key = File.read(File.expand_path('~/.config/rubygems/trusted_publishers_key')).strip
uri = URI('https://rubygems.org/api/v1/gems/strava-ruby-client/trusted_publishers')
request = action == 'create' ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
request['Authorization'] = key
request['OTP'] = otp
request['Accept'] = 'application/json'
if action == 'create'
  request['Content-Type'] = 'application/json'
  request.body = {
    trusted_publisher_type: 'OIDC::TrustedPublisher::GitHubAction',
    trusted_publisher: {
      repository_owner: 'dblock',
      repository_name: 'strava-ruby-client',
      workflow_filename: 'release.yml',
      environment: 'release',
      workflow_repository_owner: 'dblock',
      workflow_repository_name: 'ruby-gem-release'
    }
  }.to_json
end

response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
puts "HTTP #{response.code}"
puts response.body
