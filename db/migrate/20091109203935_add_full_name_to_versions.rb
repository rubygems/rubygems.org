class AddFullNameToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :full_name, :string

    Version.without_any_callbacks do
      Version.all(:include => :rubygem).each do |version|
        version.full_nameify!
      end
    end

    add_index 'versions', 'full_name'
  end

  def self.down
    remove_index 'versions', 'full_name'
    remove_column :versions, :full_name
  end
end
