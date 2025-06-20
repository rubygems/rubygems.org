require "test_helper"

class OrganizationOnboardingTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @owner = create(:user)
    @maintainer = create(:user)
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])

    @onboarding = create(
      :organization_onboarding,
      name_type: "gem",
      organization_name: "Test Organization",
      organization_handle: @rubygem.name,
      created_by: @owner,
      namesake_rubygem: @rubygem
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
        @other_rubygem = create(:rubygem, owners: [@other_user])
        @onboarding.rubygems = [@other_rubygem.id]
      end

      should "be invalid" do
        assert_predicate @onboarding, :invalid?
      end

      should "add an error to the rubygems attribute" do
        @onboarding.valid?

        assert_equal ["must be an owner of the #{@other_rubygem.name} gem"], @onboarding.errors[:created_by]
      end

      should "not add an invite for the users on the gem" do
        @onboarding.save
        @onboarding.reload

        assert_nil @onboarding.invites.find_by(user_id: @other_user.id)
      end
    end

    context "when the user specifices a user as the name of the organization" do
      setup do
        @onboarding.name_type = :user
      end

      should "set the Organization Onboarding handle to the handle of the User" do
        assert_equal @rubygem.name, @onboarding.organization_handle
      end
    end

    context "when the user specifies a gem as the name of the organization" do
      setup do
        @onboarding.name_type = :gem
      end

      context "when the name is a valid gem that the user owns" do
        should "be valid" do
          @onboarding.organization_handle = @rubygem.name

          assert_predicate @onboarding, :valid?
        end
      end

      context "when the name is not valid" do
        should "it is ignored and set to the gem name" do
          @onboarding.organization_handle = "invalid"

          assert_predicate @onboarding, :invalid?
        end
      end
    end
  end

  context "#set_user_handle" do
    context "when the gem name is set to user" do
      setup do
        @onboarding.name_type = :user
      end

      should "automatically set the organization handle to the handle of the user" do
        @onboarding.valid?

        assert_equal @owner.handle, @onboarding.organization_handle
      end
    end
  end

  context "#available_rubygems" do
    should "exclude gems that already have an organization" do
      create(:rubygem, owners: [@owner], organization: create(:organization))

      assert_equal [@rubygem], @onboarding.available_rubygems
    end
  end

  context "#rubygems=" do
    should "exclude gems that already have an organization" do
      other_rubygem = create(:rubygem, owners: [@owner], organization: create(:organization))
      @onboarding.rubygems = [@rubygem.id, other_rubygem.id]

      assert_equal [@rubygem.id], @onboarding.rubygems
    end

    should "add invites for the owners and maintainers of the specified rubygems" do
      other_user = create(:user)
      rubygem = create(:rubygem, owners: [@owner, other_user])
      @onboarding.rubygems = [rubygem.id]
      @onboarding.save
      @onboarding.reload

      assert_equal [@maintainer, other_user].map(&:handle).sort, @onboarding.users.map(&:handle).sort
    end
  end

  context "#invites_attributes=" do
    should "allow upding the role of an existing invite" do
      invite = @onboarding.invites.find_by(user_id: @maintainer.id)

      assert_equal "maintainer", invite.role

      @onboarding.invites_attributes = {
        "0" => { id: invite.id, role: "admin" }
      }

      @onboarding.save

      invite.reload

      assert_equal "admin", invite.role
    end

    should "prevent adding users that are not already invited" do
      other_user = create(:user)
      @onboarding.invites_attributes = {
        "0" => { user_id: other_user.id, role: "maintainer" }
      }

      assert_equal 1, @onboarding.invites.count
      assert_nil @onboarding.invites.find_by(user_id: other_user.id)
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

    should "set the organization_id for each specified rubygem" do
      assert_equal @onboarding.organization.id, @rubygem.reload.organization_id
    end

    should "remove Ownership records that have been migrated to Memberships" do
      assert_nil Ownership.find_by(user: @owner, rubygem: @rubygem)
      assert_nil Ownership.find_by(user: @maintainer, rubygem: @rubygem)
    end

    context "when a user is marked as an Outside Contributor" do
      setup do
        @contributor = create(:user)
        @ownership = create(:ownership, user: @contributor, rubygem: @rubygem, role: "owner")
        @onboarding.invites << create(:organization_onboarding_invite, user: @contributor, role: :outside_contributor)
      end

      should "not remove the Ownership record" do
        assert_not_nil Ownership.find_by(user: @contributor, rubygem: @rubygem)
      end
    end

    context "when onboarding encounters an error" do
      setup do
        @onboarding = create(:organization_onboarding, created_by: @owner)
        @onboarding.stubs(:create_organization!).raises(ActiveRecord::ActiveRecordError, "stubbed error")
      end

      should "mark the onboarding as failed" do
        assert_raises ActiveRecord::ActiveRecordError, "stubbed error" do
          @onboarding.onboard!
        end

        assert_predicate @onboarding, :failed?
      end

      should "record the error message" do
        assert_raises ActiveRecord::ActiveRecordError, "stubbed error" do
          @onboarding.onboard!
        end

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

  should "should schedule an email to be sent to each user that was onboarded" do
    @onboarding.onboard!

    assert_enqueued_jobs @onboarding.users.size
  end

  context "#available_rubygems" do
    should "return the rubygems that the user owns" do
      assert_equal [@rubygem], @onboarding.available_rubygems
    end
  end
end
