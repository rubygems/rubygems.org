class AddChangelogToLinksets < ActiveRecord::Migration
  def change
    add_column :linksets, :changelog, :string
  end
end
