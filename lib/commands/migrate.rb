class Gem::Commands::MigrateCommand < Gem::AbstractCommand
  attr_reader :rubygem

  def description
    'Migrate a gem your own from Rubyforge to Gemcutter.'
  end

  def initialize
    super 'migrate', description
  end

  def execute
    require 'open-uri'
    require 'net/scp'
    require 'json'
    require 'tempfile'

    setup
    migrate
  end

  def migrate
    find(get_one_gem_name)
    token = get_token
    upload_token(token)
    check_for_approved
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
    request.add_field("Content-Length", 0)
    request.add_field("Authorization", api_key)
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      say "A migration token has been created."
      response.body
    else
      say response.body
      terminate_interaction
    end
  end

  def upload_token(token)
    url = "#{self.rubygem['rubyforge_project']}.rubyforge.org"
    say "Uploading the migration token to #{url}. Please enter your RubyForge login:"
    login = ask("Login: ")
    password = ask_for_password("Password: ")

    begin
      Net::SCP.start(url, login, :password => password) do |scp|
        temp_token = Tempfile.new("token")
        temp_token.chmod 0644
        temp_token.write(token)
        temp_token.close
        scp.upload! temp_token.path, "/var/www/gforge-projects/#{rubygem['rubyforge_project']}/migrate-#{rubygem['name']}.html"
      end
      say "Successfully uploaded your token."
    rescue Exception => e
      say "There was a problem uploading your token: #{e}"
    end
  end

  def check_for_approved
    say "Asking Gemcutter to verify the upload..."
    url = URI.parse("#{gemcutter_url}/gems/#{rubygem["slug"]}/migrate")

    http = proxy_class.new(url.host, url.port)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = (url.scheme == 'https')
    request = proxy_class::Put.new(url.path)
    request.add_field("Content-Length", 0)
    request.add_field("Authorization", api_key)
    response = http.request(request)

    say response.body
  end
end
