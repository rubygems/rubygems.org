class ChangeApiKeyOwnerToNotNull < ActiveRecord::Migration[7.0]
  def change
    add_check_constraint :api_keys, "owner_id IS NOT NULL", name: "api_keys_owner_id_null", validate: false
    add_check_constraint :api_keys, "owner_type IS NOT NULL", name: "api_keys_owner_type_null", validate: false
  end
end
