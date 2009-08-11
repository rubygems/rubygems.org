require 'open-uri'
require 'json'

class Gem::Commands::MigrateCommand < Gem::AbstractCommand
  attr_reader :rubygem

  def description
    'Migrate a gem your own from Rubyforge to Gemcutter.'
  end

  def initialize
    super 'migrate', description
  end

  def execute
    setup
    migrate
  end

  def migrate
    find(get_one_gem_name)
    get_token
    #upload_token(token)
    #check_for_approval(name)
  end

  def find(name)
    begin
      data = open("#{gemcutter_url}/gems/#{name}.json")
      @rubygem = JSON.parse(data.string)
    rescue OpenURI::HTTPError
      say "This gem is currently not hosted on Gemcutter."
      terminate_interaction
    rescue JSON::ParserError => json_error
      say "There was a problem parsing the data: #{json_error}"
      terminate_interaction
    end
  end

  def get_token
    say "Starting migration of #{rubygem["name"]} from RubyForge..."

    url = URI.parse("#{gemcutter_url}/gems/#{rubygem["slug"]}/migrate")

    http = proxy_class.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = (url.scheme == 'https')
    request = proxy_class::Post.new(url.path)
    request.add_field("Authorization", api_key)
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      response.body
    else
      say response.body
      terminate_interaction
    end
  end
end
