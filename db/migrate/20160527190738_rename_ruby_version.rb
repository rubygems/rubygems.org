class RenameRubyVersion < ActiveRecord::Migration
  def change
    rename_column :versions, :ruby_version, :required_ruby_version
  end
end
