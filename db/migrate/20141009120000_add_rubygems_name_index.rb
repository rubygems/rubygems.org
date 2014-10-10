class AddRubygemsNameIndex < ActiveRecord::Migration
  def up
    # add_index :rubygems, 'upper(name) varchar_pattern_ops', :name => :rubygems_name_upcase
    execute "CREATE INDEX index_rubygems_upcase ON rubygems (upper(name) varchar_pattern_ops)"
  end

  def down
    remove_index :rubygems, :name => :rubygems_name_upcase
  end
end
