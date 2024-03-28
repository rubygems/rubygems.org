class ValidateNewKeys < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key "api_key_rubygem_scopes", "api_keys", name: "api_key_rubygem_scopes_api_key_id_fk"
    validate_foreign_key "audits", "admin_github_users", name: "audits_admin_github_user_id_fk"
    validate_foreign_key "ownership_calls", "rubygems", name: "ownership_calls_rubygem_id_fk"
    validate_foreign_key "ownership_calls", "users", name: "ownership_calls_user_id_fk"
    validate_foreign_key "ownership_requests", "users", column: "approver_id", name: "ownership_requests_approver_id_fk"
    validate_foreign_key "ownership_requests", "ownership_calls", name: "ownership_requests_ownership_call_id_fk"
    validate_foreign_key "ownership_requests", "rubygems", name: "ownership_requests_rubygem_id_fk"
    validate_foreign_key "ownership_requests", "users", name: "ownership_requests_user_id_fk"
    validate_foreign_key "versions", "rubygems", name: "versions_rubygem_id_fk"
    validate_foreign_key "web_hooks", "users", name: "web_hooks_user_id_fk"
  end
end
