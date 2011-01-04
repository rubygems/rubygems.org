$rubygems_config = YAML.load_file(Rails.root.join("config", "rubygems.yml"))[Rails.env].symbolize_keys

HOST             = $rubygems_config[:host]
Hostess.local    = $rubygems_config[:local_storage]
RUBYGEMS_VERSION = "1.4.1"

Gemcutter::Application.configure do
  config.action_mailer.default_url_options = { :host => HOST }
  config.middleware.insert_after 'Hostess', 'Redirector' if $rubygems_config[:redirector]
end
