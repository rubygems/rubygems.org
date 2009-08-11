require 'rubygems/local_remote_options'

class Gem::AbstractCommand < Gem::Command
  include Gem::LocalRemoteOptions

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

  def setup
    use_proxy! if http_proxy
    sign_in unless api_key
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
    @proxy_class = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
  end

  def proxy_class
    @proxy_class || Net::HTTP
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
