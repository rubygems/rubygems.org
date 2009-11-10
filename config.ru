if ENV['MAINTENANCE_MODE']
  require "#{File.dirname(__FILE__)}/vendor/bundler_gems/environment"
  require 'config/environment'

  get '/' do
    send_file("public/maintenance/index.html")
  end

  use Rack::Static, :urls => ["/index.html", "/favicon.ico", "/images", "/stylesheets"], :root => "public/maintenance"
  use Hostess
  run Sinatra::Application
else
  require 'thin'
  require 'rack/adapter/rails'
  run Rack::Adapter::Rails.new(:environment => ENV['RAILS_ENV'])
end

