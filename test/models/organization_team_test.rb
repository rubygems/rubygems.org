# frozen_string_literal: true

require "test_helper"

class OrganizationTeamTest < ActiveSupport::TestCase
  should belong_to(:organization)

  context "validations" do
    context "handle" do
      should allow_value("CapsLOCK").for(:handle)
      should allow_value("1abcde").for(:handle)
      should allow_value("core-team_2").for(:handle)

      should_not allow_value(nil).for(:handle)
      should_not allow_value("").for(:handle)
      should_not allow_value("-leading-dash").for(:handle)
      should_not allow_value("abc^%def").for(:handle)
      should_not allow_value("has space").for(:handle)
      should_not allow_value("abc\n<script>bad").for(:handle)

      should "be between 2 and 40 characters" do
        team = build(:organization_team, handle: "a")

        refute_predicate team, :valid?
        assert_contains team.errors[:handle], "is too short (minimum is 2 characters)"

        team.handle = "a" * 41

        refute_predicate team, :valid?
        assert_contains team.errors[:handle], "is too long (maximum is 40 characters)"

        team.handle = "a" * 40
        team.valid?

        assert_empty team.errors[:handle]
      end

      should "be invalid with a duplicate handle (case insensitive) on create" do
        existing = create(:organization_team, handle: "core")
        team = build(:organization_team, organization: existing.organization, handle: "CORE")

        refute_predicate team, :valid?
        assert_contains team.errors[:handle], "has already been taken"
      end

      should "be invalid with a duplicate handle on update" do
        existing = create(:organization_team, handle: "core")
        team = create(:organization_team, organization: existing.organization, handle: "other")

        refute team.update(handle: "Core")
        assert_contains team.errors[:handle], "has already been taken"
        assert_equal "other", team.reload.handle
      end
    end

    context "name" do
      should allow_value("Core Team").for(:name)
      should allow_value("Release Managers & Friends!").for(:name)

      should_not allow_value(nil).for(:name)
      should_not allow_value("").for(:name)

      should "be between 2 and 255 characters" do
        team = build(:organization_team, name: "a")

        refute_predicate team, :valid?
        assert_contains team.errors[:name], "is too short (minimum is 2 characters)"

        team.name = "a" * 256

        refute_predicate team, :valid?
        assert_contains team.errors[:name], "is too long (maximum is 255 characters)"

        team.name = "a" * 255
        team.valid?

        assert_empty team.errors[:name]
      end
    end

    context "organization" do
      should "be required" do
        team = build(:organization_team, organization: nil)

        refute_predicate team, :valid?
        assert_contains team.errors[:organization], "must exist"
      end
    end
  end

  context "#save_with_creation_event" do
    setup do
      @organization = create(:organization)
      @actor = create(:user)
    end

    should "save the team and record a team created event" do
      team = @organization.organization_teams.build(handle: "core", name: "Core Team")

      assert_difference -> { @organization.events.where(tag: Events::OrganizationEvent::TEAM_CREATED).count }, 1 do
        assert team.save_with_creation_event(actor: @actor)
      end

      assert_predicate team, :persisted?
    end

    should "not record an event when the team is invalid" do
      team = @organization.organization_teams.build(handle: "has space", name: "Core Team")

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        refute team.save_with_creation_event(actor: @actor)
      end
    end

    should "not save the team when the event cannot be recorded" do
      team = @organization.organization_teams.build(handle: "core", name: "Core Team")
      @organization.stubs(:record_event!).raises(ActiveRecord::RecordInvalid)

      assert_no_difference -> { OrganizationTeam.count } do
        assert_raises(ActiveRecord::RecordInvalid) { team.save_with_creation_event(actor: @actor) }
      end
    end
  end

  should "have a valid factory" do
    assert_predicate build(:organization_team), :valid?
  end
end
