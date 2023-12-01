class AddRubygemNameToVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :versions, :rubygem_name, :string
  end
end
