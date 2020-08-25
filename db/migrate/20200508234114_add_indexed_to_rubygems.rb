class AddIndexedToRubygems < ActiveRecord::Migration[6.0]
  def change
    add_column :rubygems, :indexed, :boolean, null: false, default: false
    add_index :rubygems, :indexed

    say_with_time "populating indexed rubygems table column" do
      Rubygem.joins(:versions).where(versions: {indexed: true}).update_all(indexed: true)
    end
  end
end
