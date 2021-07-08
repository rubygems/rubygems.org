class AddCertChainToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :cert_chain, :text
  end
end
