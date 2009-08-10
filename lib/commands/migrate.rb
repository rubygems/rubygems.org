class Gem::Commands::MigrateCommand < Gem::AbstractCommand
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
    name = get_one_gem_name
    say "Starting migration of #{name} from RubyForge..."
    token = get_token(name)
    #upload_token(token)
    #check_for_approval(name)
  end

  def get_token(name)

    #rubygem_migrate PUT    /gems/:rubygem_id/migrate(.:format)        {:controller=>"migrations", :action=>"update"}
    url = URI.parse("#{gemcutter_url}/gems/#{name}/migrate")

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
