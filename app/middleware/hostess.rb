class Hostess < Rack::Static
  def initialize(app, options={})
    options[:root] = Rails.root.join("server")
    options[:urls] = %w[/specs.4.8.gz
     /latest_specs.4.8.gz
     /prerelease_specs.4.8.gz
     /quick/rubygems-update-1.3.6.gemspec.rz
     /yaml.Z
     /yaml.z
     /Marshal.4.8.Z
     /quick/index.rz
     /quick/latest_index.rz
     /yaml
     /Marshal.4.8
     /specs.4.8
     /latest_specs.4.8
     /prerelease_specs.4.8
     /quick/index
     /quick/latest_index
    ]

    super(app, options)
  end

  def can_serve(path)
    super(path) || gem_download_path(path) || path =~ /\/quick\/Marshal\.4\.8\/.*\.gemspec.rz/
  end

  def gem_download_path(path)
    if path =~ /\/gems\/(.*)\.gem/
      $1
    end
  end

  def call(env)
    path = env['PATH_INFO']

    if path =~ /\/downloads\/(.*)\.gem/
      return [302, {'Location' => "/gems/#{$1}.gem"}, []]
    end

    if (full_name = gem_download_path(path)) &&
       name = Version.rubygem_name_for(full_name)
      Download.incr(name, full_name)
    end
    super
  end
end
