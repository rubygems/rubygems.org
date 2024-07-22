class AddRequiredRubygemsVersion < ActiveRecord::Migration[4.2]
  def up
    change_table(:versions, bulk: true) do |t|
      t.remove :rubygems_version
      t.string :required_rubygems_version
    end
  end

  def down
    change_table(:versions, bulk: true) do |t|
      t.remove :required_rubygems_version
      t.string :rubygems_version
    end
  end
end
