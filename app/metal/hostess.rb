require 'rubygems'
require 'sinatra'
require 'gemcutter'

class Hostess < Sinatra::Default
  set :app_file, __FILE__

  get "/latest_specs.#{Gem.marshal_version}.gz" do
    send_file(current_path)
  end

  get "/quick/Marshal.#{Gem.marshal_version}/*.gemspec.rz" do
    content_type 'application/x-deflate'
    send_file(current_path)
  end

  get "/gems/*.gem" do
    content_type 'application/octet-stream'
    send_file(current_path)
  end

  def current_path
    Gemcutter.server_path(request.env["PATH_INFO"])
  end
end
