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
    option_text = "The URL of the webhook to"

    add_option('-a', '--add URL', "#{option_text} add") do |value, options|
      options[:send] = 'add'
      options[:url] = value
    end

    add_option('-r', '--remove URL', "#{option_text} remove") do |value, options|
      options[:send] = 'remove'
      options[:url] = value
    end

    add_proxy_option
  end

  def execute
    setup
    name = get_one_gem_name

    send("#{options[:send]}_webhook", name, options[:url])
  end

  def add_webhook(name, url)
    say "Adding webhook..."
    make_webhook_request(:post, name, url)
  end

  def remove_webhook(name, url)
    say "Removing webhook..."
    make_webhook_request(:delete, name, url)
  end

  def make_webhook_request(method, name, url)
    response = make_request(method, "web_hooks") do |request|
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
