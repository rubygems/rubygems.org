# frozen_string_literal: true

class AddPushNotifierToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :push_notifier, :boolean, default: true, null: false
  end
end
