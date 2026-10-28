# frozen_string_literal: true

class ReplaceUnresolvedDependencyIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Initialize Strong Migrations' timeouts before allowing concurrent DDL to wait.
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      safety_assured { execute "SET lock_timeout = 0" }

      if index_exists?(:dependencies, name: :index_dependencies_on_unresolved_name_and_id_nonnull, valid: false)
        remove_index :dependencies, name: :index_dependencies_on_unresolved_name_and_id_nonnull, algorithm: :concurrently
      end

      # Resolved dependencies need no entry; ID ordering serves find_each batches.
      add_index :dependencies, %i[unresolved_name id],
        name: :index_dependencies_on_unresolved_name_and_id_nonnull,
        where: "unresolved_name IS NOT NULL",
        algorithm: :concurrently,
        if_not_exists: true

      remove_index :dependencies, name: :index_dependencies_on_unresolved_name,
        algorithm: :concurrently, if_exists: true
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end

  def down
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      safety_assured { execute "SET lock_timeout = 0" }

      if index_exists?(:dependencies, name: :index_dependencies_on_unresolved_name, valid: false)
        remove_index :dependencies, name: :index_dependencies_on_unresolved_name, algorithm: :concurrently
      end

      # Restore the original access path before removing its replacement.
      add_index :dependencies, :unresolved_name,
        name: :index_dependencies_on_unresolved_name,
        algorithm: :concurrently,
        if_not_exists: true

      remove_index :dependencies, name: :index_dependencies_on_unresolved_name_and_id_nonnull,
        algorithm: :concurrently, if_exists: true
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end
end
