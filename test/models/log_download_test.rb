require "test_helper"

class LogDownloadTest < ActiveSupport::TestCase
  setup do
    @log_download = LogDownload.create!(directory: "test", key: "fake.log")
  end

  should "not allow duplicate directory and key" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      LogDownload.create!(directory: "test", key: "fake.log")
    end
  end

  should "allow diffent keys in same directory" do
    LogDownload.create!(directory: "test", key: "fake2.log")
  end

  context "#pop" do
    setup do
      @log_download = LogDownload.create!(directory: "test/2", key: "bar", status: "pending")
    end

    context "without any keys" do
      setup do
        LogDownload.create!(directory: "test", key: "fake3.log")
      end

      should "return the first download" do
        assert_equal "fake.log", LogDownload.pop.key
      end
    end

    context "with a key" do
      setup do
        LogDownload.create!(directory: "test", key: "fake4.log")
      end

      should "return the first download" do
        assert_equal "fake4.log", LogDownload.pop(key: "fake4.log").key
      end
    end

    should "change the status" do
      one = LogDownload.pop
      assert_equal "processing", one.status
    end

    should "return nil in case no download is available" do
      2.times { LogDownload.pop }
      assert_nil LogDownload.pop
    end

    context "with a directory" do
      setup do
        LogDownload.create!(directory: "test/dir", key: "fake5.log")
      end

      should "return the first download" do
        assert_equal "fake5.log", LogDownload.pop(directory: "test/dir").key
      end
    end
  end
end
