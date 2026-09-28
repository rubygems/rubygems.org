# frozen_string_literal: true

require "test_helper"
require "concurrent/atomics"

class ParallelPusherTest < ActiveSupport::TestCase
  LOCK_WAIT_TIMEOUT = 5

  self.use_transactional_tests = false

  setup do
    @fs = RubygemFs.mock!
    @user = create(:user, email: "parallel-pusher-#{SecureRandom.hex(6)}@rubygems-test.org")
    @api_key = create(:api_key, owner: @user)
    @gem_names = []
  end

  teardown do
    @gem_names.each { |name| Rubygem.find_by(name: name)&.destroy! }
    @user.destroy!
    GemDownload.delete_all
    RubygemFs.mock!
  end

  context "when pushing gems in parallel" do
    should "not lead to sha mismatch between gem file and db" do
      gem_name = track_gem("hola")
      latch = Concurrent::CountDownLatch.new(2)
      gem = build_gem(new_gemspec(gem_name, "1.0.0", "GemCutter", "ruby"))

      Thread.new do
        Pusher.new(@api_key, gem).process
        ActiveRecord::Base.connection.close
        latch.count_down
      end

      Thread.new do
        duplicate_gem = build_gem(new_gemspec(gem_name, "1.0.0", "GemCutter", "ruby"))
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
      @gem_name = track_gem("hola-parallel")
    end

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
      @gem_name = track_gem("hola-parallel-yank")
    end

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

  context "when another transaction holds the per-gem advisory lock" do
    setup do
      @rubygem = create(:rubygem, name: track_gem("hola-lock-order"))
      @older = create(:version, rubygem: @rubygem, number: "1.0.0")
      @newer = create(:version, rubygem: @rubygem, number: "2.0.0")
    end

    should "wait for the lock before writing the version row" do
      pid_queue = Queue.new
      writer = nil

      Rubygem.transaction do
        Rubygem.advisory_xact_lock!("rubygem_version_reorder", @rubygem.id)

        writer = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            pid_queue << connection.select_value("SELECT pg_backend_pid()")
            Version.find(@newer.id).update!(indexed: false)
          end
        end

        writer_pid = pid_queue.pop(timeout: LOCK_WAIT_TIMEOUT)

        refute_nil writer_pid, "writer thread never started"
        assert waited_for_advisory_lock?(writer_pid), "writer never waited on the per-gem advisory lock"

        # Raises ActiveRecord::LockWaitTimeout if the writer already holds the row lock.
        assert_equal [@newer.id], Version.where(id: @newer.id).lock("FOR UPDATE NOWAIT").pluck(:id)
      end

      refute_nil writer.join(LOCK_WAIT_TIMEOUT), "writer did not finish after the advisory lock was released"
      writer.value

      refute_predicate @newer.reload, :indexed?
      assert_predicate @older.reload, :latest?
      refute_predicate @newer, :latest?
    ensure
      writer&.join(LOCK_WAIT_TIMEOUT)
    end
  end

  private

  def waited_for_advisory_lock?(pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + LOCK_WAIT_TIMEOUT
    until Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      waiting = ActiveRecord::Base.uncached do
        ActiveRecord::Base.connection.select_value(
          ActiveRecord::Base.sanitize_sql_array(
            ["SELECT EXISTS (SELECT 1 FROM pg_locks WHERE locktype = 'advisory' AND NOT granted AND pid = ?)", pid]
          )
        )
      end
      return true if waiting

      sleep 0.01
    end
    false
  end

  def track_gem(name)
    unique_name = "#{name}-#{SecureRandom.hex(6)}"
    @gem_names << unique_name
    unique_name
  end
end
