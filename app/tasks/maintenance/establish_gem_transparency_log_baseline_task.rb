# frozen_string_literal: true

class Maintenance::EstablishGemTransparencyLogBaselineTask < MaintenanceTasks::Task
  include Maintenance::TransparencyLogBaseline

  def collection
    Rubygem.with_versions.order(:id)
  end

  def process(rubygem)
    resource = rubygem_resource(rubygem)
    baseline_event.record(
      event_type: "gem.baseline",
      subject_key: "rubygem:#{rubygem.id}",
      resource:,
      subject: resource
    )
  end
end
