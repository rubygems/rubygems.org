require 'rubygems'
require 'sinatra'

class Hostess < Sinatra::Default
  set :app_file, __FILE__

  def serve(path, redirect = false)
    if Rails.env.production?
      if redirect
        redirect File.join("http://s3.amazonaws.com", VaultObject.current_bucket, request.path_info)
      else
        VaultObject.value(request.path_info)
      end
    else
      send_file(path)
    end
  end

  get "/specs.#{Gem.marshal_version}.gz" do
    content_type('application/x-gzip')
    serve(current_path)
  end

  get "/latest_specs.#{Gem.marshal_version}.gz" do
    content_type('application/x-gzip')
    serve(current_path)
  end

  get "/quick/Marshal.#{Gem.marshal_version}/*.gemspec.rz" do
    content_type('application/x-deflate')
    serve(current_path)
  end

  get "/gems/*.gem" do
    original_name = File.basename(current_path, ".gem").split('-')
    name = original_name[0..-2].join('-')
    version = original_name[-1]
    rubygem = Rubygem.find_by_name(name)

    if rubygem
      rubygem.increment!(:downloads)
      content_type('application/octet-stream')
      serve(current_path, true)
    else
      halt 404
    end
  end

  def current_path
    @current_path ||= Gemcutter.server_path(request.env["PATH_INFO"])
  end
end
