# frozen_string_literal: true

class AddRubygemNameTrigramIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :rubygems, :name,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: :index_rubygems_on_name_trigram,
      algorithm: :concurrently
  end

  def down
    remove_index :rubygems, name: :index_rubygems_on_name_trigram, algorithm: :concurrently
  end
end
