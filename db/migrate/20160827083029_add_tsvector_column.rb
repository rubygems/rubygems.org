class AddTsvectorColumn < ActiveRecord::Migration
  def up
    add_column :rubygems, :tsv, :tsvector
    execute "UPDATE rubygems SET tsv = to_tsvector(name);"
    add_index :rubygems, :tsv, using: 'gin'
  end

  def down
    remove_column :rubygems, :tsv
  end
end
