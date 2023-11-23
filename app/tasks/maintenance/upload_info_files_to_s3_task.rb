# frozen_string_literal: true

class Maintenance::UploadInfoFilesToS3Task < MaintenanceTasks::Task
  def collection
    Rubygem.with_versions
  end

  def process(rubygem)
    UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)
  end
end
