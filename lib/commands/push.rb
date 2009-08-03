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

  def ask_for_password(message)
    password = ui.ask_for_password(message)
    ui.say("\n")
    password
  end
  
  # @return [URI, nil] the HTTP-proxy as a URI if set; +nil+ otherwise
  def http_proxy
    proxy = Gem.configuration[:http_proxy]
    return nil if proxy.nil? || proxy == :no_proxy
    URI.parse(proxy)
  end

  def api_key
    Gem.configuration[:gemcutter_key]
  end

  def push_url
    if ENV['test']
      "http://gemcutter.local"
    else
      "https://gemcutter.heroku.com"
    end
  end

  def send_gem
    say "Pushing gem to Gemcutter..."

    name = get_one_gem_name
    url = URI.parse("#{push_url}/gems")

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

  def sign_in
    say "Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up"

    email = ask("Email: ")
    password = ask_for_password("Password: ")

    url = URI.parse("#{push_url}/api_key")

    http = Net::HTTP.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = (url.scheme == 'https')
    request = Net::HTTP::Get.new(url.path)
    request.basic_auth email, password
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      Gem.configuration[:gemcutter_key] = response.body
      Gem.configuration.write
      say "Signed in. Your api key has been stored in ~/.gemrc"
    else
      say response.body
      terminate_interaction
    end
  end
  
  def use_proxy!
    proxy_uri = http_proxy
    proxy_class = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
    Net.send :remove_const, :HTTP
    Net.send :const_set, :HTTP, proxy_class
  end
  
end

class Gem::StreamUI
  def ask_for_password(message)
    system "stty -echo"
    password = ask(message)
    system "stty echo"
    password
  end
end
