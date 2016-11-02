class RubygemSerializer < ApplicationSerializer
  attributes :name,
    :downloads,
    :version,
    :version_downloads,
    :platform,
    :authors,
    :info,
    :licenses,
    :metadata,
    :sha,
    :project_uri,
    :gem_uri,
    :homepage_uri,
    :wiki_uri,
    :documentation_uri,
    :mailing_list_uri,
    :source_code_uri,
    :bug_tracker_uri,
    :dependencies

  delegate :platform, to: :instance_version
  delegate :authors,  to: :instance_version
  delegate :info,     to: :instance_version
  delegate :licenses, to: :instance_version
  delegate :metadata, to: :instance_version

  def version
    instance_version.number
  end

  def version_downloads
    instance_version.downloads_count
  end

  def sha
    instance_version.sha256_hex
  end

  def project_uri
    "#{protocol}://#{host_with_port}/gems/#{object.name}"
  end

  def gem_uri
    "#{protocol}://#{host_with_port}/gems/#{instance_version.full_name}.gem"
  end

  def homepage_uri
    object.linkset.try(:home)
  end

  def wiki_uri
    object.linkset.try(:wiki)
  end

  def documentation_uri
    object.linkset.try(:docs).presence || instance_version.documentation_path
  end

  def mailing_list_uri
    object.linkset.try(:mail)
  end

  def source_code_uri
    object.linkset.try(:code)
  end

  def bug_tracker_uri
    object.linkset.try(:bugs)
  end

  def dependencies
    {
      'development' => development_deps,
      'runtime'     => runtime_deps
    }
  end

  def to_xml(options = {})
    super(options.merge(root: 'rubygem'))
  end

  private

  def deps
    @deps ||= instance_version.dependencies.to_a
  end

  def development_deps
    serialize_dep 'development'
  end

  def runtime_deps
    serialize_dep 'runtime'
  end

  def serialize_dep(type)
    deps.map do |dep|
      DependencySerializer.new(dep).as_json if dep.rubygem && type == dep.scope
    end.compact
  end

  def instance_version
    return @instance_version if @instance_version

    @instance_version = if instance_options[:version]
                          instance_options[:version]
                        else
                          object.versions.most_recent
                        end
  end

  def protocol
    instance_options[:protocol] || Gemcutter::PROTOCOL
  end

  def host_with_port
    instance_options[:host_with_port] || Gemcutter::HOST
  end
end
