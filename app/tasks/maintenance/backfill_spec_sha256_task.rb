# frozen_string_literal: true

class Maintenance::BackfillSpecSha256Task < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  def collection
    Version.indexed.where(spec_sha256: nil)
  end

  def process(version)
    logger.tagged(version_id: version.id, name: version.rubygem.name, number: version.number, platform: version.platform) do
      logger.info "Updating spec_sha256 for #{version.full_name}"

      spec_path = "quick/Marshal.4.8/#{version.full_name}.gemspec.rz"
      spec_contents = RubygemFs.instance.get(spec_path)

      raise "#{spec_path} is missing" if spec_contents.nil?

      spec_sha256 = Digest::SHA2.base64digest(spec_contents)

      logger.info "Updating spec_sha256 for #{version.full_name} to #{spec_sha256}"

      version.transaction do
        if version.reload.spec_sha256.present?
          if spec_sha256 != version.spec_sha256
            raise "Version #{version.full_name} has incorrect spec_sha256 (expected #{version.spec_sha256}, got #{spec_sha256})"
          end
        else
          version.update!(spec_sha256: spec_sha256)
        end
      end
    end
  end
end
