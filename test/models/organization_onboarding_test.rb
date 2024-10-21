require "test_helper"

class OrganizationOnboardingTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @maintainer = create(:user)
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])

    @onboarding = create(:organization_onboarding, created_by: @owner, invitees: { @maintainer.id => "maintainer" }, rubygems: [@rubygem.id])
  end

  context "validations" do
    setup do
      @onboarding = OrganizationOnboarding.new
    end

    should "require a onboarded by user" do
      assert_predicate @onboarding, :invalid?
      assert_equal ["must exist"], @onboarding.errors[:created_by]
    end

    context "when onbaording a user with an invalid role" do
      setup do
        @onboarding.invitees = { @maintainer.id => "invalid" }
      end

      should "raise an error" do
        assert_predicate @onboarding, :invalid?
        assert_equal ["Invalid Role 'invalid' for User #{@maintainer.id}"], @onboarding.errors[:invitees]
      end
    end

    context "when the user does not have the required gem roles" do
      setup do
        @onboarding.rubygems = [@rubygem.id]
        @onboarding.created_by = @maintainer
        @onboarding.invitees = { @owner.id => "owner" }
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["User does not have owner permissions for gem: #{@rubygem.name}"], @onboarding.errors[:rubygems]
      end
    end

    context "when the user specifies a gem they do not own" do
      setup do
        @rubygem = create(:rubygem)
        @onboarding.rubygems = [@rubygem.id]
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["User does not own gem: #{@rubygem.id}"], @onboarding.errors[:rubygems]
      end
    end
  end

  context "#onboard!" do
    setup do
      @onboarding.onboard!
    end

    should "mark the onboarding as completed" do
      assert_predicate @onboarding, :completed?
    end

    should "create an organization with the specified title and slug" do
      assert_not_nil @onboarding.organization
      assert_equal @onboarding.title, @onboarding.organization.name
      assert_equal @onboarding.slug, @onboarding.organization.handle
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
      team = @onboarding.organization.teams.find_by(slug: "default")

      assert_not_nil team
      assert_equal "Default", team.name
    end

    should "create team members for each invitee" do
      team = @onboarding.organization.teams.find_by(slug: "default")
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

  context "#avaliable_rubygems" do
    should "return the rubygems that the user owns" do
      assert_equal [@rubygem], @onboarding.avaliable_rubygems
    end
  end

  context "#avaliable_users" do
    should "return the users that share ownership with the set of avaliable rubygems" do
      assert_equal [@maintainer], @onboarding.avaliable_users
    end
  end
end
