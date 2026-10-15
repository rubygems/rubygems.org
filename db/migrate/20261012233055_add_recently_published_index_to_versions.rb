# frozen_string_literal: true

class AddRecentlyPublishedIndexToVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Initialize Strong Migrations' timeouts before overriding this session's lock timeout.
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      # Concurrent builds wait for existing transactions without blocking ordinary writes.
      # Keep the statement timeout and deployment deadline as the overall bounds.
      safety_assured { execute "SET lock_timeout = 0" }

      # A canceled concurrent build can leave an invalid index. IF NOT EXISTS alone
      # would silently keep it instead of building a usable index on the next attempt.
      if index_exists?(:versions, name: :index_versions_on_rubygem_id_and_created_at, valid: false)
        remove_index :versions, name: :index_versions_on_rubygem_id_and_created_at, algorithm: :concurrently
      end

      add_index :versions, %i[rubygem_id created_at],
        order: { created_at: :desc },
        where: "indexed = true",
        algorithm: :concurrently,
        if_not_exists: true
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end

  def down
    remove_index :versions, name: :index_versions_on_rubygem_id_and_created_at, algorithm: :concurrently
  end
end
