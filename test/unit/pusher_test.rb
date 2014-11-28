require 'test_helper'

class PusherTest < ActiveSupport::TestCase
  context "getting the server path" do
    should "return just the root server path with no args" do
      assert_equal "#{Rails.root}/server", Pusher.server_path
    end

    should "return a directory inside if one argument is given" do
      assert_equal "#{Rails.root}/server/gems", Pusher.server_path("gems")
    end

    should "return a directory inside if more than one argument is given" do
      assert_equal "#{Rails.root}/server/quick/Marshal.4.8", Pusher.server_path("quick", "Marshal.4.8")
    end
  end

  context "creating a new gemcutter" do
    setup do
      @user = create(:user)
      @gem = gem_file
      @cutter = Pusher.new(@user, @gem)
    end

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
        mock(@cutter).pull_spec { true }
        mock(@cutter).find { true }
        stub(@cutter).authorize { true }
        mock(@cutter).save

        @cutter.process
      end

      should "not attempt to find rubygem if spec can't be pulled" do
        mock(@cutter).pull_spec { false }
        mock(@cutter).find.never
        mock(@cutter).authorize.never
        mock(@cutter).save.never
        @cutter.process
      end

      should "not attempt to authorize if not found" do
        mock(@cutter).pull_spec { true }
        mock(@cutter).find { nil }
        mock(@cutter).authorize.never
        mock(@cutter).save.never

        @cutter.process
      end

      should "not attempt to save if not authorized" do
        mock(@cutter).pull_spec { true }
        mock(@cutter).find { true }
        mock(@cutter).authorize { false }
        mock(@cutter).save.never

        @cutter.process
      end
    end

    should "not be able to pull spec from a bad path" do
      stub(@cutter).body.stub!.read { nil }
      @cutter.pull_spec
      assert_nil @cutter.spec
      assert_match %r{RubyGems\.org cannot process this gem}, @cutter.message
      assert_equal @cutter.code, 422
    end

    should "not be able to pull spec with metadata containing bad ruby objects" do
      @gem = gem_file("exploit.gem")
      @cutter = Pusher.new(@user, @gem)
      @cutter.pull_spec
      assert_nil @cutter.spec
      assert_match %r{RubyGems\.org cannot process this gem}, @cutter.message
      assert_match %r{The metadata is invalid.}, @cutter.message
      assert_match %r{ActionController::Routing::RouteSet::NamedRouteCollection}, @cutter.message
      assert_equal @cutter.code, 422
    end

    should "not be able to pull spec with metadata containing bad ruby symbols" do
      ["1.0.0", "2.0.0", "3.0.0", "4.0.0"].each do |version|
        @gem = gem_file("dos-#{version}.gem")
        @cutter = Pusher.new(@user, @gem)
        @cutter.pull_spec
        assert_nil @cutter.spec
        assert_includes @cutter.message, %{RubyGems.org cannot process this gem}
        assert_includes @cutter.message, %{The metadata is invalid}
        assert_includes @cutter.message, %{Forbidden symbol in YAML}
        assert_includes @cutter.message, %{badsymbol}
        assert_equal @cutter.code, 422
      end
    end

    should "post info to the remote bundler API" do
      @cutter.pull_spec

      stub(@cutter.spec).platform { Gem::Platform.new("x86-java1.6") }

      @cutter.bundler_api_url = "http://test.com"

      obj = Object.new
      post_data = nil

      stub(obj).post { |*x| post_data = x }

      @cutter.update_remote_bundler_api obj

      url, payload, options = post_data

      params = MultiJson.load payload

      assert_equal "test",  params["name"]
      assert_equal "0.0.0", params["version"]
      assert_equal "x86-java-1.6", params["platform"]
      assert_equal false,   params["prerelease"]
    end

    context "initialize new gem with find if one does not exist" do
      setup do
        spec = "spec"
        stub(spec).name { "some name" }
        stub(spec).version { "1.3.3.7" }
        stub(spec).original_platform { "ruby" }
        stub(@cutter).spec { spec }
        stub(@cutter).size { 5 }
        @cutter.find
      end

      should "set rubygem" do
        assert_equal 'some name', @cutter.rubygem.name
      end

      should "set version" do
        assert_equal '1.3.3.7',  @cutter.version.number
      end

      should "set gem version size" do
        assert_equal 5, @cutter.version.size
      end
    end

    context "finding an existing gem" do
      should "bring up existing gem with matching spec" do
        @rubygem = create(:rubygem)
        spec = "spec"
        stub(spec).name { @rubygem.name }
        stub(spec).version { "1.3.3.7" }
        stub(spec).original_platform { "ruby" }
        stub(@cutter).spec { spec }
        @cutter.find

        assert_equal @rubygem, @cutter.rubygem
        assert_not_nil @cutter.version
      end

      should "error out when changing case with usuable versions" do
        @rubygem = create(:rubygem)
        create(:version, :rubygem => @rubygem)

        assert_not_equal @rubygem.name, @rubygem.name.upcase

        spec = "spec"
        stub(spec).name { @rubygem.name.upcase }
        stub(spec).version { "1.3.3.7" }
        stub(spec).original_platform { "ruby" }
        stub(@cutter).spec { spec }
        assert !@cutter.find

        assert_match /Unable to change case/, @cutter.message
      end

      should "update the DB to reflect the case in the spec" do
        @rubygem = create(:rubygem)
        assert_not_equal @rubygem.name, @rubygem.name.upcase

        spec = "spec"
        stub(spec).name { @rubygem.name.upcase }
        stub(spec).version { "1.3.3.7" }
        stub(spec).original_platform { "ruby" }
        stub(@cutter).spec { spec }
        @cutter.find

        @cutter.rubygem.save
        @rubygem.reload

        assert_equal @rubygem.name, @rubygem.name.upcase
      end
    end

    context "checking if the rubygem can be pushed to" do
      should "be true if rubygem is new" do
        stub(@cutter).rubygem { Rubygem.new }
        assert @cutter.authorize
      end

      context "with a existing rubygem" do
        setup do
          @rubygem = create(:rubygem)
          stub(@cutter).rubygem { @rubygem }
        end

        should "be true if owned by the user" do
          @rubygem.ownerships.create(:user => @user)
          assert @cutter.authorize
        end

        should "be true if no versions exist since it's a dependency" do
          assert @cutter.authorize
        end

        should "be false if not owned by user and an indexed version exists" do
          create(:version, :rubygem => @rubygem, :number => '0.1.1')
          assert ! @cutter.authorize
          assert_equal "You do not have permission to push to this gem.", @cutter.message
          assert_equal 403, @cutter.code
        end

        should "be true if not owned by user but no indexed versions exist" do
          create(:version, :rubygem => @rubygem, :number => '0.1.1', :indexed => false)
          assert @cutter.authorize
        end
      end
    end

    context "successfully saving a gemcutter" do
      setup do
        @rubygem = create(:rubygem)
        stub(@cutter).rubygem { @rubygem }
        create(:version, :rubygem => @rubygem, :number => '0.1.1')
        stub(@cutter).version { @rubygem.versions[0] }
        stub(@rubygem).update_attributes_from_gem_specification!
        any_instance_of(Indexer) {|i| stub(i).write_gem }
        @cutter.save
      end

      should "update rubygem attributes" do
        assert_received(@rubygem) do |rubygem|
            rubygem.update_attributes_from_gem_specification!(@cutter.version,
                                                              @cutter.spec)
        end
      end

      should "set gem file size" do
        assert_equal @gem.size, @cutter.size
      end

      should "set success code" do
        assert_equal 200, @cutter.code
      end
    end
  end
end
