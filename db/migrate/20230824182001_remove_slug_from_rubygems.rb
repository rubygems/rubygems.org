class RemoveSlugFromRubygems < ActiveRecord::Migration[7.0]
  def change
    remove_column :rubygems, :slug, :string
  end
end
