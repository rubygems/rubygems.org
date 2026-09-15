# frozen_string_literal: true

class AddLowerNameIndexToRubygems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :rubygems, "lower(name)",
      name: :index_rubygems_on_lower_name,
      algorithm: :concurrently
  end

  def down
    remove_index :rubygems, name: :index_rubygems_on_lower_name, algorithm: :concurrently
  end
end
