class OwnershipForeignKey < ActiveRecord::Migration[7.0]
  def up
    add_foreign_key :ownerships, :users, on_delete: :cascade
  end

  def down
    remove_foreign_key :ownerships, :users
  end
end
