require File.dirname(__FILE__) + '/../test_helper'

class GemcutterTest < ActiveSupport::TestCase
  context "getting the server path" do
    should "return just the root server path with no args" do
      assert_equal "#{Rails.root}/server", Gemcutter.server_path
    end

    should "return a directory inside if one argument is given" do
      assert_equal "#{Rails.root}/server/gems", Gemcutter.server_path("gems")
    end

    should "return a directory inside if more than one argument is given" do
      assert_equal "#{Rails.root}/server/quick/Marshal.4.8", Gemcutter.server_path("quick", "Marshal.4.8")
    end
  end

  should "generate a new indexer" do
    @indexer = "indexer"
    mock(Gem::Indexer).new(Gemcutter.server_path, :build_legacy => false) { @indexer }
    assert_equal @indexer, Gemcutter.indexer
    assert @indexer.respond_to?(:say)
    assert_nil @indexer.say("Should be quiet")
  end

  context "creating a new gemcutter" do
    setup do
      @user = Factory(:email_confirmed_user)
      @gem = gem_file
      @cutter = Gemcutter.new(@user, @gem)
    end

    should "have some state" do
      assert @cutter.respond_to?(:user)
      assert @cutter.respond_to?(:data)
      assert @cutter.respond_to?(:spec)
      assert @cutter.respond_to?(:error_message)
      assert @cutter.respond_to?(:error_code)
      assert @cutter.respond_to?(:rubygem)

      assert_equal @user, @cutter.user
      assert_equal @gem, @cutter.data
    end

    context "processing incoming gems" do
      should "work normally when things go well" do
        mock(@cutter).pull_spec
        stub(@cutter).spec { "ruby gem spec" }
        mock(@cutter).find_rubygem
        @cutter.process
      end

      should "not attempt to find rubygem if there's no spec" do
        mock(@cutter).pull_spec
        stub(@cutter).spec { nil }
        mock(@cutter).find_rubygem.never
        @cutter.process
      end
    end


    context "pulling the spec " do
      should "pull spec out of the given gem" do
        @cutter.pull_spec
        assert_not_nil @cutter.spec
        assert @cutter.spec.is_a?(Gem::Specification)
      end

      should "not be able to pull spec from a bad path" do
        stub(@cutter).data { "bad data" }
        @cutter.pull_spec
        assert_nil @cutter.spec
        assert_equal @cutter.error_message, "Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid."
        assert_equal @cutter.error_code, 422
      end
    end

    context "finding rubygem" do
      should "initialize new gem if one does not exist" do
        @cutter.pull_spec
        @cutter.find_rubygem
        assert_not_nil @cutter.rubygem
        assert @cutter.rubygem.new_record?
      end

      should "bring up existing gem with matching spec" do
        @cutter.pull_spec
        @rubygem = Factory(:rubygem, :spec => @cutter.spec, :name => @cutter.spec.name)

        @cutter.find_rubygem
        assert_equal @rubygem, @cutter.rubygem
      end
    end
  end
end
