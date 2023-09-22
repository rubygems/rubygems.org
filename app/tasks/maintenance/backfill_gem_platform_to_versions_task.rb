# frozen_string_literal: true

class Maintenance::BackfillGemPlatformToVersionsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  FULL_NAME_ATTRIBUTES = %i[full_name gem_full_name].freeze

  def collection
    Version.where(gem_platform: nil)
  end

  def process(element)
    platform = Gem::Platform.new(element.platform)
    element.update!(gem_platform: platform.to_s)
  rescue ActiveRecord::RecordInvalid => e
    if e.record.errors.errors.all? { |error| FULL_NAME_ATTRIBUTES.include?(error.attribute) && error.type == :taken }
      element.save!(validate: false)
      logger.warn "Version #{element.full_name} failed validation setting gem_platform to #{platform.to_s.inspect} but was saved without validation",
                  error: e
    else
      logger.error "Version #{element.full_name} failed validation setting gem_platform to #{platform.to_s.inspect}", error: e
    end
  end
end
