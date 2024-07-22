class RemoveTimestampsOnVersionHistory < ActiveRecord::Migration[4.2]
  def up
    change_table(:version_histories, bulk: true) do |t|
      t.remove :created_at
      t.remove :updated_at
    end
  end

  def down
  end
end
