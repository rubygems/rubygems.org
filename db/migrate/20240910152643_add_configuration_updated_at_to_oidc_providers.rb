class AddConfigurationUpdatedAtToOIDCProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :oidc_providers, :configuration_updated_at, :timestamp
  end
end
