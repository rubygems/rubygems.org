class CreateVersionBuiltAtMultiIndex < ActiveRecord::Migration[5.1]
  def change
    # Used on VersionsController#show
    add_index :versions, [:rubygem_id, :built_at]
  end
end
