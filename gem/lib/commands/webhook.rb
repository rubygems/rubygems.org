class Gem::Commands::WebhookCommand < Gem::AbstractCommand

  def description
    <<-EOF
Register a webhook that will be called any time a gem is updated on Gemcutter.

Webhooks can be created for either specific gems or all gems. In both cases
you'll get a POST request of the gem in JSON format at the URL you specify in
the command. You can also use this command to test fire a webhook.
    EOF
  end

  def arguments
    "GEM_NAME       name of gem to register webhook for. Use '*' for all gems."
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
    add_webhook
  end

  def add_webhook
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
