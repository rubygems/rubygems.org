require 'net/http'

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

  def send_gem
    say "Pushing gem to Gemcutter..."

    name = get_one_gem_name
    site = ENV['TEST'] ? "local" : "org"
    url = URI.parse("http://gemcutter.#{site}/gems")

    request = Net::HTTP::Post.new(url.path)
    request.body = File.open(name).read
    request.content_length = request.body.size
    request.initialize_http_header("HTTP_AUTHORIZATION" => api_key)

    response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }
    say response.body
  end

  def sign_in
    say "Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up"

    email = ask("Email: ")
    password = ask_for_password("Password: ")

    site = ENV['TEST'] ? "local" : "org"
    url = URI.parse("http://gemcutter.#{site}/api_key")

    request = Net::HTTP::Get.new(url.path)
    request.basic_auth email, password
    response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }

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
