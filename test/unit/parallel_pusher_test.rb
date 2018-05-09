require 'test_helper'
require 'concurrent/atomics'

class ParallelPusherTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  context "when pushing gems in parallel" do
    setup do
      @fs = RubygemFs.mock!
      @user = create(:user, email: "user@example.com")
    end

    teardown do
      @user.destroy
      @rubygem = Rubygem.find_by(name: 'hola')
      @rubygem.versions.destroy_all
      @rubygem.destroy
      Delayed::Job.delete_all
      GemDownload.delete_all
    end

    should "not lead to sha mismatch between gem file and db" do
      @gem1 = gem_file("hola-0.0.0.gem")
      @gem2 = gem_file("hola/hola-0.0.0.gem")
      @cutter1 = Pusher.new(@user, @gem1)
      @cutter2 = Pusher.new(@user, @gem2)
      latch = Concurrent::CountDownLatch.new(2)

      Thread.new do
        @cutter1.process
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      Thread.new do
        @cutter2.process
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      latch.wait
      expected_sha = Digest::SHA2.base64digest(@fs.get('gems/hola-0.0.0.gem'))
      assert_equal expected_sha, Version.last.sha256
    end
  end
end
