class AddRubyVersionToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :ruby_version, :string
  end
end
