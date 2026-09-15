# frozen_string_literal: true

class CreateEmailDomainAllowlists < ActiveRecord::Migration[8.0]
  def change
    create_table :email_domain_allowlists do |t|
      t.string :domain, null: false
      t.text :notes

      t.timestamps
    end

    add_index :email_domain_allowlists, :domain, unique: true
  end
end
