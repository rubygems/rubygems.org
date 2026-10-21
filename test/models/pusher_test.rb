# frozen_string_literal: true

require "test_helper"

class PusherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include GemspecYamlTemplateHelpers

  setup do
    @user = create(:user, email: "user@rubygems-test.org")
    @api_key = create(:api_key, owner: @user)
    @gem = gem_file
    @cutter = Pusher.new(@api_key, @gem)

    # Ensure we test #log_pushing
    @cutter.logger.level = :info
  end

  teardown do
    @gem&.close
  end

  context "creating a new gemcutter" do
    should "have some state" do
      assert_respond_to @cutter, :owner
      assert_respond_to @cutter, :version
      assert_respond_to @cutter, :version_id
      assert_respond_to @cutter, :spec
      assert_respond_to @cutter, :message
      assert_respond_to @cutter, :code
      assert_respond_to @cutter, :rubygem
      assert_respond_to @cutter, :body

      assert_equal @user, @cutter.owner
    end

    should "initialize size from the gem" do
      assert_equal @gem.size, @cutter.size
    end

    should "#inspect" do
      assert_equal "<Pusher @rubygem=nil @owner=#{@user.inspect} @message=nil @code=nil>",
                   @cutter.inspect
    end

    context "processing incoming gems" do
      should "work normally when things go well" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:verify_mfa_requirement).returns true
        @cutter.stubs(:verify_gem_scope).returns true
        @cutter.stubs(:validate).returns true
        @cutter.stubs(:verify_sigstore).returns true
        @cutter.stubs(:sign_sigstore).returns true
        @cutter.stubs(:save).returns true

        assert @cutter.process
      end

      should "not attempt to find rubygem if spec can't be pulled" do
        @cutter.stubs(:pull_spec).returns false
        @cutter.stubs(:find).never
        @cutter.stubs(:authorize).never
        @cutter.stubs(:verify_gem_scope).never
        @cutter.stubs(:verify_mfa_requirement).never
        @cutter.stubs(:save).never
        @cutter.process
      end

      should "not attempt to authorize if not found" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find)
        @cutter.stubs(:authorize).never
        @cutter.stubs(:verify_gem_scope).never
        @cutter.stubs(:verify_mfa_requirement).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to check gem scope if not authorized" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns false
        @cutter.stubs(:verify_gem_scope).never
        @cutter.stubs(:verify_mfa_requirement).never
        @cutter.stubs(:validate).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to check mfa requirement if scoped to another gem" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:verify_gem_scope).returns false
        @cutter.stubs(:verify_mfa_requirement).never
        @cutter.stubs(:validate).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to validate if mfa check failed" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:verify_gem_scope).returns true
        @cutter.stubs(:verify_mfa_requirement).returns false
        @cutter.stubs(:validate).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to save if not validated" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:verify_gem_scope).returns true
        @cutter.stubs(:verify_mfa_requirement).returns true
        @cutter.stubs(:validate).returns false
        @cutter.stubs(:save).never

        @cutter.process
      end
    end

    should "handle unexpected StandardError without leaking details" do
      GemValidator::Package.stubs(:validate).raises(RuntimeError, "unexpected internal error")
      @cutter = Pusher.new(@api_key, @gem)

      refute @cutter.pull_spec

      assert_includes @cutter.message, "RubyGems.org cannot process this gem"
      refute_includes @cutter.message, "Error:"
      refute_includes @cutter.message, "unexpected internal error"
      assert_equal 422, @cutter.code
    end
  end

  context "initialize new gem with find if one does not exist" do
    setup do
      spec = mock
      spec.expects(:name).returns "some name"
      spec.expects(:version).returns Gem::Version.new("1.3.3.7")
      spec.expects(:original_platform).returns "ruby"
      spec.expects(:platform).returns "ruby"
      spec.expects(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.default
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.stubs(:size).returns 5
      @cutter.stubs(:body).returns StringIO.new("dummy body")

      @cutter.find
    end

    should "set rubygem" do
      assert_equal "some name", @cutter.rubygem.name
    end

    should "set version" do
      assert_equal "1.3.3.7", @cutter.version.number
    end

    should "set platform" do
      assert_equal "ruby", @cutter.version.platform
    end

    should "set gem_platform" do
      assert_equal "ruby", @cutter.version.gem_platform
    end

    should "set gem version size" do
      assert_equal 5, @cutter.version.size
    end

    should "set sha256" do
      expected_sha = Digest::SHA2.base64digest(@cutter.body.string)

      assert_equal expected_sha, @cutter.version.sha256
    end
  end

  context "finding an existing gem" do
    should "bring up existing gem with matching spec" do
      @rubygem = create(:rubygem)
      spec = mock
      spec.stubs(:name).returns @rubygem.name
      spec.stubs(:version).returns Gem::Version.new("1.3.3.7")
      spec.stubs(:original_platform).returns "ruby"
      spec.stubs(:platform).returns "ruby"
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.default
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      spec.stubs(:metadata).returns({})
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.find

      assert_equal @rubygem, @cutter.rubygem
      refute_nil @cutter.version
    end

    should "error out when changing case with usuable versions" do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem)

      refute_equal @rubygem.name, @rubygem.name.upcase

      spec = mock
      spec.expects(:name).returns @rubygem.name.upcase
      spec.expects(:version).returns Gem::Version.new("1.3.3.7")
      spec.expects(:platform).returns "ruby"
      spec.expects(:original_platform).returns "ruby"
      spec.expects(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.default
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"

      refute @cutter.find

      assert_match(/Unable to change case/, @cutter.message)
    end

    should "update the DB to reflect the case in the spec" do
      @rubygem = create(:rubygem)

      refute_equal @rubygem.name, @rubygem.name.upcase

      spec = mock
      spec.stubs(:name).returns @rubygem.name.upcase
      spec.stubs(:version).returns Gem::Version.new("1.3.3.7")
      spec.stubs(:original_platform).returns "ruby"
      spec.stubs(:platform).returns "ruby"
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.default
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      spec.stubs(:metadata).returns({})
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.find

      @cutter.rubygem.save
      @rubygem.reload

      assert_equal @rubygem.name.upcase, @rubygem.name
    end

    should "find existing gem with matching version and different platform" do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem, number: "0.1.1")
      create(:version, rubygem: @rubygem, number: "0.1.1", platform: "java")

      spec = mock
      spec.stubs(:name).returns @rubygem.name
      spec.stubs(:version).returns Gem::Version.new("0.1.1")
      spec.stubs(:original_platform).returns "universal-darwin-6000"
      spec.stubs(:platform).returns Gem::Platform.new("universal-darwin-6000")
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.default
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"

      @cutter.find

      assert_equal @rubygem, @cutter.rubygem
      refute_nil @cutter.version

      assert_equal "universal-darwin-6000", @cutter.version.platform
      assert_equal "universal-darwin-6000", @cutter.version.gem_platform
    end

    should "initialize a new version but not set the Ruby ABI when the feature flag is off" do
      rubygem = create(:rubygem, name: "sandworm")

      spec = mock
      spec.stubs(:name).returns "sandworm"
      spec.stubs(:version).returns Gem::Version.new("1.0.0")
      spec.stubs(:original_platform).returns "arm64-darwin-25"
      spec.stubs(:platform).returns Gem::Platform.new("arm64-darwin-25")
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.new("~> 3.4.0")
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      spec.stubs(:metadata).returns({})

      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.stubs(:size).returns 5
      @cutter.stubs(:body).returns StringIO.new("dummy body")

      assert @cutter.find

      assert_equal rubygem, @cutter.rubygem
      refute_predicate @cutter.version, :persisted?
      assert_equal "1.0.0", @cutter.version.number
      assert_equal "arm64-darwin-25", @cutter.version.platform
      assert_equal "~> 3.4.0", @cutter.version.required_ruby_version
      assert_nil @cutter.version.ruby_abi
    end

    should "set Ruby ABI for a new version when the feature flag is on" do
      FeatureFlag.enable_for_actor(FeatureFlag::CONTENT_ADDRESSABLE_GEM_PUSHES, @user)
      rubygem = create(:rubygem, name: "sandworm")
      create(:version, rubygem: rubygem, number: "1.0.0", platform: "arm64-darwin-25",
        required_ruby_version: "~> 3.3.0", required_rubygems_version: Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION, ruby_abi: "3.3")

      spec = mock
      spec.stubs(:name).returns "sandworm"
      spec.stubs(:version).returns Gem::Version.new("1.0.0")
      spec.stubs(:original_platform).returns "arm64-darwin-25"
      spec.stubs(:platform).returns Gem::Platform.new("arm64-darwin-25")
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.new("~> 3.4.0")
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.new(Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION)
      spec.stubs(:metadata).returns({})

      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.stubs(:size).returns 5
      @cutter.stubs(:body).returns StringIO.new("dummy body")

      assert @cutter.find

      assert_equal rubygem, @cutter.rubygem
      refute_predicate @cutter.version, :persisted?
      assert_equal "1.0.0", @cutter.version.number
      assert_equal "arm64-darwin-25", @cutter.version.platform
      assert_equal "~> 3.4.0", @cutter.version.required_ruby_version
      assert_equal "3.4", @cutter.version.ruby_abi
    end

    should "not set Ruby ABI for gems without a platform even when the feature flag is on" do
      FeatureFlag.enable_for_actor(FeatureFlag::CONTENT_ADDRESSABLE_GEM_PUSHES, @user)
      create(:rubygem, name: "sandworm")

      spec = mock
      spec.stubs(:name).returns "sandworm"
      spec.stubs(:version).returns Gem::Version.new("1.0.0")
      spec.stubs(:original_platform).returns "ruby"
      spec.stubs(:platform).returns "ruby"
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.new("~> 3.4.0")
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.default
      spec.stubs(:metadata).returns({})

      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.stubs(:size).returns 5
      @cutter.stubs(:body).returns StringIO.new("dummy body")

      assert @cutter.find

      assert_equal "ruby", @cutter.version.platform
      assert_equal "~> 3.4.0", @cutter.version.required_ruby_version
      assert_nil @cutter.version.ruby_abi
    end

    should "reject a new version when the existing version has the same Ruby ABI" do
      FeatureFlag.enable_for_actor(FeatureFlag::CONTENT_ADDRESSABLE_GEM_PUSHES, @user)
      rubygem = create(:rubygem, name: "sandworm")
      create(:version, rubygem: rubygem, number: "1.0.0", platform: "arm64-darwin-25",
        required_ruby_version: "~> 3.4.0", required_rubygems_version: Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION, ruby_abi: "3.4")

      spec = mock
      spec.stubs(:name).returns "sandworm"
      spec.stubs(:version).returns Gem::Version.new("1.0.0")
      spec.stubs(:original_platform).returns "arm64-darwin-25"
      spec.stubs(:platform).returns Gem::Platform.new("arm64-darwin-25")
      spec.stubs(:cert_chain).returns nil
      spec.stubs(:required_ruby_version).returns Gem::Requirement.new("~> 3.4.0")
      spec.stubs(:required_rubygems_version).returns Gem::Requirement.new(Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION)
      spec.stubs(:metadata).returns({})

      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.stubs(:size).returns 5
      @cutter.stubs(:body).returns StringIO.new("dummy body")

      refute @cutter.find

      assert_equal 409, @cutter.code
      assert_match(/Repushing of gem versions is not allowed/, @cutter.message)
    end
  end

  context "validating uploaded spec content addressable attributes" do
    should "allow content-addressable versions whose uploaded spec keeps platform identity" do
      rubygem = create(:rubygem, name: "sandworm")
      version = create(
        :version,
        rubygem: rubygem,
        number: "1.0.0",
        platform: "arm64-darwin-25",
        gem_platform: "arm64-darwin-25",
        required_ruby_version: "~> 3.4.0",
        required_rubygems_version: Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION,
        ruby_abi: "3.4",
        sha256: Digest::SHA2.base64digest("sandworm-1.0.0-arm64-darwin-25-3.4")
      )
      spec = mock
      spec.stubs(:cert_chain).returns([])
      spec.stubs(:original_platform).returns("arm64-darwin-25")
      spec.stubs(:platform).returns Gem::Platform.new("arm64-darwin-25")

      @cutter.stubs(:rubygem).returns rubygem
      @cutter.stubs(:version).returns version
      @cutter.instance_variable_set(:@spec, spec)

      assert_predicate version, :content_addressable?
      assert @cutter.validate
    end
  end

  context "pushing a gem name covered by a prefix reservation" do
    setup do
      @organization = create(:organization, handle: "acme-corp")
      create(:membership, :admin, user: @user, organization: @organization)
      create(:prefix_reservation, organization: @organization, prefix: "acme")
    end

    should "let a member claim a new gem for the reserving organization" do
      cutter = push_gem_named("acme-widgets", organization_handle: @organization.handle)

      assert_predicate cutter, :process
      assert_equal @organization, Rubygem.find_by!(name: "acme-widgets").organization
    end

    should "let a trusted publisher claim a new gem for the reserving organization on behalf of a member" do
      pending_publisher = create(:oidc_pending_trusted_publisher, rubygem_name: "acme-widgets", user: @user)
      api_key = create(:api_key, owner: pending_publisher.trusted_publisher, scopes: %i[push_rubygem])
      cutter = push_gem_named("acme-widgets", organization_handle: @organization.handle, api_key:)

      assert_predicate cutter, :process
      assert_equal @organization, Rubygem.find_by!(name: "acme-widgets").organization
    end

    should "reject a member pushing a new gem without claiming the reserving organization" do
      cutter = push_gem_named("acme-widgets")

      assert_no_prefix_reserved_push cutter
      assert_includes cutter.message, 'add `spec.metadata["rubygems_organization"] = "acme-corp"` to your gemspec'
    end

    should "reject a new gem under the prefix of a deleted organization" do
      @organization.update!(deleted_at: Time.zone.now)
      cutter = push_gem_named("acme-widgets")

      assert_no_difference [-> { Rubygem.count }, -> { Version.count }, -> { Ownership.count }] do
        refute cutter.process
      end
      assert_equal 403, cutter.code
      assert_match(/'acme-widgets' starts with 'acme', a reserved prefix\./, cutter.message)
    end

    should "reject a member claiming a new gem for a different organization" do
      other_organization = create(:organization, handle: "other-org", owners: [@user])

      assert_no_prefix_reserved_push push_gem_named("acme-widgets", organization_handle: other_organization.handle)
      assert_empty other_organization.events.where(tag: Events::OrganizationEvent::RUBYGEM_ADDED)
    end

    should "reject a trusted publisher push that does not claim the reserving organization" do
      pending_publisher = create(:oidc_pending_trusted_publisher, rubygem_name: "acme-widgets", user: @user)
      api_key = create(:api_key, owner: pending_publisher.trusted_publisher, scopes: %i[push_rubygem])

      assert_no_prefix_reserved_push push_gem_named("acme-widgets", api_key:)
    end

    should "reject a non-member claiming a new gem for the reserving organization" do
      outsider = create(:user)
      cutter = push_gem_named("acme-widgets", organization_handle: @organization.handle, api_key: create(:api_key, owner: outsider))

      assert_no_difference -> { Rubygem.count } do
        refute cutter.process
      end
      assert_equal 403, cutter.code
      assert_equal "You do not have permission to add a gem to organization 'acme-corp'.", cutter.message
    end

    should "reject a non-member pushing a new gem without organization metadata" do
      assert_no_prefix_reserved_push push_gem_named("acme-widgets", api_key: create(:api_key, owner: create(:user)))
    end

    should "allow a gem that predates the reservation to push a new version" do
      @organization.prefix_reservations.destroy_all
      rubygem = create(:rubygem, name: "acme-legacy", owners: [@user])
      create(:version, rubygem: rubygem, number: "0.0.1")
      create(:prefix_reservation, organization: @organization, prefix: "acme")

      assert push_gem_named("acme-legacy", version: "0.0.2").process
    end

    context "with an abandoned gem that predates the reservation" do
      setup do
        @organization.prefix_reservations.destroy_all
        @previous_owner = create(:user)
        @abandoned = create(:rubygem, name: "acme-abandoned", owners: [@previous_owner])
        create(:version, :yanked, rubygem: @abandoned, number: "0.0.1")
        @abandoned.update_columns(created_at: 1.year.ago, updated_at: 1.year.ago)
        create(:prefix_reservation, organization: @organization, prefix: "acme")
      end

      should "reject a non-member reclaiming it" do
        cutter = push_gem_named("acme-abandoned", api_key: create(:api_key, owner: create(:user)))

        assert_no_difference [-> { Version.count }, -> { Ownership.count }, -> { Events::OrganizationEvent.count }] do
          refute cutter.process
        end
        assert_equal 403, cutter.code
        assert_match(/starts with 'acme', a prefix reserved by the acme-corp organization/, cutter.message)
        refute_includes cutter.message, "rubygems_organization"
        assert_equal [@previous_owner], @abandoned.reload.owners
      end

      # Takeover pushes ignore organization metadata, so even an admin of the
      # reserving organization can't claim the gem this way.
      should "reject an admin of the reserving organization reclaiming it" do
        assert_no_prefix_reserved_push push_gem_named("acme-abandoned", organization_handle: @organization.handle)
        assert_equal [@previous_owner], @abandoned.reload.owners
        assert_nil @abandoned.organization
      end

      should "reject a non-member reclaiming it when it already belongs to the reserving organization" do
        @abandoned.update_columns(organization_id: @organization.id)

        assert_no_prefix_reserved_push push_gem_named("acme-abandoned", api_key: create(:api_key, owner: create(:user)))
        assert_equal [@previous_owner], @abandoned.reload.owners
      end

      should "let the previous owner push a new version" do
        assert push_gem_named("acme-abandoned", api_key: create(:api_key, owner: @previous_owner)).process
      end
    end
  end

  context "checking if the rubygem can be pushed to" do
    setup do
      @cutter.stubs(:spec).returns stub(metadata: {})
    end

    should "be true if rubygem is new" do
      @cutter.stubs(:rubygem).returns Rubygem.new

      assert @cutter.authorize
    end

    should "be false if rubygem is new and api key has unexpected owner type" do
      @cutter.stubs(:rubygem).returns Rubygem.new

      owner = stub("owner", to_gid: nil)
      @api_key.update_columns(owner_id: 0, owner_type: "stub")
      @cutter.stubs(:owner).returns owner
      owner.expects(:owns_gem?).with(@cutter.rubygem).returns(false)

      refute @cutter.authorize
      assert_equal "You are not allowed to push this gem.",
        @cutter.message
      assert_equal 403, @cutter.code
    end

    context "with a existing rubygem" do
      setup do
        @rubygem = create(:rubygem, name: "the_gem_name")
        @cutter.stubs(:rubygem).returns @rubygem
      end

      should "be true if owned by the user" do
        create(:ownership, rubygem: @rubygem, user: @user)

        assert @cutter.authorize
      end

      should "be true if no versions exist since it's a dependency" do
        assert @cutter.authorize
      end

      should "be false if not owned by user and an indexed version exists" do
        create(:version, rubygem: @rubygem, number: "0.1.1")

        refute @cutter.authorize
        assert_equal "You do not have permission to push to this gem. " \
                     "Ask an owner to add you with: gem owner the_gem_name --add user@rubygems-test.org",
          @cutter.message
        assert_equal 403, @cutter.code
      end

      should "be false if api key has unexpected owner type" do
        owner = stub("owner", to_gid: nil)
        @api_key.update_columns(owner_id: 0, owner_type: "stub")
        @cutter.stubs(:owner).returns owner
        owner.expects(:owns_gem?).with(@rubygem).returns(false)

        refute @cutter.authorize
        assert_equal "You are not allowed to push this gem.",
          @cutter.message
        assert_equal 403, @cutter.code
      end

      should "be false if ownership is not confirmed" do
        create(:ownership, rubygem: @rubygem, user: @user, confirmed_at: nil)
        create(:version, rubygem: @rubygem, number: "0.1.1")

        refute @cutter.authorize
        assert_equal "You do not have permission to push to this gem. " \
                     "Please click the confirmation link we emailed you at #{@user.email} to verify ownership before pushing.",
          @cutter.message
        assert_equal 403, @cutter.code
      end

      should "be true if not owned by user but no indexed versions exist" do
        create(:version, :yanked, rubygem: @rubygem, number: "0.1.1")

        assert @cutter.authorize
      end

      should "be false if gem is pushable but is reserved" do
        create(:version, :yanked, rubygem: @rubygem, number: "0.1.1")
        create(:gem_name_reservation, name: @rubygem.name.downcase)

        refute @cutter.authorize
        assert_equal "This gem name is reserved. You are not allowed to push this gem.", @cutter.message
        assert_equal 403, @cutter.code
      end

      should "be false if gem is owned by user but is reserved" do
        create(:ownership, rubygem: @rubygem, user: @user)
        create(:gem_name_reservation, name: @rubygem.name.downcase)

        refute @cutter.authorize
        assert_equal "This gem name is reserved. You are not allowed to push this gem.", @cutter.message
        assert_equal 403, @cutter.code
      end

      context "version metadata has rubygems_mfa_required set" do
        setup do
          spec = mock
          spec.stubs(:metadata).returns({ "rubygems_mfa_required" => true })
          @cutter.stubs(:spec).returns spec

          metadata = { "rubygems_mfa_required" => "true" }
          create(:version, rubygem: @rubygem, number: "0.1.1", metadata: metadata)
        end

        should "be false if user has no mfa setup" do
          refute @cutter.verify_mfa_requirement
        end

        should "be true if user has ui_and_api mfa but API key does not require MFA" do
          @user.enable_totp!("abc123", User.mfa_levels["ui_and_api"])

          assert_predicate @cutter, :verify_mfa_requirement
        end

        should "be true if user has ui_only mfa but API key does not require MFA" do
          @user.enable_totp!("abc123", User.mfa_levels["ui_only"])

          assert_predicate @cutter, :verify_mfa_requirement
        end

        should "be true if user has ui_and_gem_signin mfa but API key does not require MFA" do
          @user.enable_totp!("abc123", User.mfa_levels["ui_and_gem_signin"])

          assert_predicate @cutter, :verify_mfa_requirement
        end
      end
    end
  end

  context "has a scoped gem" do
    setup do
      @rubygem = create(:rubygem)
    end

    should "pushes gem if scoped to the same gem" do
      create(:version, rubygem: @rubygem, number: "0.1.1", indexed: false)
      @api_key.ownership = create(:ownership, rubygem: @rubygem, user: @user)
      cutter = Pusher.new(@api_key, @gem)
      cutter.stubs(:rubygem).returns @rubygem

      assert cutter.verify_gem_scope
    end

    should "does not push gem if scoped to another gem" do
      create(:version, rubygem: @rubygem, number: "0.1.1", indexed: false)
      @api_key.ownership = create(:ownership, rubygem: create(:rubygem), user: @user)
      cutter = Pusher.new(@api_key, @gem)
      cutter.stubs(:rubygem).returns @rubygem

      refute cutter.verify_gem_scope
    end
  end

  test "rolls back disowning a fully yanked gem when creating the replacement owner fails" do
    previous_owner = create(:user)
    rubygem = create(:rubygem, name: "test", owners: [previous_owner])
    create(:version, :yanked, rubygem: rubygem, number: "0.1.0")
    ownership = rubygem.ownerships.sole
    scoped_key = create(:api_key, owner: previous_owner, ownership: ownership, scopes: %i[push_rubygem])
    original_event_ids = rubygem.events.ids

    invalid_ownership = Ownership.new
    invalid_ownership.errors.add(:base, "forced replacement failure")
    Ownership.stubs(:create_confirmed).raises(ActiveRecord::RecordInvalid.new(invalid_ownership))

    refute @cutter.process

    assert_equal [ownership.id], rubygem.ownerships_including_unconfirmed.ids
    refute_predicate scoped_key.reload, :soft_deleted?
    assert_equal ownership, scoped_key.ownership
    assert_equal original_event_ids, rubygem.events.ids
    assert_equal [["0.1.0", false]], rubygem.versions.pluck(:number, :indexed)
    refute_predicate rubygem.reload, :indexed?
  end

  context "when a fully yanked gem changes after a push is authorized" do
    setup do
      @previous_owner = create(:user)
      @rubygem = create(:rubygem, name: "revivable", owners: [@previous_owner])
      create(:version, :yanked, rubygem: @rubygem, number: "0.1.0")
    end

    should "reject a non-owner push once the owner has indexed a version" do
      cutter = authorized_pusher(@user, "9.9.9")
      create(:version, rubygem: @rubygem, number: "1.0.0")

      assert_push_rejected(cutter)
      assert_equal "You do not have permission to push to this gem. " \
                   "Ask an owner to add you with: gem owner revivable --add #{@user.email}", cutter.message
      assert_equal [@previous_owner], @rubygem.reload.owners
      assert_equal %w[1.0.0], @rubygem.versions.indexed.pluck(:number)
    end

    should "accept an owner push once another owner push has indexed a version" do
      cutter = authorized_pusher(@previous_owner, "2.0.0")
      create(:version, rubygem: @rubygem, number: "1.0.0")

      assert cutter.verify_gem_scope && cutter.verify_mfa_requirement && cutter.validate
      assert cutter.save

      assert_equal 200, cutter.code
      assert_equal [@previous_owner], @rubygem.reload.owners
      assert_equal %w[1.0.0 2.0.0], @rubygem.versions.indexed.pluck(:number).sort
    end

    should "reject a second non-owner push while the first push is still writing its gem" do
      second_user = create(:user)
      first = authorized_pusher(@user, "2.0.0")
      second = authorized_pusher(second_user, "3.0.0")

      assert first.verify_gem_scope && first.verify_mfa_requirement && first.validate
      assert first.send(:update)

      assert_push_rejected(second)
      assert_equal "You do not have permission to push to this gem. " \
                   "Ask an owner to add you with: gem owner revivable --add #{second_user.email}", second.message

      first.send(:write_gem, first.body, first.spec_contents)
      first.send(:after_write)

      assert_equal [@user], @rubygem.reload.owners
      assert_equal %w[2.0.0], @rubygem.versions.indexed.pluck(:number)
    end
  end

  context "with attestations" do
    should "not push gem if api key owner is not a trusted publisher" do
      @cutter.stubs(:attestations).returns([{}])

      refute @cutter.verify_sigstore
      assert_equal "Pushing with an attestation requires trusted publishing", @cutter.message
    end

    should "not push gem if attestation fails to validate" do
      @cutter.stubs(:attestations).returns(
        [
          "media_type" => Sigstore::BundleType::BUNDLE_0_3.media_type,
           "verification_material" => {
             "certificate" => {
               "rawBytes" => [build(:x509_certificate, :key_usage).to_der].pack("m0")
             },
             "tlogEntries" => [

               "inclusionProof" => {
                 "checkpoint" => { "envelope" => "" }
               },
                "canonicalizedBody" => [
                  JSON.dump(
                    spec: {
                      signature: {
                        content: {
                          publicKey: { content: [""].pack("m0") }
                        }
                      },
                      kind: "hashedrekord",
                      apiVersion: "0.0.1"
                    }
                  )
                ].pack("m0")

             ]
           },
           "message_signature" => {}
        ]
      )
      @api_key.owner = create(:oidc_trusted_publisher_github_action)
      @api_key.oidc_id_token = create(:oidc_id_token)

      @cutter.send(:sigstore_verifier).expects(:verify).with(input: anything, policy: anything, offline: true)
        .returns Sigstore::VerificationFailure.new("Attestation failed to validate")

      refute @cutter.verify_sigstore
      assert_equal "Attestation verification failed:\nAttestation failed to validate", @cutter.message
    end
  end

  context "claiming a new gem for an organization" do
    setup do
      @organization = create(:organization, handle: "org-example", owners: [@user])
    end

    should "create personal ownership when a new gem has no organization metadata" do
      cutter = push_gem_named("plain-new-gem")

      assert cutter.process
      rubygem = Rubygem.find_by!(name: "plain-new-gem")

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: @user), :exists?
      assert_empty rubygem.events.where(tag: Events::RubygemEvent::ORGANIZATION_ADDED)
    end

    should "create personal ownership when the pusher is not an organization member and metadata is absent" do
      guest = create(:user)
      api_key = create(:api_key, owner: guest)
      cutter = push_gem_named("guest-new-gem", api_key: api_key)

      assert cutter.process
      rubygem = Rubygem.find_by!(name: "guest-new-gem")

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: guest), :exists?
    end

    should "assign the gem to the organization for an owner without creating ownership" do
      cutter = push_gem_named("org-owned-gem", organization_handle: @organization.handle)

      assert cutter.process
      rubygem = Rubygem.find_by!(name: "org-owned-gem")

      assert_equal @organization, rubygem.organization
      assert_empty rubygem.ownerships
      assert rubygem.owned_by?(@user)
    end

    should "assign the gem to the organization for an admin without creating ownership" do
      admin = create(:user)
      create(:membership, :admin, user: admin, organization: @organization)
      api_key = create(:api_key, owner: admin)
      cutter = push_gem_named("org-admin-gem", organization_handle: @organization.handle, api_key: api_key)

      assert cutter.process
      rubygem = Rubygem.find_by!(name: "org-admin-gem")

      assert_equal @organization, rubygem.organization
      assert_empty rubygem.ownerships
      assert rubygem.owned_by?(admin)
      assert_organization_added_events rubygem, actor: admin
    end

    should "look up the organization handle case-insensitively" do
      cutter = push_gem_named("org-case-gem", organization_handle: @organization.handle.upcase)

      assert cutter.process
      rubygem = Rubygem.find_by!(name: "org-case-gem")

      assert_equal @organization, rubygem.organization
    end

    should "deny a maintainer and not create the gem" do
      maintainer = create(:user)
      create(:membership, :maintainer, user: maintainer, organization: @organization)
      api_key = create(:api_key, owner: maintainer)
      cutter = push_gem_named("org-maintainer-gem", organization_handle: @organization.handle, api_key: api_key)

      assert_new_gem_push_rejected cutter
      assert_equal "You do not have permission to add a gem to organization 'org-example'.", cutter.message
    end

    should "deny a non-member and not create the gem" do
      guest = create(:user)
      api_key = create(:api_key, owner: guest)
      cutter = push_gem_named("org-guest-gem", organization_handle: @organization.handle, api_key: api_key)

      assert_new_gem_push_rejected cutter
      assert_equal "You do not have permission to add a gem to organization 'org-example'.", cutter.message
    end

    should "deny an unconfirmed admin and not create the gem" do
      pending_admin = create(:user)
      create(:membership, :pending, :admin, user: pending_admin, organization: @organization)
      api_key = create(:api_key, owner: pending_admin)
      cutter = push_gem_named("org-pending-gem", organization_handle: @organization.handle, api_key: api_key)

      assert_new_gem_push_rejected cutter
    end

    should "return 404 when the organization handle does not exist" do
      cutter = push_gem_named("org-missing-gem", organization_handle: "no-such-org")

      assert_new_gem_push_rejected cutter, code: 404
      assert_equal "Could not find organization 'no-such-org'.", cutter.message
    end

    should "ignore organization metadata on an existing user-owned gem" do
      rubygem = create(:rubygem, name: "user-owned-gem", number: "1.0.0", owners: [@user])
      cutter = push_gem_named("user-owned-gem", version: "2.0.0", organization_handle: @organization.handle)

      assert cutter.process
      rubygem.reload

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: @user), :exists?
    end

    should "keep personal ownership when republishing a protected yanked gem for an organization the owner cannot add gems to" do
      rubygem = create(:rubygem, name: "protected-outsider-gem", owners: [@user])
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0")
      rubygem.update_columns(created_at: 60.days.ago)
      outsider_org = create(:organization, handle: "outsider-org")
      cutter = push_gem_named(rubygem.name, version: "2.0.0", organization_handle: outsider_org.handle)

      assert cutter.process
      rubygem.reload

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: @user), :exists?
      assert rubygem.versions.indexed.find_by(number: "2.0.0")
    end

    should "keep personal ownership when republishing a protected yanked gem for an organization the owner is admin" do
      rubygem = create(:rubygem, name: "protected-admin-gem", owners: [@user])
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0")
      rubygem.update_columns(created_at: 60.days.ago)
      cutter = push_gem_named(rubygem.name, version: "2.0.0", organization_handle: @organization.handle)

      assert cutter.process
      rubygem.reload

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: @user), :exists?
      assert rubygem.versions.indexed.find_by(number: "2.0.0")
    end

    should "ignore organization metadata on an existing organization-owned gem" do
      rubygem = create(:rubygem, name: "already-org-gem", number: "1.0.0")
      @organization.rubygems << rubygem
      other_organization = create(:organization, owners: [@user], handle: "other-org")
      cutter = push_gem_named("already-org-gem", version: "2.0.0", organization_handle: other_organization.handle)

      assert cutter.process

      assert_equal @organization, rubygem.reload.organization
    end

    should "deny a non-member pushing an existing organization-owned gem even with metadata" do
      rubygem = create(:rubygem, name: "org-member-only", number: "1.0.0")
      @organization.rubygems << rubygem
      guest = create(:user)
      api_key = create(:api_key, owner: guest)

      assert_no_difference "Version.count" do
        cutter = push_gem_named("org-member-only", version: "2.0.0", organization_handle: @organization.handle, api_key: api_key)

        refute cutter.process
        assert_equal 403, cutter.code
      end

      assert_equal @organization, rubygem.reload.organization
    end

    should "ignore organization metadata when an organization admin takes over an unprotected yanked gem" do
      admin = create(:user)
      create(:membership, :admin, user: admin, organization: @organization)
      api_key = create(:api_key, owner: admin)
      rubygem = create(:rubygem, name: "abandoned-yanked-gem", owners: [@user])
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0")
      rubygem.update_columns(created_at: 200.days.ago, updated_at: 101.days.ago)

      cutter = push_gem_named(rubygem.name, version: "2.0.0", organization_handle: @organization.handle, api_key:)

      assert cutter.process
      rubygem.reload

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: admin), :exists?
      refute_predicate rubygem.ownerships.where(user: @user), :exists?
      assert_empty rubygem.events.where(tag: Events::RubygemEvent::ORGANIZATION_ADDED)
      assert_empty @organization.events.where(tag: Events::OrganizationEvent::RUBYGEM_ADDED)
    end

    should "ignore organization metadata when the owner republishes a recently created fully yanked gem" do
      rubygem = create(:rubygem, name: "recent-yanked-gem", owners: [@user])
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0")

      cutter = push_gem_named(rubygem.name, version: "2.0.0", organization_handle: @organization.handle)

      assert cutter.process
      rubygem.reload

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: @user), :exists?
    end

    should "ignore organization metadata when a non-member takes over an unprotected yanked gem" do
      guest = create(:user)
      api_key = create(:api_key, owner: guest)
      rubygem = create(:rubygem, name: "guest-yanked-gem", owners: [@user])
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0")
      rubygem.update_columns(created_at: 200.days.ago, updated_at: 101.days.ago)

      cutter = push_gem_named(rubygem.name, version: "2.0.0", organization_handle: @organization.handle, api_key:)

      assert cutter.process
      rubygem.reload

      assert_nil rubygem.organization
      assert_predicate rubygem.ownerships.where(user: guest), :exists?
      assert_empty @organization.rubygems
    end

    should "assign the gem to the organization for a pending trusted publisher without creating ownership" do
      pending_publisher = create(:oidc_pending_trusted_publisher, rubygem_name: "trusted-org-gem", user: @user)
      api_key = create(:api_key, owner: pending_publisher.trusted_publisher, scopes: %i[push_rubygem])
      cutter = push_gem_named("trusted-org-gem", organization_handle: @organization.handle, api_key: api_key)

      assert cutter.process
      rubygem = Rubygem.find_by!(name: "trusted-org-gem")

      assert_equal @organization, rubygem.organization
      assert_empty rubygem.ownerships
      assert rubygem.oidc_rubygem_trusted_publishers.exists?(trusted_publisher: pending_publisher.trusted_publisher)
      assert rubygem.owned_by?(@user)
      assert_organization_added_events rubygem, actor: @user
    end

    %w[revoked expired].product(%w[personal organization]).each do |state, ownership|
      should "reject a pending trusted publisher #{state} during a first push for #{ownership} ownership" do
        name = "#{state}-#{ownership}-gem"
        pending_publisher = create(:oidc_pending_trusted_publisher, rubygem_name: name, user: @user)
        api_key = create(:api_key, owner: pending_publisher.trusted_publisher, scopes: %i[push_rubygem])
        organization_handle = @organization.handle if ownership == "organization"
        cutter = push_gem_named(name, organization_handle:, api_key:)
        change = state == "revoked" ? -> { pending_publisher.destroy! } : -> { travel_to(pending_publisher.expires_at + 1.second) }
        validate = cutter.method(:validate)
        # Change the registration after real validation, before transactional authorization.
        cutter.define_singleton_method(:validate) { validate.call.tap { change.call } }

        assert_new_gem_push_rejected cutter
        assert_equal "You are not allowed to push this gem.", cutter.message
      end
    end

    should "deny a pending trusted publisher whose user cannot add gems to the organization" do
      maintainer = create(:user)
      create(:membership, :maintainer, user: maintainer, organization: @organization)
      pending_publisher = create(:oidc_pending_trusted_publisher, rubygem_name: "trusted-maintainer-gem", user: maintainer)
      api_key = create(:api_key, owner: pending_publisher.trusted_publisher, scopes: %i[push_rubygem])
      cutter = push_gem_named("trusted-maintainer-gem", organization_handle: @organization.handle, api_key: api_key)

      assert_new_gem_push_rejected cutter
      assert_equal "You do not have permission to add a gem to organization 'org-example'.", cutter.message
    end
  end

  private

  def authorized_pusher(user, number)
    cutter = Pusher.new(create(:api_key, owner: user), build_gem(new_gemspec(@rubygem.name, number, "Gemcutter", "ruby")))

    assert cutter.pull_spec && cutter.find
    assert cutter.authorize, "expected #{user.handle} to be allowed to push #{@rubygem.name}"
    cutter
  end

  def gem_state(rubygem)
    {
      versions: rubygem.versions.order(:id).pluck(:id, :indexed),
      ownerships: rubygem.ownerships_including_unconfirmed.order(:id).pluck(:id, :user_id),
      trusted_publishers: rubygem.oidc_rubygem_trusted_publishers.ids,
      events: rubygem.events.ids
    }
  end

  def assert_push_rejected(cutter)
    assert cutter.verify_gem_scope && cutter.verify_mfa_requirement && cutter.validate

    assert_no_changes -> { gem_state(cutter.rubygem) } do
      assert_no_enqueued_jobs { refute cutter.save }
    end
    assert_equal 403, cutter.code
    refute Version.exists?(full_name: cutter.version.full_name)
    assert_nil RubygemFs.instance.get("gems/#{cutter.version.gem_file_name}")
    assert_nil RubygemFs.instance.get("quick/Marshal.4.8/#{cutter.version.full_name}.gemspec.rz")
  end

  def assert_new_gem_push_rejected(cutter, code: 403)
    assert_no_difference %w[Rubygem.count Ownership.count Version.count OIDC::RubygemTrustedPublisher.count
                            Events::RubygemEvent.count Events::OrganizationEvent.count] do
      assert_no_changes -> { RubygemFs.instance.each_key.to_a.sort } do
        assert_no_enqueued_jobs { refute cutter.process }
      end
    end
    assert_equal code, cutter.code
    assert_nil Rubygem.find_by(name: cutter.rubygem.name)
  end

  def assert_organization_added_events(rubygem, actor:)
    assert_event Events::RubygemEvent::ORGANIZATION_ADDED, {
      organization: @organization.handle, organization_gid: @organization.to_gid.to_s,
      added_by: actor.display_handle, actor_gid: actor.to_gid.to_s
    }, rubygem.events.where(tag: Events::RubygemEvent::ORGANIZATION_ADDED).sole

    assert_event Events::OrganizationEvent::RUBYGEM_ADDED, {
      rubygem: rubygem.name, rubygem_gid: rubygem.to_gid.to_s,
      added_by: actor.display_handle, actor_gid: actor.to_gid.to_s
    }, @organization.events.where(tag: Events::OrganizationEvent::RUBYGEM_ADDED).sole
  end

  def assert_no_prefix_reserved_push(cutter)
    assert_no_difference [-> { Rubygem.count }, -> { Version.count }, -> { Ownership.count }, -> { Events::OrganizationEvent.count }] do
      refute cutter.process
    end
    assert_equal 403, cutter.code
    assert_match(/starts with 'acme', a prefix reserved by the acme-corp organization/, cutter.message)
  end

  def push_gem_named(name, version: "1.0.0", organization_handle: nil, api_key: @api_key)
    spec = new_gemspec(name, version, "Gemcutter", "ruby") do |s|
      s.metadata["rubygems_organization"] = organization_handle if organization_handle
    end
    Pusher.new(api_key, build_gem(spec))
  end
end
