class AddRequiredRubygemsVersion < ActiveRecord::Migration[4.2]
  def change
    remove_column :versions, :rubygems_version, :string # rubocop:disable Rails/BulkChangeTable
    add_column :versions, :required_rubygems_version, :string
  end
end
