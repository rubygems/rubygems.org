# frozen_string_literal: true

class RenameOwnershipNotifier < ActiveRecord::Migration[6.0]
  def change
    rename_column :ownerships, :notifier, :push_notifier
  end
end
