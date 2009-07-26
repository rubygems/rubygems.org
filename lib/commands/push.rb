require 'net/http'
require 'net/https'

class Gem::Commands::PushCommand < Gem::Command
  def description
    'Push a gem up to Gemcutter'
  end

  def arguments
    "GEM       built gem to push up"
  end

  def usage
    "#{programe_name} GEM"
  end

  def initialize
    super 'push', description
  end

  def execute
    sign_in unless api_key
    send_gem
  end

  def ask_for_password(message)
    password = ui.ask_for_password(message)
    ui.say("\n")
    password
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
    http.use_ssl = (url.scheme == 'https')
    request = Net::HTTP::Post.new(url.path)
    request.body = File.open(name).read
    request.content_length = request.body.size
    request.initialize_http_header("HTTP_AUTHORIZATION" => api_key)

    response = http.request(request)

    say response.body
  end

  def sign_in
    say "Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up"

    email = ask("Email: ")
    password = ask_for_password("Password: ")

    url = URI.parse("#{push_url}/api_key")

    http = Net::HTTP.new(url.host, url.port)
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
end

class Gem::StreamUI
  def ask_for_password(message)
    system "stty -echo"
    password = ask(message)
    system "stty echo"
    password
  end
end
