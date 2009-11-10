if ENV['MAINTENANCE_MODE']
  require File.join('vendor', 'bundler_gems', 'environment')
  require File.join('config', 'environment')

  use Rack::Static, :urls => ["/index.html", "/favicon.ico", "/images", "/stylesheets"], :root => "public/maintenance"
  use Hostess
  use Rack::Maintenance, :file => File.join('public', 'maintenance', 'index.html')
  run Sinatra::Application
else
  require 'thin'

  run Rack::Adapter::Rails.new(:environment => ENV['RAILS_ENV'])
end

