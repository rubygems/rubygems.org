class RemoveOIDCProviderFromOIDCIdToken < ActiveRecord::Migration[7.0]
  def change
    remove_column :oidc_id_tokens, :oidc_provider_id, null: false
  end
end
