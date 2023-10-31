require "test_helper"

class PusherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

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
        @cutter.stubs(:save)

        @cutter.process
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

    should "not be able to pull spec from a bad path" do
      @cutter.stubs(:body).stubs(:stub!).stubs(:read)
      @cutter.pull_spec

      assert_nil @cutter.spec
      assert_match(/RubyGems\.org cannot process this gem/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to pull spec with metadata containing bad ruby objects" do
      @gem = gem_file("exploit.gem")
      @cutter = Pusher.new(@api_key, @gem)
      out, err = capture_io do
        @cutter.pull_spec
      end

      assert_equal "", out
      assert_equal("Exception while verifying \n", err)
      assert_nil @cutter.spec
      assert_match(/RubyGems\.org cannot process this gem/, @cutter.message)
      assert_match(/ActionController::Routing::RouteSet::NamedRouteCollection/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if it is not valid" do
      legit_gem = create(:rubygem, name: "legit-gem")
      create(:version, rubygem: legit_gem, number: "0.0.1")
      # this isn't the kind of invalid that we're testing with this gem
      Gem::Specification.any_instance.stubs(:authors).returns(["user@example.com"])
      @gem = gem_file("legit-gem-0.0.1.gem.fake")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.stubs(:save).never
      @cutter.process

      assert_equal("legit", @cutter.rubygem.name)
      assert_equal("gem-0.0.1", @cutter.version.number)
      assert_match(/There was a problem saving your gem: Number is invalid/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the date is not valid" do
      @gem = gem_file("bad-date-1.0.0.gem")
      @cutter = Pusher.new(@api_key, @gem)
      out, err = capture_io do
        @cutter.process
      end

      assert_equal "", out
      assert_equal("Exception while verifying \n", err)
      assert_match(/mon out of range/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if the required_ruby_version is not valid" do
      @cutter.stubs(:spec).returns(new_gemspec("bad-required-ruby-version", "1.0.0", "Summary", "ruby") do |s|
        s.instance_variable_set(:@required_ruby_version, Gem::Requirement.new)
          .instance_variable_set(:@requirements, [[">=", "test"]])
      end)
      @cutter.stubs(:validate_signature_exists?).returns(true)

      @cutter.process

      assert_match(/Required ruby version must be list of valid requirements/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the required_rubygems_version is not valid" do
      @cutter.stubs(:spec).returns(new_gemspec("bad-required-rubygems-version", "1.0.0", "Summary", "ruby") do |s|
        s.instance_variable_set(:@required_rubygems_version, Gem::Requirement.new)
          .instance_variable_set(:@requirements, [[">=", "test"]])
      end)
      @cutter.stubs(:validate_signature_exists?).returns(true)

      @cutter.process

      assert_match(/Required rubygems version must be list of valid requirements/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the dependency requirement is not valid" do
      @cutter.stubs(:spec).returns(new_gemspec("bad-dependency-requirement", "1.0.0", "Summary", "ruby") do |s|
        s.add_runtime_dependency "foo"
        s.dependencies.first.requirement
          .instance_variable_set(:@requirements, [["!!!", "0"]])
      end)
      @cutter.stubs(:validate_signature_exists?).returns(true)

      @cutter.process

      assert_match(/requirements must be list of valid requirements/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the dependency name is not valid" do
      @cutter.stubs(:spec).returns(new_gemspec("bad-dependency-name", "1.0.0", "Summary", "ruby") do |s|
        s.add_runtime_dependency "\nother"
      end)
      @cutter.stubs(:validate_signature_exists?).returns(true)

      @cutter.process

      assert_match(/Dependency unresolved name can only include letters, numbers, dashes, and underscores/, @cutter.message)
      assert_equal 403, @cutter.code
    end

    should "not be able to save a gem if the metadata has incorrect values" do
      @cutter.stubs(:spec).returns(new_gemspec("bad-metadata", "1.0.0", "Summary", "ruby") do |s|
        s.metadata["foo"] = []
      end)
      @cutter.stubs(:validate_signature_exists?).returns(true)

      refute @cutter.process

      assert_match(/metadata\['foo'\] value must be a String/, @cutter.message)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if it is signed and has been tampered with" do
      @gem = gem_file("valid_signature_tampered-0.0.1.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_includes @cutter.message, %(missing signing certificate)
      assert_equal 422, @cutter.code
    end

    should "not be able to save a gem if it is signed with an expired signing certificate" do
      @gem = gem_file("expired_signature-0.0.0.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process

      assert_includes @cutter.message, %(not valid after 2021-07-08 08:21:01 UTC)
      assert_equal 422, @cutter.code
    end

    context "for a signed gem having two certificates in the chain" do
      setup do
        Dir.chdir(Dir.mktmpdir)
      end

      should "be able to save the gem if the chain is valid" do
        gem_file = build_gem("valid_cert_chain", "0.0.0") do |spec|
          signing_key = OpenSSL::PKey::RSA.new(1024)
          spec.signing_key = signing_key
          spec.cert_chain = two_cert_chain(signing_key: signing_key)
        end

        @cutter = Pusher.new(@api_key, File.open(gem_file))
        @cutter.process

        assert_equal 200, @cutter.code
      end

      should "not be able to save the gem if the root certificate has expired" do
        begin
          old_verify_root_policy = Gem::Security::SigningPolicy.verify_root
          Gem::Security::SigningPolicy.verify_root = false
          signing_key = OpenSSL::PKey::RSA.new(1024)

          gem_file = build_gem("expired_root_cert", "0.0.0") do |spec|
            spec.signing_key = signing_key
            spec.cert_chain = two_cert_chain(signing_key: signing_key, root_not_before: 2.years.ago)
          end
        ensure
          Gem::Security::SigningPolicy.verify_root = old_verify_root_policy
        end

        @cutter = Pusher.new(@api_key, File.open(gem_file))
        @cutter.process

        assert_includes @cutter.message, %(CN=Root not valid after)
        assert_equal(422, @cutter.code)
      end

      teardown do
        Dir.chdir(Rails.root)
      end
    end

    should "not be able to pull spec with metadata containing bad ruby symbols" do
      ["1.0.0", "2.0.0", "3.0.0", "4.0.0"].each do |version|
        @gem = gem_file("dos-#{version}.gem")
        @cutter = Pusher.new(@api_key, @gem)
        out, err = capture_io do
          @cutter.pull_spec
        end

        assert_equal "", out
        assert_equal("Exception while verifying \n", err)
        assert_nil @cutter.spec
        assert_includes @cutter.message, %(RubyGems.org cannot process this gem)
        assert_includes @cutter.message, %(Tried to load unspecified class: Symbol)
        assert_equal 422, @cutter.code
      end
    end

    should "be able to pull spec with metadata containing aliases" do
      @gem = gem_file("aliases-0.0.0.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.pull_spec

      assert_not_nil @cutter.spec
      assert_not_nil @cutter.spec.dependencies.first.requirement
    end

    should "not be able to pull spec when no data available" do
      @gem = gem_file("aliases-nodata-0.0.1.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.pull_spec

      assert_includes @cutter.message, %{package content (data.tar.gz) is missing}
    end
  end

  def two_cert_chain(signing_key:, root_not_before: Time.current, cert_not_before: Time.current)
    root_key = OpenSSL::PKey::RSA.new(1024)
    root_subject = "/C=FI/O=Test/OU=Test/CN=Root"

    root_cert = OpenSSL::X509::Certificate.new
    root_cert.subject = root_cert.issuer = OpenSSL::X509::Name.parse(root_subject)
    root_cert.not_before = root_not_before
    root_cert.not_after = root_not_before + 1.year
    root_cert.public_key = root_key.public_key
    root_cert.serial = 0x0
    root_cert.version = 2
    root_cert.sign(root_key, OpenSSL::Digest.new("SHA256"))

    subject = "/C=FI/O=Test/OU=Test/CN=Test"

    cert = OpenSSL::X509::Certificate.new
    cert.issuer = OpenSSL::X509::Name.parse(root_subject)
    cert.subject = OpenSSL::X509::Name.parse(subject)
    cert.not_before = cert_not_before
    cert.not_after = cert_not_before + 1.year
    cert.public_key = signing_key.public_key
    cert.serial = 0x0
    cert.version = 2
    cert.sign(root_key, OpenSSL::Digest.new("SHA256"))

    [root_cert, cert]
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

  context "successfully saving a gemcutter" do
    setup do
      @rubygem = create(:rubygem, name: "gemsgemsgems")
      @cutter.stubs(:rubygem).returns @rubygem
      create(:version, rubygem: @rubygem, number: "0.1.1", summary: "old summary", pusher_api_key: @cutter.api_key)
      @spec = mock
      @cutter.stubs(:version).returns @rubygem.versions[0]
      @cutter.stubs(:spec).returns(@spec)
      @rubygem.stubs(:update_attributes_from_gem_specification!)
      @cutter.stubs(:write_gem)
    end

    context "when cutter is saved" do
      setup do
        assert @cutter.save
      end

      should "set gem file size" do
        assert_equal @gem.size, @cutter.size
      end

      should "set success code" do
        assert_equal 200, @cutter.code
      end

      should "set info_checksum" do
        assert_not_nil @rubygem.versions.last.info_checksum
      end

      should "indexe rubygem and version" do
        assert_predicate @rubygem, :indexed?
        assert_predicate @rubygem.versions.last, :indexed?
      end

      should "create rubygem index" do
        @rubygem.update_column("updated_at", Date.new(2016, 07, 04))
        perform_enqueued_jobs only: ReindexRubygemJob
        response = Searchkick.client.get index: "rubygems-#{Rails.env}",
                                         id:    @rubygem.id
        expected_response = {
          "name"              => "gemsgemsgems",
          "downloads"         => 0,
          "version"           => "0.1.1",
          "version_downloads" => 0,
          "platform"          => "ruby",
          "authors"           => "Joe User",
          "info"              => "Some awesome gem",
          "licenses"          => "MIT",
          "metadata"          => { "foo" => "bar" },
          "sha"               => "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78",
          "project_uri"       => "http://localhost/gems/gemsgemsgems",
          "gem_uri"           => "http://localhost/gems/gemsgemsgems-0.1.1.gem",
          "homepage_uri"      => "http://example.com",
          "wiki_uri"          => "http://example.com",
          "documentation_uri" => "http://example.com",
          "mailing_list_uri"  => "http://example.com",
          "source_code_uri"   => "http://example.com",
          "bug_tracker_uri"   => "http://example.com",
          "changelog_uri"     => nil,
          "funding_uri"       => nil,
          "yanked"            => false,
          "summary"           => "old summary",
          "description"       => "Some awesome gem",
          "updated"           => "2016-07-04T00:00:00.000Z",
          "dependencies"      => { "development" => [], "runtime" => [] },
          "suggest"           => { "input" => "gemsgemsgems", "weight" => 0, "contexts" => { "yanked" => false } }
        }

        assert_equal expected_response, response["_source"]
      end

      should "record the push event" do
        assert_event Events::RubygemEvent::VERSION_PUSHED, {
          number: "0.1.1",
          platform: "ruby",
          sha256: @rubygem.versions.last.sha256_hex,
          version_gid: @rubygem.versions.last.to_gid.to_s
        }, @rubygem.events.where(tag: Events::RubygemEvent::VERSION_PUSHED).sole
      end
    end

    should "purge gem cache" do
      GemCachePurger.expects(:call).with(@rubygem.name).at_least_once
      @cutter.save
    end

    context "with rstuf enabled" do
      setup do
        setup_rstuf
      end

      should "enqueue rstuf addition" do
        assert_enqueued_jobs 1, only: Rstuf::AddJob do
          @cutter.save
        end
      end

      teardown do
        teardown_rstuf
      end
    end

    should "update rubygem attributes when saved" do
      @rubygem.expects(:update_attributes_from_gem_specification!).with(@cutter.version, @spec)
      @cutter.save
    end

    should "enqueue job for email, updating ES index, spec index and purging cdn" do
      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        assert_enqueued_jobs 6, only: FastlyPurgeJob do
          assert_enqueued_jobs 1, only: Indexer do
            assert_enqueued_jobs 1, only: ReindexRubygemJob do
              @cutter.save
            end
          end
        end
      end
    end

    # TODO: Remove this test once this is always enabled
    should "not enqueue job for storing version contents when ENV disables it" do
      assert_enqueued_jobs 0, only: StoreVersionContentsJob do
        @cutter.save
      end
    end
  end

  context "pushing a new version" do
    setup do
      @rubygem = create(:rubygem)
      @cutter.stubs(:rubygem).returns @rubygem
      create(:version, rubygem: @rubygem, summary: "old summary")
      @version = create(:version, rubygem: @rubygem, summary: "new summary", pusher_api_key: @cutter.api_key)
      @cutter.stubs(:version).returns @version
      @rubygem.stubs(:update_attributes_from_gem_specification!)
      @cutter.stubs(:version).returns @version
      GemCachePurger.stubs(:call)
      @cutter.stubs(:write_gem)
      @cutter.save
    end

    should "update rubygem index" do
      perform_enqueued_jobs only: ReindexRubygemJob
      response = Searchkick.client.get index: "rubygems-#{Rails.env}",
                                       id:    @rubygem.id

      assert_equal "new summary", response["_source"]["summary"]
    end

    should "send gem pushed email" do
      perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

      email = ActionMailer::Base.deliveries.last

      assert_equal "Gem #{@version.to_title} pushed to RubyGems.org", email.subject
      assert_equal [@user.email], email.to

      assert_event Events::UserEvent::EMAIL_SENT, {
        to: @user.email, from: "no-reply@mailer.rubygems.org", subject: email.subject,
        message_id: email.message_id, mailer: "mailer", action: "gem_pushed"
      }, @user.events.where(tag: Events::UserEvent::EMAIL_SENT).sole
    end
  end

  context "pushing to s3 fails" do
    setup do
      @gem = gem_file("test-1.0.0.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @fs = RubygemFs.s3!("https://some.host")
      s3_exception = Aws::S3::Errors::ServiceError.new("stub raises", "something went wrong")
      Aws::S3::Client.any_instance.stubs(:put_object).with(any_parameters).raises(s3_exception)
      @cutter.process
    end

    should "not create version" do
      rubygem = Rubygem.find_by(name: "test")
      expected_message = "There was a problem saving your gem. Please try again."

      assert_equal expected_message, @cutter.message
      assert_equal 0, rubygem.versions.count
    end

    teardown do
      RubygemFs.mock!
    end
  end

  context "saving fails with ArgumentError" do
    setup do
      @gem = gem_file("test-1.0.0.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.stubs(:update).raises(ArgumentError.new("some message"))
      @cutter.process
    end

    should "not create rubygem or version" do
      rubygem = Rubygem.find_by(name: "test")
      expected_message = "There was a problem saving your gem. some message"

      assert_equal expected_message, @cutter.message
      assert_nil rubygem
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

  context "the gem has been signed and not tampered with" do
    setup do
      @gem = gem_file("valid_signature-0.0.0.gem")
      @cutter = Pusher.new(@api_key, @gem)
      @cutter.process
    end

    should "extracts the certificate chain to the version" do
      assert_equal 200, @cutter.code
      assert_not_nil @cutter.version
      assert_not_nil @cutter.version.cert_chain
      assert_equal 1, @cutter.version.cert_chain.size
      assert_equal "CN=snakeoil/DC=example/DC=invalid", @cutter.version.cert_chain.first.subject.to_utf8
    end

    teardown do
      RubygemFs.mock!
    end
  end
end
