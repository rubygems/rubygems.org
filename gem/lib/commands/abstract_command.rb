require 'rubygems/local_remote_options'

class Gem::AbstractCommand < Gem::Command
  include Gem::LocalRemoteOptions

  def gemcutter_url
    ENV['GEMCUTTER_URL'] || 'https://gemcutter.org'
  end

  def setup
    use_proxy! if http_proxy
    sign_in unless api_key
  end

  def sign_in
    say "Enter your Gemcutter credentials. Don't have an account yet? Create one at http://gemcutter.org/sign_up"

    email = ask("Email: ")
    password = ask_for_password("Password: ")

    response = make_request(:get, "api_key") do |request|
      request.basic_auth email, password
    end

    case response
    when Net::HTTPSuccess
      self.api_key = response.body
      say "Signed in. Your api key has been stored in ~/.gem/credentials"
    else
      say response.body
      terminate_interaction
    end
  end

  def credentials_path
    File.join(Gem.user_home, '.gem', 'credentials')
  end

  def api_key
    Gem.configuration.load_file(credentials_path)[:rubygems_api_key]
  end

  def api_key=(api_key)
    config = Gem.configuration.load_file(credentials_path).merge(:rubygems_api_key => api_key)

    dirname = File.dirname(credentials_path)
    Dir.mkdir(dirname) unless File.exists?(dirname)

    File.open(credentials_path, 'w') do |f|
      f.write config.to_yaml
    end

    @rubygems_api_key = api_key
  end

  def make_request(method, path)
    require 'net/http'
    require 'net/https'

    url = URI.parse("#{gemcutter_url}/api/v1/#{path}")

    http = proxy_class.new(url.host, url.port)

    if url.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.use_ssl = true
    end

    request_method =
      case method
      when :get
        proxy_class::Get
      when :post
        proxy_class::Post
      when :put
        proxy_class::Put
      when :delete
        proxy_class::Delete
      else
        raise ArgumentError
      end

    request = request_method.new(url.path)
    request.add_field "User-Agent", "Gemcutter/0.2.0"

    yield request if block_given?
    http.request(request)
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
    proxy = Gem.configuration[:http_proxy] || ENV['http_proxy'] || ENV['HTTP_PROXY']
    return nil if proxy.nil? || proxy == :no_proxy
    URI.parse(proxy)
  end

  def ask_for_password(message)
    system "stty -echo"
    password = ask(message)
    system "stty echo"
    ui.say("\n")
    password
  end
end
