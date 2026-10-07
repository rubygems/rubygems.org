# frozen_string_literal: true

require "test_helper"
require "concurrent/atomics"
require "timeout"

class ParallelPusherTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @fs = RubygemFs.mock!
    @user = create(:user, email: "parallel-pusher-#{SecureRandom.hex(6)}@rubygems-test.org")
    @api_key = create(:api_key, owner: @user)
    @gem_names = []
  end

  teardown do
    @gem_names.each { |name| Rubygem.name_is(name).first&.destroy! }
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

      ActiveRecord::Base.connection_pool.release_connection
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

      ActiveRecord::Base.connection_pool.release_connection
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

  should "take the advisory lock before updating a version row" do
    rubygem = create(:rubygem, name: track_gem("advisory-lock-ordering"))
    version = create(:version, rubygem: rubygem)

    assert_locks_before_writing(rubygem, version) { Version.find(version.id).update!(indexed: false) }

    refute_predicate version.reload, :indexed?
  end

  should "take the advisory lock before changing gem name case during a push" do
    rubygem = create(:rubygem, name: track_gem("case-lock-ordering"))
    create(:version, rubygem: rubygem, indexed: false)
    rubygem.create_ownership(@user)
    gem = build_gem(new_gemspec(rubygem.name.upcase, "2.0.0", "GemCutter", "ruby"))
    pusher = Pusher.new(@api_key, gem)

    assert_locks_before_writing(rubygem, rubygem) { pusher.process }

    assert_equal 200, pusher.code, pusher.message
    assert_equal pusher.spec.name, rubygem.reload.name
  end

  should "keep the advisory lock across content address retries during a revival push" do
    previous_owner = create(:user)
    rubygem = create(:rubygem, name: track_gem("revival-retry-lock"))
    rubygem.create_ownership(previous_owner)
    yanked = create(:version, :yanked, rubygem: rubygem, number: "1.0.0", platform: "x86_64-linux")
    FeatureFlag.enable_for_actor(FeatureFlag::CONTENT_ADDRESSABLE_GEM_PUSHES, @user)
    spec = new_gemspec(rubygem.name, "1.0.0", "GemCutter", "arm64-darwin-25",
                       ruby_version: "~> 3.4.0", rubygems_version: Version::CONTENT_ADDRESSABLE_REQUIRED_RUBYGEMS_VERSION)
    pusher = Pusher.new(@api_key, build_gem(spec))
    content_address = Digest::SHA256.hexdigest(pusher.body.string).first(Version::DEFAULT_CONTENT_ADDRESS_LENGTH)
    yanked.update_columns(content_address: content_address)

    lock_held_after_rollbacks = []
    record_lock = lambda do |*, payload|
      lock_held_after_rollbacks << advisory_lock_held?(rubygem) if payload[:sql].start_with?("ROLLBACK TO SAVEPOINT")
    end
    ActiveSupport::Notifications.subscribed(record_lock, "sql.active_record") { pusher.process }

    assert_equal 409, pusher.code
    assert_includes pusher.message, "could not generate a unique content address"
    assert_equal [true] * 4, lock_held_after_rollbacks
    assert_equal [previous_owner], rubygem.reload.owners
    assert_equal [yanked.id], rubygem.versions.ids
  ensure
    FeatureFlag.disable_for_actor(FeatureFlag::CONTENT_ADDRESSABLE_GEM_PUSHES, @user)
    previous_owner&.destroy!
  end

  should "take the advisory lock before destroying a version or its dependents" do
    rubygem = create(:rubygem, name: track_gem("destroy-lock-ordering"))
    version = create(:version, rubygem: rubygem)

    assert_locks_before_writing(rubygem, version, version.gem_download) { Version.find(version.id).destroy! }

    refute Version.exists?(version.id)
    assert Rubygem.exists?(rubygem.id)
  end

  should "take the advisory lock before destroying a gem or any dependents" do
    rubygem = create(:rubygem, name: track_gem("gem-destroy-lock-ordering"))
    version = create(:version, rubygem: rubygem)
    rubygem.create_ownership(@user)
    ownership = rubygem.ownerships.sole

    assert_locks_before_writing(rubygem, rubygem, ownership, version) { Rubygem.find(rubygem.id).destroy! }

    refute Rubygem.exists?(rubygem.id)
    refute Version.exists?(version.id)
  end

  %i[destroy yank].each do |operation|
    should "reject a yank when #{operation} wins the gem lock" do
      rubygem = create(:rubygem, name: track_gem("#{operation}-yank-ordering"))
      version = create(:version, rubygem: rubygem)
      create(:version, rubygem: rubygem, number: "2.0.0")
      backend_pid = Queue.new
      yanker = nil

      Rubygem.transaction do
        rubygem.lock_version_writes!
        yanker = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            backend_pid << connection.select_value("SELECT pg_backend_pid()")
            deletion = Deletion.new(user: @user, version: Version.find(version.id))
            [deletion.save, deletion.errors.full_messages]
          end
        end
        waiting_pid = backend_pid.pop(timeout: 5)

        assert waiting_pid, "yanker did not check out a connection within 5 seconds"
        wait_for_advisory_lock(waiting_pid, yanker)
        if operation == :destroy
          version.destroy!
        else
          Deletion.create!(user: @user, version: version)
        end
      end

      saved, errors = Timeout.timeout(5) { yanker.value }

      refute saved, "yank succeeded after #{operation}: #{errors.inspect}"
      assert_predicate errors, :present?
      if operation == :destroy
        refute Version.exists?(version.id)
        assert_empty Deletion.where(version_id: version.id)
      else
        refute_predicate version.reload, :indexed?
        assert_equal 1, Deletion.where(version_id: version.id).count
      end
    ensure
      yanker&.kill if yanker&.alive?
      yanker&.join(5)
      Deletion.where(version_id: version.id).delete_all if version
    end
  end

  [true, false].each do |change_indexed|
    should "lock before writing link verifications with indexed change #{change_indexed}" do
      rubygem = create(:rubygem, name: track_gem("links-lock-ordering"))
      version = create(:version, rubygem: rubygem)
      uri = "https://example.com/#{rubygem.name}"
      verification = rubygem.link_verifications.create!(uri: uri, failures_since_last_verification: 1, last_failure_at: Time.current)
      attributes = { metadata: { "homepage_uri" => uri } }
      attributes[:indexed] = false if change_indexed

      assert_locks_before_writing(rubygem, verification, version) { Version.find(version.id).update!(attributes) }

      assert_equal 0, verification.reload.failures_since_last_verification
      assert_equal attributes[:metadata], version.reload.metadata
      assert_equal !change_indexed, version.indexed?
    end
  end

  private

  # While the writer waits on the advisory lock, none of its earlier writes may
  # hold row locks. NOWAIT detects a callback or transaction entry point locking
  # too late, without relying on a probabilistic deadlock interleaving.
  def assert_locks_before_writing(rubygem, *records)
    backend_pid = Queue.new
    updater = nil

    Rubygem.transaction do
      Rubygem.advisory_xact_lock!("rubygem_version_reorder", rubygem.id)

      updater = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          backend_pid << connection.select_value("SELECT pg_backend_pid()")
          yield
        end
      end

      waiting_pid = backend_pid.pop(timeout: 5)

      assert waiting_pid, "writer did not check out a connection within 5 seconds"
      wait_for_advisory_lock(waiting_pid, updater)
      records.each { |record| record.class.lock("FOR UPDATE NOWAIT").find(record.id) }
    end

    Timeout.timeout(5) { updater.value }
  ensure
    updater&.kill if updater&.alive?
    updater&.join(5)
  end

  def advisory_lock_held?(rubygem)
    Rubygem.connection.select_value(<<~SQL.squish)
      SELECT EXISTS (
        SELECT 1 FROM pg_locks
        WHERE locktype = 'advisory' AND pid = pg_backend_pid() AND granted
          AND objid = #{Integer(rubygem.id)} AND objsubid = 2
      )
    SQL
  end

  def wait_for_advisory_lock(pid, updater)
    Timeout.timeout(5) do
      Rubygem.uncached do
        loop do
          assert_predicate updater, :alive?, "writer exited without waiting for the advisory lock"
          waiting = Rubygem.connection.select_value(<<~SQL.squish)
            SELECT EXISTS (
              SELECT 1 FROM pg_locks
              WHERE pid = #{Integer(pid)}
                AND locktype = 'advisory'
                AND NOT granted
            )
          SQL
          break if waiting

          sleep 0.01
        end
      end
    end
  end

  def track_gem(name)
    unique_name = "#{name}-#{SecureRandom.hex(6)}"
    @gem_names << unique_name
    unique_name
  end
end
