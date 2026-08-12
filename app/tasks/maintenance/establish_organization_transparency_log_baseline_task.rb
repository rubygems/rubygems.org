# frozen_string_literal: true

class Maintenance::EstablishOrganizationTransparencyLogBaselineTask < MaintenanceTasks::Task
  include Maintenance::TransparencyLogBaseline

  def collection
    Organization.joins(:rubygems).merge(Rubygem.with_versions).distinct.order(:id)
  end

  def process(organization)
    resource = {
      type: "organization",
      name: organization.handle,
      id: organization.id.to_s
    }
    baseline_event.record(
      event_type: "organization.baseline",
      subject_key: "organization:#{organization.id}",
      resource:,
      subject: resource.merge(handle: organization.handle),
      payload_attributes: { "name" => organization.name }
    )
  end
end
