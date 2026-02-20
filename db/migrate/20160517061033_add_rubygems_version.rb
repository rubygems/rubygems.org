# frozen_string_literal: true

class AddRubygemsVersion < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :rubygems_version, :string
  end
end
