class RemoveOrphanedOwners < ActiveRecord::Migration[7.0]
  def up
    Ownership.where.missing(:user).destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
