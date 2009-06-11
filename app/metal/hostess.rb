require 'rubygems'
require 'sinatra'

class Hostess < Sinatra::Default
  set :app_file, __FILE__

  get "/specs.#{Gem.marshal_version}.gz" do
    send_file(current_path)
  end

  get "/latest_specs.#{Gem.marshal_version}.gz" do
    send_file(current_path)
  end

  get "/quick/Marshal.#{Gem.marshal_version}/*.gemspec.rz" do
    content_type 'application/x-deflate'
    send_file(current_path)
  end

  get "/gems/*.gem" do
    if File.exists?(current_path)
      content_type 'application/octet-stream'
      original_name = File.basename(current_path, ".gem").split('-')
      name = original_name[0..-2].join('-')
      version = original_name[-1]
      rubygem = Rubygem.find_by_name(name)
      rubygem.increment!(:downloads)
      send_file(current_path)
    else
      halt 404
    end
  end

  def current_path
    @current_path ||= Gemcutter.server_path(request.env["PATH_INFO"])
  end
end
