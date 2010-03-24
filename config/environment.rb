RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'
  config.action_mailer.delivery_method = :sendmail
  config.frameworks -= [:active_resource]
  config.load_paths << Rails.root.join('app', 'middleware')
end

$redis = Redis.new
