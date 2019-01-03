# frozen_string_literal: true

class Hostess < Rack::Static
  def initialize(app, options = {})
    options[:root] = RubygemFs.instance.base_dir

    options[:urls] = %w[
      /specs.4.8.gz
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
    super(path) || gem_download_path(path) || path =~ %r{/quick/Marshal\.4\.8/.*\.gemspec.rz}
  end

  def gem_download_path(path)
    Regexp.last_match(1) if path =~ %r{/gems/(.*)\.gem}
  end

  def call(env)
    path = env['PATH_INFO']

    return [302, { 'Location' => "/gems/#{Regexp.last_match(1)}.gem" }, []] if path =~ %r{/downloads/(.*)\.gem}

    download_path = gem_download_path(path)
    name = Version.rubygem_name_for(download_path) if download_path
    if name
      GemDownload.transaction do
        GemDownload.bulk_update([[download_path, 1]])
      end
    end
    super
  end
end
