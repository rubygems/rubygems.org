require "test_helper"

class OrganizationOnboardingTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @maintainer = create(:user)
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])

    @onboarding = create(
      :organization_onboarding,
      name_type: :user,
      organization_name: "Test Organization",
      organization_handle: @owner.handle,
      created_by: @owner,
      rubygems: [@rubygem.id]
    )
    maintainer_invite = @onboarding.invites.first
    maintainer_invite.update(role: :maintainer)
  end

  context "validations" do
    context "when the created_by field is blank" do
      setup do
        @onboarding.created_by = nil
      end

      should "require a onboarded by user" do
        assert_predicate @onboarding, :invalid?
        assert_equal ["must exist"], @onboarding.errors[:created_by]
      end
    end

    context "when the user does not have the required gem roles" do
      setup do
        @onboarding.rubygems = [@rubygem.id]
        @onboarding.created_by = @maintainer
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["must be an owner of the #{@rubygem.name} gem"], @onboarding.errors[:created_by]
      end
    end

    context "when the user specifies a gem they do not own" do
      setup do
        @other_user = create(:user)
        @rubygem = create(:rubygem, owners: [@other_user])
        @onboarding.rubygems = [@rubygem.id]
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["must be an owner of the #{@rubygem.name} gem"], @onboarding.errors[:created_by]
      end

      should "not add an invite for the users on the gem" do
        @onboarding.save
        @onboarding.reload

        assert @onboarding.invites.find_by(user_id: @other_user.id).nil?
      end
    end

    context "when the user specifices a user as the name of the organization" do
      setup do
        @onboarding.name_type = :user
      end

      context "when the name is a valid user" do
        setup do
          @onboarding.organization_handle = @owner.handle
        end

        should :be_valid
      end

      context "when the name is not valid" do
        setup do
          @onboarding.organization_handle = "invalid"
        end

        should :be_invalid
      end
    end

    context "when the user specifies a gem as the name of the organization" do
      setup do
        @onboarding.name_type = :gem
      end

      context "when the name is a valid gem that the user owns" do
        setup do
          @onboarding.organization_name = @rubygem.name
        end

        should :be_valid
      end

      context "when the name is not valid" do
        setup do
          @onboarding.organization_name = "invalid"
        end

        should :be_invalid
      end
    end
  end

  context "when assigning rubygems" do
    should "adds invites for the owners and maintainers of the specified rubygems" do
      @other_user = create(:user)
      @rubygem = create(:rubygem, owners: [@owner, @other_user])
      @onboarding.rubygems = [@rubygem.id]
      @onboarding.save
      @onboarding.reload

      assert_equal [@maintainer, @other_user].map(&:handle).sort, @onboarding.users.map(&:handle).sort
    end
  end

  context "#onboard!" do
    setup do
      @onboarding.onboard!
    end

    should "mark the onboarding as completed" do
      assert_predicate @onboarding, :completed?
    end

    should "create an organization with the specified name and handle" do
      assert_not_nil @onboarding.organization
      assert_equal @onboarding.organization_name, @onboarding.organization.name
      assert_equal @onboarding.organization_handle, @onboarding.organization.handle
    end

    should "create a confirmed owner membership for the person that onboarded the organization" do
      membership = @onboarding.organization.memberships.find_by(user_id: @onboarding.created_by)

      assert_predicate membership, :owner?
      assert_predicate membership, :confirmed?
    end

    should "create unconfirmed memberships for each invitee" do
      membership = @onboarding.organization.unconfirmed_memberships.find_by(user_id: @maintainer.id)

      assert_predicate membership, :maintainer?
      assert_not_predicate membership, :confirmed?
    end

    should "create a default team" do
      team = @onboarding.organization.teams.find_by(handle: "default")

      assert_not_nil team
      assert_equal "Default", team.name
    end

    should "create team members for each invitee" do
      team = @onboarding.organization.teams.find_by(handle: "default")
      owner_team_members = team.team_members.find_by(user_id: @owner.id)
      maintainer_team_member = team.team_members.find_by(user_id: @maintainer.id)

      assert_not_nil owner_team_members
      assert_not_nil maintainer_team_member
    end

    should "set the organization_id for each specified rubygem" do
      assert_equal @onboarding.organization.id, @rubygem.reload.organization_id
    end

    context "when onboarding encounters an error" do
      setup do
        @onboarding = create(:organization_onboarding, created_by: @owner)
        @onboarding.stubs(:create_organization!).raises(ActiveRecord::ActiveRecordError, "stubbed error")
        @onboarding.onboard!
      end

      should "mark the onboarding as failed" do
        assert_predicate @onboarding, :failed?
      end

      should "record the error message" do
        assert_equal "stubbed error", @onboarding.error
      end
    end

    context "when the onboarding is already completed" do
      setup do
        @onboarding = create(:organization_onboarding, :completed, created_by: @owner)
      end

      should "raise an error" do
        assert_raises StandardError, "onboard has already been completed" do
          @onboarding.onboard!
        end
      end
    end
  end

  context "#available_rubygems" do
    should "return the rubygems that the user owns" do
      assert_equal [@rubygem], @onboarding.available_rubygems
    end
  end
end
