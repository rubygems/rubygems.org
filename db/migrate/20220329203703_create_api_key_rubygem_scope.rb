class CreateApiKeyRubygemScope < ActiveRecord::Migration[7.0]
  def change
    create_table :api_key_rubygem_scopes do |t|
      t.references :api_key, null: false
      t.references :ownership, null: false, index: false
      t.timestamps
    end
  end
end
