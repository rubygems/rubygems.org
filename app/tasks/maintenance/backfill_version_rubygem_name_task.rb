# frozen_string_literal: true

class Maintenance::BackfillVersionRubygemNameTask < MaintenanceTasks::Task
  def collection
    Version.all.includes(:rubygem)
  end

  def process(version)
    return if version.rubygem_name.present?

    version.update!(rubygem_name: version.rubygem.name)
  end
end
