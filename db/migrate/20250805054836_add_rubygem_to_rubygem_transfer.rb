class AddRubygemToRubygemTransfer < ActiveRecord::Migration[8.0]
  def change
    add_column :rubygem_transfers, :rubygems, :integer, array: true, default: []

    safety_assured do
      remove_column :rubygem_transfers, :rubygem_id, :integer
    end
  end
end
