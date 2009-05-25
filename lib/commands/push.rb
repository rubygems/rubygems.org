require 'net/http'

class Gem::Commands::PushCommand < Gem::Command
  DESCRIPTION = 'Push a gem up to Gemcutter'

  def description
    DESCRIPTION
  end

  def arguments
    "GEM       built gem to push up"
  end

  def usage
    "#{programe_name} GEM"
  end

  def initialize
    super 'push', DESCRIPTION
  end

  def execute
    say "Pushing gem to Gemcutter..."

    gem = get_one_gem_name
    url = URI.parse("http://gemcutter.org/gems")
    request = Net::HTTP::Post.new(url.path)
    request.body = File.open(gem).read
    request.content_length = request.body.size
    request.content_type = "application/octet-stream"

    response = Net::HTTP.new(url.host, url.port).start { |http| http.request(request) }
    say response.body
  end
end

Gem::CommandManager.instance.register_command :push
