# frozen_string_literal: true

class AddOrganizationsToGemNameReservation < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference(:gem_name_reservations,
                  :organization,
                  null: true,
                  index: { algorithm: :concurrently })
  end
end
