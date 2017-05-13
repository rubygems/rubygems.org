class LinkWebHookToRubygems < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :web_hooks, :gem_name
    add_column :web_hooks, :rubygem_id, :integer
  end

  def self.down
    remove_column :web_hooks, :rubygem_id
    add_column :web_hooks, :gem_name, :string
  end
end
