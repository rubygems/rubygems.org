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

  context "when pushing and yanking versions of the same gem in parallel" do
    setup do
      @fs = RubygemFs.mock!
      @user = create(:user, email: "parallel-yank-user@rubygems-test.org")
      @api_key = create(:api_key, owner: @user)
      @gem_name = "hola-parallel-yank"
    end

    teardown do
      Rubygem.find_by(name: @gem_name)&.destroy!
      @user.destroy!
      GemDownload.delete_all
      RubygemFs.mock!
    end

    # Yanks UPDATE an existing (visible) version row before reorder_versions
    # runs, so unlike concurrent pushes they deadlock unless the per-gem
    # advisory lock is taken *before* the version row is written
    # (Version#serialize_indexed_writes_per_gem). Guards that callback.
    should "not deadlock and keep indexed state consistent" do
      %w[1.0.0 2.0.0 3.0.0].each do |number|
        pusher = Pusher.new(@api_key, build_gem(new_gemspec(@gem_name, number, "GemCutter", "ruby")))
        pusher.process

        assert_equal 200, pusher.code, pusher.message
      end

      rubygem = Rubygem.find_by!(name: @gem_name)
      to_yank = rubygem.versions.where(number: %w[1.0.0 2.0.0]).to_a
      start = Concurrent::CountDownLatch.new(1)

      push_threads = %w[4.0.0 5.0.0].map do |number|
        Thread.new do
          gem = build_gem(new_gemspec(@gem_name, number, "GemCutter", "ruby"))
          start.wait
          ActiveRecord::Base.connection_pool.with_connection do
            pusher = Pusher.new(@api_key, gem)
            pusher.process
            ["push #{number}", pusher.code == 200 ? nil : pusher.message]
          end
        end
      end

      yank_threads = to_yank.map do |version|
        Thread.new do
          start.wait
          ActiveRecord::Base.connection_pool.with_connection do
            Deletion.create!(user: @user, version: version)
            ["yank #{version.number}", nil]
          rescue StandardError => e
            ["yank #{version.number}", "#{e.class}: #{e.message}"]
          end
        end
      end

      start.count_down
      failures = (push_threads + yank_threads).map(&:value).reject { |(_, error)| error.nil? }

      assert_empty failures, "expected all concurrent pushes and yanks to succeed, got: #{failures.inspect}"

      versions = rubygem.versions.reload

      assert_equal 5, versions.count
      assert_equal %w[3.0.0 4.0.0 5.0.0], versions.indexed.pluck(:number).sort
      assert_equal (0..4).to_a, versions.pluck(:position).sort
      assert_equal ["5.0.0"], versions.where(latest: true).pluck(:number)
    end
  end
end
