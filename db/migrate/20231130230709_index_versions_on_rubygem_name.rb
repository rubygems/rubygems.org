class IndexVersionsOnRubygemName < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :versions, :rubygem_name, algorithm: :concurrently
  end
end
