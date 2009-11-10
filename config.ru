if ENV['MAINTENANCE_MODE']
  require 'sinatra'
  require 'aws/s3'
  require 'app/metal/hostess'
  require 'lib/vault_object'

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

