# frozen_string_literal: true

class Maintenance::EstablishGemOwnershipTransparencyLogBaselineTask < MaintenanceTasks::Task
  include Maintenance::TransparencyLogBaseline

  def collection
    Rubygem.with_versions.includes(:organization, ownerships: :user).order(:id)
  end

  def process(rubygem)
    resource = rubygem_resource(rubygem)
    rubygem.ownerships.each do |ownership|
      user = ownership.user
      record_ownership(
        rubygem:,
        resource:,
        principal_key: "user:#{user.id}",
        subject: { type: "user", name: user.display_handle, id: user.id.to_s, handle: user.display_handle }
      )
    end

    return unless rubygem.organization

    organization = rubygem.organization
    record_ownership(
      rubygem:,
      resource:,
      principal_key: "organization:#{organization.id}",
      subject: { type: "organization", name: organization.handle, id: organization.id.to_s, handle: organization.handle }
    )
  end

  private

  def record_ownership(rubygem:, resource:, principal_key:, subject:)
    baseline_event.record(
      event_type: "gem.ownership.baseline",
      subject_key: "rubygem:#{rubygem.id}:#{principal_key}",
      resource:,
      subject:
    )
  end
end
