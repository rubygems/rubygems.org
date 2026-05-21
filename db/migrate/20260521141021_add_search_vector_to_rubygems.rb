# frozen_string_literal: true

class AddSearchVectorToRubygems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :rubygems, :search_vector, :tsvector

    add_index :rubygems, :search_vector,
      using: :gin,
      name: "index_rubygems_on_search_vector",
      algorithm: :concurrently
  end
end
