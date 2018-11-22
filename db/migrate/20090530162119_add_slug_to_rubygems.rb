class AddSlugToRubygems < ActiveRecord::Migration[4.2]
  def self.up
    add_column :rubygems, :slug, :string
  end

  def self.down
    remove_column :rubygems, :slug
  end
end
