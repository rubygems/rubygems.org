class AddIndexToVersions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!
  def change
    add_index :versions, %w[rubygem_id position created_at], order: { position: :asc, created_at: :desc },
      where: "indexed = true",
      include: %i[full_name number platform],
      algorithm: :concurrently
  end
end
