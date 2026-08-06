# frozen_string_literal: true

class AddRubyAbiToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :ruby_abi, :string
  end
end
