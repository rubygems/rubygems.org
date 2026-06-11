# frozen_string_literal: true

class CreateBlockedEmailDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :blocked_email_domains do |t|
      t.string :domain, null: false
      t.integer :source, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :blocked_email_domains, :domain, unique: true
    add_index :blocked_email_domains, :source
  end
end
