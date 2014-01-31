Gemcutter::Application.configure do
  config.active_support.deprecation = :notify

  config.middleware.use ::Rack::Static,
    :urls => ["/index.html",
              "/favicon.ico",
              "/images",
              "/stylesheets"],
    :root => "public/maintenance"
  config.middleware.use ::Rack::Maintenance,
    :file => File.join('public', 'maintenance', 'index.html')

  config.plugins = []
  config.eager_load = true
end

require Rails.root.join("config", "secret") if Rails.root.join("config", "secret.rb").file?
