require 'sinatra'
class Hostess < Sinatra::Base
  cattr_writer :local

  def self.local
    @@local ||= false
  end

  def serve
    if Hostess.local
      send_file(Pusher.server_path(request.path_info))
    else
      yield
    end
  end

  def serve_via_s3
    serve do
      redirect VaultObject.s3_url_for(request.path_info)
    end
  end

  def serve_via_cf
    serve do
      redirect VaultObject.cf_url_for(request.path_info)
    end
  end

  %w[/specs.4.8.gz
     /latest_specs.4.8.gz
     /prerelease_specs.4.8.gz
  ].each do |index|
    get index do
      content_type('application/x-gzip')
      serve_via_s3
    end
  end

  %w[/quick/Marshal.4.8/*.gemspec.rz
     /quick/rubygems-update-1.3.6.gemspec.rz
     /yaml.Z
     /yaml.z
     /Marshal.4.8.Z
     /quick/index.rz
     /quick/latest_index.rz
  ].each do |deflated_index|
    get deflated_index do
      content_type('application/x-deflate')
      serve_via_s3
    end
  end

  %w[/yaml
     /Marshal.4.8
     /specs.4.8
     /latest_specs.4.8
     /prerelease_specs.4.8
     /quick/index
     /quick/latest_index
  ].each do |old_index|
    head old_index do
      "Please upgrade your RubyGems, it's quite old: http://rubygems.org/pages/download"
    end

    get old_index do
      serve_via_s3
    end
  end

  get "/gems/*.gem" do
    full_name = params[:splat].to_s.chomp(".gem")

    if Rails.env.maintenance?
      serve_via_cf
    else
      if version = Version.find_by_full_name(full_name)
        Download.incr(version)

        serve_via_cf
      else
        error 400, "This gem does not currently live at Gemcutter."
      end
    end
  end

  get "/downloads/*.gem" do
    redirect "/gems/#{params[:splat]}.gem"
  end
end
