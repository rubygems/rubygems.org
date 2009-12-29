class Gem::Commands::WebhookCommand < Gem::AbstractCommand
  def description
    'Register a webhook to be called any time a gem is updated.'
  end
  
  def arguments
     "GEM_NAME       name of gem to register interest in. Use '*' for all gems."
   end

   def usage
     "#{program_name} GEM_NAME or '*'"
   end

  def initialize
    super 'webhook', description
    add_option('-a', '--add URL', 'The URL of the webhook') do |value, options|
      options[:url] = value
    end
    add_proxy_option
  end

  def execute
    setup
    post_webhook
  end

  def post_webhook
    say "Registering webhook..."
    name = get_one_gem_name
    url = options[:url]
    response = make_request(:post, "web_hooks") do |request|
      request.set_form_data("gem_name" => name, "url" => url)
      request.add_field("Authorization", api_key)
    end
    case response
    when Net::HTTPSuccess
      say response.body
    else
      say response.body
      terminate_interaction
    end
  end
end
