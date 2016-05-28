class AddRequiredRubygemsVersion < ActiveRecord::Migration
  def change
    remove_column :versions, :rubygems_version, :string
    add_column :versions, :required_rubygems_version, :string
  end
end
