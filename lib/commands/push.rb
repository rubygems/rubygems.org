class Gem::Commands::PushCommand < Gem::AbstractCommand

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
    require 'net/http'
    require 'net/https'

    setup
    send_gem
  end

  def send_gem
    say "Pushing gem to Gemcutter..."

    name = get_one_gem_name
    url = URI.parse("#{gemcutter_url}/gems")

    http = proxy_class.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = (url.scheme == 'https')
    request = proxy_class::Post.new(url.path)
    request.body = File.open(name).read
    request.add_field("Content-Length", request.body.size)
    request.add_field("Authorization", api_key)

    response = http.request(request)

    say response.body
  end

end
