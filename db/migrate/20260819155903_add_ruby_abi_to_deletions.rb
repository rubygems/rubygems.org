# frozen_string_literal: true

class AddRubyAbiToDeletions < ActiveRecord::Migration[8.1]
  def change
    add_column :deletions, :ruby_abi, :string, if_not_exists: true
  end
end
