# frozen_string_literal: true

require "test_helper"
require "concurrent/atomics"

class ParallelPusherTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  context "when pushing gems in parallel" do
    setup do
      @fs = RubygemFs.mock!
      @user = create(:user, email: "user@rubygems-test.org")
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

  context "when pushing many versions of the same gem in parallel" do
    setup do
      @fs = RubygemFs.mock!
      @user = create(:user, email: "parallel-user@rubygems-test.org")
      @api_key = create(:api_key, owner: @user)
      @gem_name = "hola-parallel"
    end

    teardown do
      Rubygem.find_by(name: @gem_name)&.destroy!
      @user.destroy!
      GemDownload.delete_all
      RubygemFs.mock!
    end

    # Regression test for concurrent pushes deadlocking in reorder_versions
    # (https://github.com/rubygems/rubygems.org/issues/6099). Concurrent
    # writers must serialize on the per-gem advisory lock, so every push
    # succeeds and positions/latest are consistent afterwards.
    should "push all versions without deadlocking and leave versions consistently ordered" do
      seed = Pusher.new(@api_key, build_gem(new_gemspec(@gem_name, "0.0.1", "GemCutter", "ruby")))
      seed.process

      assert_equal 200, seed.code, seed.message

      numbers = (1..4).map { |i| "#{i}.0.0" }
      start = Concurrent::CountDownLatch.new(1)

      threads = numbers.map do |number|
        Thread.new do
          gem = build_gem(new_gemspec(@gem_name, number, "GemCutter", "ruby"))
          start.wait
          ActiveRecord::Base.connection_pool.with_connection do
            pusher = Pusher.new(@api_key, gem)
            pusher.process
            [number, pusher.code, pusher.message]
          end
        end
      end

      start.count_down
      results = threads.map(&:value)
      failures = results.reject { |(_, code, _)| code == 200 }

      assert_empty failures, "expected all concurrent pushes to succeed, got: #{failures.inspect}"

      versions = Rubygem.find_by!(name: @gem_name).versions.reload

      assert_equal numbers.size + 1, versions.count
      assert_equal (0..numbers.size).to_a, versions.pluck(:position).sort
      assert_equal ["4.0.0"], versions.where(latest: true).pluck(:number)
      assert_equal numbers.size + 1, versions.indexed.count
    end
  end
end
