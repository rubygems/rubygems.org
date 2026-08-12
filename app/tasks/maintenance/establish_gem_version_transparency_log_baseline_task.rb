# frozen_string_literal: true

class Maintenance::EstablishGemVersionTransparencyLogBaselineTask < MaintenanceTasks::Task
  include Maintenance::TransparencyLogBaseline

  def collection
    Version.includes(:rubygem).joins(:rubygem).merge(Rubygem.with_versions).order(:id)
  end

  def process(version)
    baseline_event.record(
      event_type: "gem.version.baseline",
      subject_key: "version:#{version.id}",
      resource: rubygem_resource(version.rubygem),
      subject: {
        type: "rubygem_version",
        name: version.full_name,
        id: version.id.to_s
      },
      payload_attributes: {
        "number" => version.number,
        "platform" => version.platform,
        "state" => version.indexed? ? "indexed" : "yanked"
      }
    )
  end
end
