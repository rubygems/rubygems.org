$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

require 'rubygems/command_manager'

%w[migrate push tumble].each do |command|
  require "commands/#{command}"
  Gem::CommandManager.instance.register_command command.to_sym
end

URL = "http://gemcutter.org" unless defined?(URL)

class Gem::Command
  def api_key
    Gem.configuration[:gemcutter_key]
  end

  def gemcutter_url
    if ENV['test']
      "http://gemcutter.local"
    else
      "https://gemcutter.heroku.com"
    end
  end

  def sign_in
    say "Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up"

    email = ask("Email: ")
    password = ask_for_password("Password: ")

    url = URI.parse("#{gemcutter_url}/api_key")

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

  # @return [URI, nil] the HTTP-proxy as a URI if set; +nil+ otherwise
  def http_proxy
    proxy = Gem.configuration[:http_proxy]
    return nil if proxy.nil? || proxy == :no_proxy
    URI.parse(proxy)
  end

  def ask_for_password(message)
    password = ui.ask_for_password(message)
    ui.say("\n")
    password
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
