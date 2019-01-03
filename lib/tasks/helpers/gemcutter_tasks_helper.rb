# frozen_string_literal: true

module GemcutterTaskshelper
  module_function

  def recalculate_sha256(version_full_name)
    key = "gems/#{version_full_name}.gem"
    file = RubygemFs.instance.get(key)
    Digest::SHA2.base64digest(file) if file
  end

  def recalculate_sha256!(version)
    sha256 = recalculate_sha256(version.full_name)
    version.update(sha256: sha256)
  end

  def recalculate_metadata!(version)
    metadata = get_spec_attribute(version.full_name, 'metadata')
    version.update(metadata: metadata || {})
  end

  def assign_required_rubygems_version!(version)
    required_rubygems_version = get_spec_attribute(version.full_name, 'required_rubygems_version')
    version.update_column(:required_rubygems_version, required_rubygems_version.to_s)
  end

  def get_spec_attribute(version_full_name, attribute_name)
    key = "gems/#{version_full_name}.gem"
    file = RubygemFs.instance.get(key)
    return nil unless file
    spec = Gem::Package.new(StringIO.new(file)).spec
    spec.send(attribute_name)
  rescue Gem::Package::FormatError
    nil
  end
end
