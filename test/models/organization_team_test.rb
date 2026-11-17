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

      should allow_value("security").for(:handle)
      should allow_value("newsroom").for(:handle)

      %w[new edit create destroy index show update NEW].each do |reserved|
        should_not allow_value(reserved).for(:handle).with_message("is reserved and cannot be used")
      end

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
      should "be required by the database" do
        assert_raises(ActiveRecord::NotNullViolation) do
          OrganizationTeam.insert_all!([handle: "orphan", name: "Orphan Team", organization_id: nil])
        end
      end

      should "be required" do
        team = build(:organization_team, organization: nil)

        refute_predicate team, :valid?
        assert_contains team.errors[:organization], "must exist"
      end
    end
  end

  context "finding a team by handle" do
    setup do
      @organization = create(:organization)
      @team = create(:organization_team, organization: @organization, handle: "core")
      @other_team = create(:organization_team, handle: "other")
    end

    should "find a team in the organization case-insensitively" do
      assert_equal @team, @organization.organization_teams.find_by_case_insensitive_handle!("CORE")
    end

    should "not find another organization's team" do
      assert_raises(ActiveRecord::RecordNotFound) do
        @organization.organization_teams.find_by_case_insensitive_handle!("other")
      end
    end

    should "only be available through an organization" do
      refute_respond_to OrganizationTeam, :find_by_case_insensitive_handle!
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

    should "not save or record an event for a team that already exists" do
      team = create(:organization_team, organization: @organization, handle: "core")
      team.name = "Renamed Team"

      assert_no_difference -> { Events::OrganizationEvent.count } do
        refute team.save_with_creation_event(actor: @actor)
      end

      assert_equal "core", team.reload.handle
      refute_equal "Renamed Team", team.name
    end

    should "not save the team when the event cannot be recorded" do
      team = @organization.organization_teams.build(handle: "core", name: "Core Team")
      @organization.stubs(:record_event!).raises(ActiveRecord::RecordInvalid)

      assert_no_difference -> { OrganizationTeam.count } do
        assert_raises(ActiveRecord::RecordInvalid) { team.save_with_creation_event(actor: @actor) }
      end
    end
  end

  context "members" do
    setup do
      @team = create(:organization_team)
      @organization = @team.organization
    end

    should "list memberships in the order they were added" do
      carol, alice, bob = %w[carol alice bob].map do |handle|
        create(:membership, organization: @organization, user: create(:user, handle:))
      end
      [carol, alice, bob].each do |membership|
        travel 1.minute
        @team.team_memberships.create!(membership:)
      end

      assert_equal [carol, alice, bob], @team.reload.memberships.to_a
    end

    should "remove team rows when the membership is destroyed" do
      team_membership = create(:organization_team_membership, organization_team: @team)

      assert_difference -> { OrganizationTeamMembership.count }, -1 do
        team_membership.membership.destroy!
      end
    end

    context "#addable_memberships" do
      should "include confirmed members not on the team, ordered by handle" do
        zed = create(:membership, organization: @organization, user: create(:user, handle: "zed"))
        amy = create(:membership, organization: @organization, user: create(:user, handle: "amy"))

        assert_equal [amy, zed], @team.addable_memberships.to_a
      end

      should "exclude members already on the team, pending members, and other organizations' members" do
        on_team = create(:organization_team_membership, organization_team: @team).membership
        create(:membership, :pending, organization: @organization)
        create(:membership)
        addable = create(:membership, organization: @organization)

        assert_equal [addable], @team.addable_memberships.to_a
        refute_includes @team.addable_memberships, on_team
      end
    end
  end

  should "have a valid factory" do
    assert_predicate build(:organization_team), :valid?
  end
end
