require "test_helper"

class PusherTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, email: "user@example.com")
    @gem = gem_file
    @cutter = Pusher.new(@user, @gem)
  end

  context "creating a new gemcutter" do
    should "have some state" do
      assert @cutter.respond_to?(:user)
      assert @cutter.respond_to?(:version)
      assert @cutter.respond_to?(:version_id)
      assert @cutter.respond_to?(:spec)
      assert @cutter.respond_to?(:message)
      assert @cutter.respond_to?(:code)
      assert @cutter.respond_to?(:rubygem)
      assert @cutter.respond_to?(:body)

      assert_equal @user, @cutter.user
    end

    should "initialize size from the gem" do
      assert_equal @gem.size, @cutter.size
    end

    context "processing incoming gems" do
      should "work normally when things go well" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
        @cutter.stubs(:validate).returns true
        @cutter.stubs(:save)

        @cutter.process
      end

      should "not attempt to find rubygem if spec can't be pulled" do
        @cutter.stubs(:pull_spec).returns false
        @cutter.stubs(:find).never
        @cutter.stubs(:authorize).never
        @cutter.stubs(:save).never
        @cutter.process
      end

      should "not attempt to authorize if not found" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find)
        @cutter.stubs(:authorize).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to validate if not authorized" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns false
        @cutter.stubs(:validate).never
        @cutter.stubs(:save).never

        @cutter.process
      end

      should "not attempt to save if not validated" do
        @cutter.stubs(:pull_spec).returns true
        @cutter.stubs(:find).returns true
        @cutter.stubs(:authorize).returns true
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
      assert_equal @cutter.code, 422
    end

    should "not be able to pull spec with metadata containing bad ruby objects" do
      @gem = gem_file("exploit.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_nil @cutter.spec
      assert_match(/RubyGems\.org cannot process this gem/, @cutter.message)
      assert_match(/ActionController::Routing::RouteSet::NamedRouteCollection/, @cutter.message)
      assert_equal @cutter.code, 422
    end

    should "not be able to save a gem if it is not valid" do
      legit_gem = create(:rubygem, name: "legit-gem")
      create(:version, rubygem: legit_gem, number: "0.0.1")
      @gem = gem_file("legit-gem-0.0.1.gem.fake")
      @cutter = Pusher.new(@user, @gem)
      @cutter.stubs(:save).never
      @cutter.process
      assert_equal @cutter.rubygem.name, "legit"
      assert_equal @cutter.version.number, "gem-0.0.1"
      assert_match(/There was a problem saving your gem: Number is invalid/, @cutter.message)
      assert_equal @cutter.code, 403
    end

    should "not be able to save a gem if the date is not valid" do
      @gem = gem_file("bad-date-1.0.0.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.process
      assert_match(/exception while verifying: mon out of range/, @cutter.message)
      assert_equal @cutter.code, 422
    end

    should "not be able to pull spec with metadata containing bad ruby symbols" do
      ["1.0.0", "2.0.0", "3.0.0", "4.0.0"].each do |version|
        @gem = gem_file("dos-#{version}.gem")
        @cutter = Pusher.new(@user, @gem)
        @cutter.pull_spec
        assert_nil @cutter.spec
        assert_includes @cutter.message, %(RubyGems.org cannot process this gem)
        assert_includes @cutter.message, %(Tried to load unspecified class: Symbol)
        assert_equal @cutter.code, 422
      end
    end

    should "be able to pull spec with metadata containing aliases" do
      @gem = gem_file("aliases-0.0.0.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_not_nil @cutter.spec
      assert_not_nil @cutter.spec.dependencies.first.requirement
    end

    should "not be able to pull spec when no data available" do
      @gem = gem_file("aliases-nodata-0.0.1.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_includes @cutter.message, %{package content (data.tar.gz) is missing}
    end
  end

  context "initialize new gem with find if one does not exist" do
    setup do
      spec = mock
      spec.expects(:name).returns "some name"
      spec.expects(:version).times(2).returns Gem::Version.new("1.3.3.7")
      spec.expects(:original_platform).returns "ruby"
      @cutter.stubs(:spec).returns spec
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
      @cutter.stubs(:spec).returns spec
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
      spec.expects(:original_platform).returns "ruby"
      @cutter.stubs(:spec).returns spec
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
      @cutter.stubs(:spec).returns spec
      @cutter.find

      @cutter.rubygem.save
      @rubygem.reload

      assert_equal @rubygem.name, @rubygem.name.upcase
    end
  end

  context "checking if the rubygem can be pushed to" do
    should "be true if rubygem is new" do
      @cutter.stubs(:rubygem).returns Rubygem.new
      assert @cutter.authorize
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

      should "be true if not owned by user but no indexed versions exist" do
        create(:version, rubygem: @rubygem, number: "0.1.1", indexed: false)
        assert @cutter.authorize
      end
    end
  end

  context "successfully saving a gemcutter" do
    setup do
      @rubygem = create(:rubygem, name: "gemsgemsgems")
      @cutter.stubs(:rubygem).returns @rubygem
      create(:version, rubygem: @rubygem, number: "0.1.1", summary: "old summary")
      @spec = mock
      @cutter.stubs(:version).returns @rubygem.versions[0]
      @cutter.stubs(:spec).returns(@spec)
      @rubygem.stubs(:update_attributes_from_gem_specification!)
      Indexer.any_instance.stubs(:write_gem)
    end

    context "when cutter is saved" do
      setup do
        assert_equal true, @cutter.save
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
        assert @rubygem.indexed?
        assert @rubygem.versions.last.indexed?
      end

      should "create rubygem index" do
        @rubygem.update_column("updated_at", Date.new(2016, 07, 04))
        Delayed::Worker.new.work_off
        response = Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
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
          "dependencies"      => { "development" => [], "runtime" => [] }
        }

        assert_equal expected_response, response["_source"]
      end
    end

    should "purge gem cache" do
      GemCachePurger.expects(:call).with(@rubygem.name).at_least_once
      @cutter.save
    end

    should "update rubygem attributes when saved" do
      @rubygem.expects(:update_attributes_from_gem_specification!).with(@cutter.version, @spec)
      @cutter.save
    end

    should "enqueue job for email, updating ES index, spec index and purging cdn" do
      assert_difference "Delayed::Job.count", 6 do
        @cutter.save
      end
    end
  end

  context "pushing a new version" do
    setup do
      @rubygem = create(:rubygem)
      @cutter.stubs(:rubygem).returns @rubygem
      create(:version, rubygem: @rubygem, summary: "old summary")
      @version = create(:version, rubygem: @rubygem, summary: "new summary")
      @cutter.stubs(:version).returns @version
      @rubygem.stubs(:update_attributes_from_gem_specification!)
      @cutter.stubs(:version).returns @version
      GemCachePurger.stubs(:call)
      Indexer.any_instance.stubs(:write_gem)
      @cutter.save
    end

    should "update rubygem index" do
      Delayed::Worker.new.work_off
      response = Rubygem.__elasticsearch__.client.get index: "rubygems-#{Rails.env}",
                                                      id:    @rubygem.id
      assert_equal "new summary", response["_source"]["summary"]
    end

    should "send gem pushed email" do
      Delayed::Worker.new.work_off

      email = ActionMailer::Base.deliveries.last
      assert_equal "Gem #{@version.to_title} pushed to RubyGems.org", email.subject
      assert_equal [@user.email], email.to
    end
  end

  context "pushing to s3 fails" do
    setup do
      @gem = gem_file("test-1.0.0.gem")
      @cutter = Pusher.new(@user, @gem)
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

    teardown { RubygemFs.mock! }
  end
end
