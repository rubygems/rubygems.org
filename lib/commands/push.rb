require 'net/http'
require 'net/https'
require 'rubygems/local_remote_options'

class Gem::Commands::PushCommand < Gem::Command

  include Gem::LocalRemoteOptions

  def description
    'Push a gem up to Gemcutter'
  end

  def arguments
    "GEM       built gem to push up"
  end

  def usage
    "#{program_name} GEM"
  end

  def initialize
    super 'push', description
    add_proxy_option
  end

  def execute
    use_proxy! if http_proxy
    sign_in unless api_key
    send_gem
  end

  def send_gem
    say "Pushing gem to Gemcutter..."

    name = get_one_gem_name
    url = URI.parse("#{gemcutter_url}/gems")

    http = Net::HTTP.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = (url.scheme == 'https')
    request = Net::HTTP::Post.new(url.path)
    request.body = File.open(name).read
    request.add_field("Content-Length", request.body.size)
    request.add_field("Authorization", api_key)

    response = http.request(request)

    say response.body
  end

end
