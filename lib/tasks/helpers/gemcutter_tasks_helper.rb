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
    metadata = get_spec_attribute(version.full_name, "metadata")
    version.update(metadata: metadata || {})
  end

  def assign_required_ruby_version!(version)
    required_ruby_version = get_spec_attribute(version.full_name, "required_ruby_version")

    return if required_ruby_version.nil? || required_ruby_version.to_s == ">= 0"
    Rails.logger.info("[gemcutter:required_ruby_version:backfill] updating version: #{version.full_name} " \
                      "with required_ruby_version: #{required_ruby_version}")

    version.update_column(:required_ruby_version, required_ruby_version.to_s)
    CompactIndexTasksHelper.update_last_checksum(version.rubygem, "gemcutter:required_ruby_version:backfill")
  end

  def get_spec_attribute(version_full_name, attribute_name)
    key = "quick/Marshal.4.8/#{version_full_name}.gemspec.rz"
    file = RubygemFs.instance.get(key)
    return nil unless file
    spec = Marshal.load(Gem::Util.inflate(file))
    spec.send(attribute_name)
  rescue StandardError => e
    Rails.logger.info("[gemcutter:required_ruby_version:backfill] could not get required_ruby_version for version: #{version_full_name} " \
                      "error: #{e.inspect}")
    nil
  end
end
