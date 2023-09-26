# frozen_string_literal: true

class Maintenance::BackfillGemPlatformToVersionsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  FULL_NAME_ATTRIBUTES = %i[full_name gem_full_name].freeze

  def collection
    Version.includes(:rubygem).where(gem_platform: nil)
  end

  def process(version)
    platform = Gem::Platform.new(version.platform)
    version.update!(gem_platform: platform.to_s)
  rescue ActiveRecord::RecordInvalid => e
    if e.record.errors.errors.all? { |error| FULL_NAME_ATTRIBUTES.include?(error.attribute) && error.type == :taken }
      version.save!(validate: false)
      logger.warn "Version #{version.full_name} failed validation setting gem_platform to #{platform.to_s.inspect} but was saved without validation",
                  error: e
    else
      logger.error "Version #{version.full_name} failed validation setting gem_platform to #{platform.to_s.inspect}", error: e
    end
  end
end
