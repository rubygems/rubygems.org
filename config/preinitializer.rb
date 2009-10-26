require "#{File.dirname(__FILE__)}/../vendor/bundler_gems/environment"

class Rails::Boot
  def run
    load_initializer
    extend_environment
    Rails::Initializer.run(:set_load_path)
  end

  def extend_environment
    Rails::Initializer.class_eval do
      old_load = instance_method(:load_environment)
      define_method(:load_environment) do
        Bundler.require_env RAILS_ENV
        old_load.bind(self).call
      end
    end
  end
end
