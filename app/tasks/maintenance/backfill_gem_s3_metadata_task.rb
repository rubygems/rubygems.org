# frozen_string_literal: true

class Maintenance::BackfillGemS3MetadataTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  def collection
    Version.indexed.includes(:rubygem)
  end

  def process(version)
    sha256 = version.sha256

    gem_path = "gems/#{version.gem_file_name}"
    gem_contents, response = RubygemFs.instance.get_object(gem_path)

    if gem_contents.nil?
      logger.error("Version #{version.full_name} has no gem contents")
      return
    end

    actual_sha256 = Digest::SHA256.base64digest(gem_contents)
    # Validate the stored content matches the expected checksum
    if actual_sha256 != sha256
      logger.error("Version #{version.full_name} has sha256 mismatch", expected: sha256, actual: actual_sha256)
      return
    end

    existing_metadata = response[:metadata]
    new_metadata = {
      "gem" => version.rubygem.name, "version" => version.number, "platform" => version.platform,
      "surrogate-key" => "gem/#{version.rubygem.name}", "sha256" => sha256
    }

    if existing_metadata == new_metadata
      # No changes needed
    elsif existing_metadata <= new_metadata
      logger.info("Updating metadata for #{version.full_name}", existing_metadata: existing_metadata, new_metadata: new_metadata)
      RubygemFs.instance.store(gem_path, gem_contents, checksum_sha256: sha256, metadata: new_metadata)
    else
      logger.error("Version #{version.full_name} has unexpected metadata", existing_metadata:, new_metadata:)
    end
  end
end
