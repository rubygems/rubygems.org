# frozen_string_literal: true

class AddYankedAtToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :yanked_at, :datetime
  end
end
