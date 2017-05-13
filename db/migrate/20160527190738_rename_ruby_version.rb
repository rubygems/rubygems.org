class RenameRubyVersion < ActiveRecord::Migration[4.2]
  def change
    rename_column :versions, :ruby_version, :required_ruby_version
  end
end
