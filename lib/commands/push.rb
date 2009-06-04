require 'yaml'
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
    say "Pushing gem to Gemcutter..."

    name = get_one_gem_name
    site = ENV['TEST'] ? "local" : "org"
    url = URI.parse("http://gemcutter.#{site}/gems")

    request = Net::HTTP::Post.new(url.path)
    request.body = File.open(name).read
    request.content_length = request.body.size
    request.initialize_http_header("HTTP_AUTHORIZATION" => Gem.configuration[:gemcutter_key])

    response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }
    say response.body
  end
end

Gem::CommandManager.instance.register_command :push
