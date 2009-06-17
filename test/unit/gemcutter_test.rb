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
end
