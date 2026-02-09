require "test_helper"
require "concurrent/atomics"

class ParallelPusherTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  context "when pushing gems in parallel" do
    setup do
      @fs = RubygemFs.mock!
      @user = create(:user, email: "user@example.com")
      @api_key = create(:api_key, owner: @user)
    end

    teardown do
      @user.destroy!
      Rubygem.find_by(name: "hola")&.destroy!
      GemDownload.delete_all
      RubygemFs.mock!
    end

    should "not lead to sha mismatch between gem file and db" do
      latch = Concurrent::CountDownLatch.new(2)
      gem = build_gem(new_gemspec("hola", "1.0.0", "GemCutter", "ruby"))

      Thread.new do
        Pusher.new(@api_key, gem).process
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      Thread.new do
        duplicate_gem = build_gem(new_gemspec("hola", "1.0.0", "GemCutter", "ruby"))
        Pusher.new(@api_key, duplicate_gem).process
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      latch.wait
      expected_sha = Digest::SHA2.base64digest(gem.string)

      assert_equal expected_sha, Version.last.sha256
    end
  end
end
