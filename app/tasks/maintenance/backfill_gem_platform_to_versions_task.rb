# frozen_string_literal: true

class Maintenance::BackfillGemPlatformToVersionsTask < MaintenanceTasks::Task
  def collection
    Version.where(gem_platform: nil)
  end

  def process(element)
    platform = Gem::Platform.new(element.platform)
    element.update!(gem_platform: platform.to_s)
  end
end
