class AddUniqueVersionsCanonicalVersionIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :versions, [:canonical_number ,:rubygem_id, :platform], unique: true, algorithm: :concurrently
  end
end
