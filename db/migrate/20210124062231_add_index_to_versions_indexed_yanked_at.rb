class AddIndexToVersionsIndexedYankedAt < ActiveRecord::Migration[6.1]
  def change
    add_index :versions, %i[indexed yanked_at]
  end
end
