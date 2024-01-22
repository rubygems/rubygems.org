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
      @api_key.destroy!
      Rubygem.find_by(name: "hola").destroy!
      GemDownload.delete_all
      RubygemFs.mock!
    end

    should "not lead to sha mismatch between gem file and db" do
      latch = Concurrent::CountDownLatch.new(2)

      Thread.new do
        gem_file("hola-0.0.0.gem") do |gem1|
          Pusher.new(@api_key, gem1).process
        end
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      Thread.new do
        gem_file("hola/hola-0.0.0.gem") do |gem2|
          Pusher.new(@api_key, gem2).process
        end
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      latch.wait
      expected_sha = Digest::SHA2.base64digest(@fs.get("gems/hola-0.0.0.gem"))

      assert_equal expected_sha, Version.last.sha256
    end
  end
end
