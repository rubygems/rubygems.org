class VersionSerializer < ApplicationSerializer
  attributes :authors,
    :built_at,
    :created_at,
    :description,
    :downloads_count,
    :metadata,
    :number,
    :summary,
    :platform,
    :rubygems_version,
    :ruby_version,
    :prerelease,
    :licenses,
    :requirements,
    :sha

  def rubygems_version
    object.required_rubygems_version
  end

  def ruby_version
    object.required_ruby_version
  end

  def sha
    object.sha256_hex
  end

  def to_xml(options = {})
    super(options.merge(root: 'version'))
  end
end
