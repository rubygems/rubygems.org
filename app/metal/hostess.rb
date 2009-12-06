class Hostess < Sinatra::Default
  cattr_writer :local

  def self.local
    @@local ||= false
  end

  def serve(redirect = false)
    if Hostess.local
      send_file(Gemcutter.server_path(request.path_info))
    else
      if redirect
        redirect VaultObject.url_for(request.path_info, :authenticated => false)
      else
        serve_via_s3
      end
    end
  end

  def serve_via_s3
    # Query S3
    begin
      result = VaultObject.value(request.path_info,
                                 :if_modified_since => env['HTTP_IF_MODIFIED_SINCE'],
                                 :if_none_match     => env['HTTP_IF_NONE_MATCH'])
    rescue AWS::S3::NoSuchKey
      not_found "This gemspec could not be found."
    end

    # These should raise a 304 if either of them match
    last_modified(result.response['last-modified']) if result.response['last-modified']

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

  %w[/specs.4.8.gz
     /latest_specs.4.8.gz
     /prerelease_specs.4.8.gz
  ].each do |index|
    get index do
      content_type('application/x-gzip')
      serve
    end
  end

  %w[/quick/Marshal.4.8/*.gemspec.rz
     /yaml.Z
     /Marshal.4.8.Z
  ].each do |deflated_index|
    get deflated_index do
      content_type('application/x-deflate')
      serve
    end
  end

  %w[/yaml
     /Marshal.4.8
     /specs.4.8
     /latest_specs.4.8
     /prerelease_specs.4.8
  ].each do |old_index|
    get old_index do
      serve
    end
  end

  get "/gems/*.gem" do
    unless ENV['MAINTENANCE_MODE']
      Delayed::Job.enqueue Download.new(:raw        => params[:splat].to_s,
                                        :created_at => Time.zone.now)
    end

    serve(true)
  end
end
