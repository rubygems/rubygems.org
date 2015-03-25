class Hostess < Sinatra::Base
  enable :raise_errors
  disable :show_exceptions

  set :protection, { :except => [:json_csrf] }

  cattr_writer :local

  def self.local
    @@local ||= false
  end

  def serve
    if self.class.local
      send_file(Pusher.server_path(request.path_info))
    else
      yield
    end
  end

  def serve_via_s3
    serve do
      redirect "http://#{Gemcutter.config['s3_domain']}#{request.path_info}"
    end
  end

  def serve_via_cf
    serve do
      redirect "http://#{Gemcutter.config['cf_domain']}#{request.path_info}"
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

  %w[/quick/rubygems-update-1.3.6.gemspec.rz
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

  get "/quick/Marshal.4.8/*.gemspec.rz" do
    if Version.rubygem_name_for(full_name)
      content_type('application/x-deflate')
      serve_via_cf
    else
      error 404, "This gem does not currently live at RubyGems.org."
    end
  end

  get "/gems/*.gem" do
    if name = Version.rubygem_name_for(full_name)
      Download.incr(name, full_name)
      serve_via_cf
    else
      error 404, "This gem does not currently live at RubyGems.org."
    end
  end

  get "/downloads/*.gem" do
    redirect "/gems/#{params[:splat].join}.gem"
  end

  def full_name
    @full_name ||= params[:splat].join.chomp('.gem')
  end
end
