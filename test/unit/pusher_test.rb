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

    context "finding rubygem" do
      should "initialize new gem if one does not exist" do
        spec = "spec"
        stub(spec).name { "some name" }
        stub(spec).version { "1.3.3.7" }
        stub(spec).original_platform { "ruby" }
        stub(@cutter).spec { spec }
        @cutter.find

        assert_not_nil @cutter.rubygem
        assert_not_nil @cutter.version
      end

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
  end
end
