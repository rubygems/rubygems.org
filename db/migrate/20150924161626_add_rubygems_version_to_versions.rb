class AddRubygemsVersionToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :rubygems_version, :string
  end
end
