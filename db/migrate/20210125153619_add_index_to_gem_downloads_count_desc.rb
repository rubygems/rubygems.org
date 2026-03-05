# frozen_string_literal: true

class AddIndexToGemDownloadsCountDesc < ActiveRecord::Migration[6.1]
  def change
    add_index :gem_downloads, [:count], order: { count: :desc }
  end
end
