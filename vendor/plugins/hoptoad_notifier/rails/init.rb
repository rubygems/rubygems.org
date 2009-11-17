if defined?(ActionController::Base) && !ActionController::Base.include?(HoptoadNotifier::Catcher)
  ActionController::Base.send(:include, HoptoadNotifier::Catcher)
end

HoptoadNotifier.configure do |config|
  config.environment_name = RAILS_ENV
  config.project_root     = RAILS_ROOT
end
