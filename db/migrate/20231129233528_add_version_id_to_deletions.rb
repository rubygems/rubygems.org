class AddVersionIdToDeletions < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :deletions, :version, index: {algorithm: :concurrently}
  end
end
