require "test_helper"

class PusherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include GemspecYamlTemplateHelpers

  setup do
    @user = create(:user, email: "user@example.com")
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
      assert_not_includes @cutter.message, "Error:"
      assert_not_includes @cutter.message, "unexpected internal error"
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
      spec.stubs(:metadata).returns({})
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"
      @cutter.find

      assert_equal @rubygem, @cutter.rubygem
      assert_not_nil @cutter.version
    end

    should "error out when changing case with usuable versions" do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem)

      assert_not_equal @rubygem.name, @rubygem.name.upcase

      spec = mock
      spec.expects(:name).returns @rubygem.name.upcase
      spec.expects(:version).returns Gem::Version.new("1.3.3.7")
      spec.expects(:platform).returns "ruby"
      spec.expects(:original_platform).returns "ruby"
      spec.expects(:cert_chain).returns nil
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"

      refute @cutter.find

      assert_match(/Unable to change case/, @cutter.message)
    end

    should "update the DB to reflect the case in the spec" do
      @rubygem = create(:rubygem)

      assert_not_equal @rubygem.name, @rubygem.name.upcase

      spec = mock
      spec.stubs(:name).returns @rubygem.name.upcase
      spec.stubs(:version).returns Gem::Version.new("1.3.3.7")
      spec.stubs(:original_platform).returns "ruby"
      spec.stubs(:platform).returns "ruby"
      spec.stubs(:cert_chain).returns nil
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
      @cutter.stubs(:spec).returns spec
      @cutter.stubs(:spec_contents).returns "spec"

      @cutter.find

      assert_equal @rubygem, @cutter.rubygem
      assert_not_nil @cutter.version

      assert_equal "universal-darwin-6000", @cutter.version.platform
      assert_equal "universal-darwin-6000", @cutter.version.gem_platform
    end
  end

  context "checking if the rubygem can be pushed to" do
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
        assert_equal "You do not have permission to push to this gem. Ask an owner to add you with: gem owner the_gem_name --add user@example.com",
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
        create(:version, rubygem: @rubygem, number: "0.1.1", indexed: false)

        assert @cutter.authorize
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
end
