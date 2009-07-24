require 'rubygems'
require 'sinatra'

class Hostess < Sinatra::Default
  set :app_file, __FILE__

  def serve(path, type = nil)
    if Rails.env.production?
      if type
        redirect File.join("http://s3.amazonaws.com", VaultObject.current_bucket, request.path)
      else
        VaultObject.value(request.path)
      end
    else
      content_type type if type
      send_file(path)
    end
  end

  get "/specs.#{Gem.marshal_version}.gz" do
    serve(current_path)
  end

  get "/latest_specs.#{Gem.marshal_version}.gz" do
    serve(current_path)
  end

  get "/quick/Marshal.#{Gem.marshal_version}/*.gemspec.rz" do
    serve(current_path)
  end

  get "/gems/*.gem" do
    original_name = File.basename(current_path, ".gem").split('-')
    name = original_name[0..-2].join('-')
    version = original_name[-1]
    rubygem = Rubygem.find_by_name(name)

    if rubygem
      rubygem.increment!(:downloads)
      serve(current_path, 'application/octet-stream')
    else
      halt 404
    end
  end

  def current_path
    @current_path ||= Gemcutter.server_path(request.env["PATH_INFO"])
  end
end
