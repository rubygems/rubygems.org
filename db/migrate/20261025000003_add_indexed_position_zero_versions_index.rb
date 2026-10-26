# frozen_string_literal: true

class AddIndexedPositionZeroVersionsIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Initialize Strong Migrations' timeouts before allowing concurrent DDL to wait.
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      safety_assured { execute "SET lock_timeout = 0" }

      if index_exists?(:versions, name: :index_versions_on_id_for_indexed_position_zero, valid: false)
        remove_index :versions, name: :index_versions_on_id_for_indexed_position_zero, algorithm: :concurrently
      end

      # Reverse dependencies use position zero, which is not equivalent to latest.
      add_index :versions, :id,
        name: :index_versions_on_id_for_indexed_position_zero,
        include: :rubygem_id,
        where: "indexed AND position = 0",
        algorithm: :concurrently,
        if_not_exists: true
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end

  def down
    remove_index :versions, name: :index_versions_on_id_for_indexed_position_zero,
      algorithm: :concurrently, if_exists: true
  end
end
