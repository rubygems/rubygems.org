require 'rubygems'
require 'sinatra'

class Hostess < Sinatra::Default
  set :app_file, __FILE__

  def serve(path, redirect = false)
    headers "Cache-Control" => "public, max-age=60"

    if Rails.env.development? || Rails.env.test?
      send_file(path)
    else
      if redirect
        redirect File.join("http://s3.amazonaws.com", VaultObject.current_bucket, request.path_info)
      else
        # Query S3
        result = VaultObject.value(request.path_info,
                                    :if_modified_since => env['HTTP_IF_MODIFIED_SINCE'],
                                    :if_none_match => env['HTTP_IF_NONE_MATCH'])

        # These should raise a 304 if either of them match
        if result.response['last-modified']
          last_modified(result.response['last-modified'])
        end

        if value = result.response['etag']
          response['ETag'] = value

          # Conditional GET check
          if etags = env['HTTP_IF_NONE_MATCH']
            etags = etags.split(/\s*,\s*/)
            halt 304 if etags.include?(value) || etags.include?('*')
          end
        end

        # If we got a 304 back, let's give it back to the client
        halt 304 if result.response.code == 304

        # Otherwise return the result back
        result
      end
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

  get "/prerelease_specs.#{Gem.marshal_version}.gz" do
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
