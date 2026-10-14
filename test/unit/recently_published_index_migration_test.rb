# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/migrate/20261012233055_add_recently_published_index_to_versions")

class RecentlyPublishedIndexMigrationTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  INDEX_NAME = "index_versions_on_rubygem_id_and_created_at"
  POSITION_INDEX_NAME = "index_versions_on_rubygem_id_and_position_and_created_at"
  CREATE_INDEX = <<~SQL.squish
    CREATE INDEX CONCURRENTLY #{INDEX_NAME}
    ON versions (rubygem_id, created_at DESC) WHERE indexed = true
  SQL

  setup do
    @connection = ActiveRecord::Base.connection
    @search_path = @connection.schema_search_path
    @lock_timeout = StrongMigrations.lock_timeout
    @statement_timeout = StrongMigrations.statement_timeout
    @session_lock_timeout = @connection.select_value("SHOW lock_timeout")
    @session_statement_timeout = @connection.select_value("SHOW statement_timeout")
    StrongMigrations.lock_timeout = 0.1
    StrongMigrations.statement_timeout = 5

    # Keep DDL outside Rails' test transactions and away from application tables.
    @schema = "recently_published_index_test_#{Process.pid}"
    @connection.execute("CREATE SCHEMA #{@schema}")
    @connection.schema_search_path = @schema
    @connection.execute(<<~SQL.squish)
      CREATE TABLE versions (
        id bigint, rubygem_id bigint, created_at timestamp, indexed boolean,
        position integer, full_name text, number text, platform text
      )
    SQL
    @connection.execute("INSERT INTO versions (id, rubygem_id, created_at, indexed) VALUES (1, 1, now(), true)")
    @connection.execute(<<~SQL.squish)
      CREATE INDEX #{POSITION_INDEX_NAME} ON versions (rubygem_id, position, created_at DESC)
      INCLUDE (full_name, number, platform) WHERE indexed = true
    SQL
    @position_index = index_state(POSITION_INDEX_NAME)
    @connection_options = @connection.raw_connection.conninfo_hash.compact_blank
    @blocker = PG.connect(@connection_options)
    @blocker.exec("SET search_path TO #{@schema}")
  end

  teardown do
    @blocker&.close
    @connection.schema_search_path = @search_path
    @connection.execute("DROP SCHEMA #{@schema} CASCADE")
    @connection.execute("SET lock_timeout = #{@connection.quote(@session_lock_timeout)}")
    @connection.execute("SET statement_timeout = #{@connection.quote(@session_statement_timeout)}")
    StrongMigrations.lock_timeout = @lock_timeout
    StrongMigrations.statement_timeout = @statement_timeout
  end

  test "waits beyond the normal lock timeout without blocking new writes and preserves valid indexes on retry" do
    @blocker.exec("BEGIN; UPDATE versions SET indexed = true WHERE id = 1")
    release = release_blocker_after_wait do
      # The index builder must not block ordinary writes while waiting.
      PG.connect(@connection_options) do |writer|
        writer.exec("SET search_path TO #{@schema}; SET statement_timeout = '1s'")
        writer.exec("INSERT INTO versions (id) VALUES (2)")
      end
    end
    begin
      AddRecentlyPublishedIndexToVersions.new.migrate(:up)
    ensure
      release.value
    end

    assert_index_valid
    assert_equal 1, @connection.select_value("SELECT count(*) FROM versions WHERE id = 2")
    assert_equal "100ms", @connection.select_value("SHOW lock_timeout")
    valid_index = index_state(INDEX_NAME)
    AddRecentlyPublishedIndexToVersions.new.migrate(:up)

    assert_equal valid_index, index_state(INDEX_NAME)

    AddRecentlyPublishedIndexToVersions.new.migrate(:down)

    assert_nil index_state(INDEX_NAME)
    assert_equal @position_index, index_state(POSITION_INDEX_NAME)
  end

  test "rebuilds invalid residue from an interrupted concurrent build" do
    @blocker.exec("BEGIN; UPDATE versions SET indexed = true WHERE id = 1")
    @connection.execute("SET lock_timeout = '100ms'")
    assert_raises(ActiveRecord::LockWaitTimeout) { @connection.execute(CREATE_INDEX) }
    @blocker.exec("ROLLBACK")
    invalid_index = index_state(INDEX_NAME)

    refute invalid_index.fetch("indisvalid")
    refute invalid_index.fetch("indisready")

    AddRecentlyPublishedIndexToVersions.new.migrate(:up)

    assert_index_valid
    refute_equal invalid_index.fetch("oid"), index_state(INDEX_NAME).fetch("oid")
    assert_equal "100ms", @connection.select_value("SHOW lock_timeout")
  end

  test "restores the lock timeout after cancellation and recovers a ready but invalid index" do
    # An old snapshot waits at a later build phase, after the index is ready for writes.
    @blocker.exec("BEGIN ISOLATION LEVEL REPEATABLE READ; SELECT * FROM versions")
    StrongMigrations.statement_timeout = 0.2
    release = release_blocker_after_wait
    begin
      assert_raises(ActiveRecord::QueryCanceled) { AddRecentlyPublishedIndexToVersions.new.migrate(:up) }
    ensure
      release.value
    end

    assert_equal "100ms", @connection.select_value("SHOW lock_timeout")
    assert_equal "200ms", @connection.select_value("SHOW statement_timeout")
    refute index_state(INDEX_NAME).fetch("indisvalid")
    assert index_state(INDEX_NAME).fetch("indisready")

    StrongMigrations.statement_timeout = 5
    AddRecentlyPublishedIndexToVersions.new.migrate(:up)

    assert_index_valid
  end

  private

  def index_state(name)
    @connection.select_one(<<~SQL.squish)
      SELECT indexrelid AS oid, indisvalid, indisready, pg_get_indexdef(indexrelid) AS definition
      FROM pg_index WHERE indexrelid = to_regclass(#{@connection.quote(name)})
    SQL
  end

  def assert_index_valid
    index = index_state(INDEX_NAME)

    assert index.fetch("indisvalid")
    assert index.fetch("indisready")
    assert_equal "CREATE INDEX #{INDEX_NAME} ON #{@schema}.versions USING btree (rubygem_id, created_at DESC) WHERE (indexed = true)",
      index.fetch("definition")
    assert_equal @position_index, index_state(POSITION_INDEX_NAME)
  end

  def release_blocker_after_wait
    migration_pid = @connection.raw_connection.backend_pid
    Thread.new do
      Timeout.timeout(5) do
        loop do
          waiting = @blocker.exec("SELECT cardinality(pg_blocking_pids(#{migration_pid})) > 0").getvalue(0, 0)
          break if waiting == "t"
          sleep 0.01
        end
      end
      yield if block_given?
      sleep 0.3 # Longer than the test's normal migration lock timeout.
    ensure
      @blocker.exec("ROLLBACK")
    end
  end
end
