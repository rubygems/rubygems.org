class AddRubyVersionToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :ruby_version, :string
  end
end
