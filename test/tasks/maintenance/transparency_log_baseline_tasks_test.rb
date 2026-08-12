# frozen_string_literal: true

require "test_helper"

class Maintenance::TransparencyLogBaselineTasksTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "requires one valid baseline ID and cutoff for every task" do
    task_classes.each do |task_class|
      assert_predicate build_transparency_log_baseline_task(task_class), :valid?
      refute_predicate build_transparency_log_baseline_task(task_class, baseline_id: "not-a-uuid"), :valid?
      refute_predicate build_transparency_log_baseline_task(task_class, observed_at: nil), :valid?
    end
  end

  test "gem task includes active gems and excludes completely yanked gems" do
    active_gem = create(:rubygem)
    create(:version, rubygem: active_gem)
    yanked_gem = create(:rubygem)
    create(:version, :yanked, rubygem: yanked_gem)
    baseline_task = build_transparency_log_baseline_task(Maintenance::EstablishGemTransparencyLogBaselineTask)

    assert_includes baseline_task.collection, active_gem
    refute_includes baseline_task.collection, yanked_gem

    baseline_task.process(active_gem)
    event = TransparencyLogEvent.find_by!(event_type: "gem.baseline")

    assert_equal active_gem.name, event.resource_name
    assert_equal active_gem.id.to_s, event.resource_id
    assert_equal event.resource_name, event.subject_name
  end

  test "version task records indexed and yanked versions of an active gem" do
    rubygem = create(:rubygem)
    indexed = create(:version, rubygem:, number: "2.0.0")
    yanked = create(:version, :yanked, rubygem:, number: "1.0.0")
    baseline_task = build_transparency_log_baseline_task(Maintenance::EstablishGemVersionTransparencyLogBaselineTask)

    assert_equal [indexed, yanked].sort_by(&:id), baseline_task.collection.where(id: [indexed.id, yanked.id]).to_a

    baseline_task.process(indexed)
    baseline_task.process(yanked)

    states = TransparencyLogEvent.of_event_type("gem.version.baseline").order(:subject_id).pluck(:payload_attributes)

    assert_equal %w[indexed yanked], states.map { |attributes| attributes.fetch("state") }.sort
  end

  test "version task excludes every version of a completely yanked gem" do
    rubygem = create(:rubygem)
    version = create(:version, :yanked, rubygem:)

    refute_includes build_transparency_log_baseline_task(Maintenance::EstablishGemVersionTransparencyLogBaselineTask).collection, version
  end

  test "ownership task records confirmed users and organization ownership without private roles or memberships" do
    rubygem = create(:rubygem)
    create(:version, rubygem:)
    owner = create(:user)
    confirmed = create(:ownership, :maintainer, rubygem:, user: owner)
    create(:ownership, :unconfirmed, rubygem:)
    organization = create(:organization)
    rubygem.update!(organization:)

    build_transparency_log_baseline_task(Maintenance::EstablishGemOwnershipTransparencyLogBaselineTask).process(rubygem)

    events = TransparencyLogEvent.of_event_type("gem.ownership.baseline").order(:subject_type)

    assert_equal %w[organization user], events.pluck(:subject_type)
    assert_equal [organization.id.to_s, confirmed.user_id.to_s].sort, events.pluck(:subject_id).sort

    serialized_payloads = events.pluck(:canonical_payload).to_json

    refute_includes serialized_payloads, confirmed.role
    refute_includes serialized_payloads, "membership"
  end

  test "organization task only records organizations owning active gems" do
    active_organization = create(:organization)
    active_gem = create(:rubygem, organization: active_organization)
    create(:version, rubygem: active_gem)
    inactive_organization = create(:organization)
    inactive_gem = create(:rubygem, organization: inactive_organization)
    create(:version, :yanked, rubygem: inactive_gem)
    baseline_task = build_transparency_log_baseline_task(Maintenance::EstablishOrganizationTransparencyLogBaselineTask)

    assert_includes baseline_task.collection, active_organization
    refute_includes baseline_task.collection, inactive_organization

    baseline_task.process(active_organization)
    event = TransparencyLogEvent.find_by!(event_type: "organization.baseline")

    assert_equal active_organization.handle, event.subject_handle
    assert_equal({ "name" => active_organization.name }, event.payload_attributes)
  end

  test "task retries do not enqueue or duplicate baseline events" do
    rubygem = create(:rubygem)
    create(:version, rubygem:)
    baseline_task = build_transparency_log_baseline_task(Maintenance::EstablishGemTransparencyLogBaselineTask)

    assert_no_enqueued_jobs only: ProcessTransparencyLogEventJob do
      baseline_task.process(rubygem)
      baseline_task.process(rubygem)
    end

    assert_equal 1, TransparencyLogEvent.of_event_type("gem.baseline").count
  end

  private

  def task_classes
    [
      Maintenance::EstablishGemTransparencyLogBaselineTask,
      Maintenance::EstablishGemVersionTransparencyLogBaselineTask,
      Maintenance::EstablishGemOwnershipTransparencyLogBaselineTask,
      Maintenance::EstablishOrganizationTransparencyLogBaselineTask
    ]
  end
end
