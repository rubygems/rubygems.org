# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_11_02_190427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "admin_github_users", force: :cascade do |t|
    t.string "login"
    t.string "avatar_url"
    t.string "github_id"
    t.json "info_data"
    t.string "oauth_token"
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_admin_github_users_on_github_id", unique: true
  end

  create_table "api_key_rubygem_scopes", force: :cascade do |t|
    t.bigint "api_key_id", null: false
    t.bigint "ownership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_id"], name: "index_api_key_rubygem_scopes_on_api_key_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "hashed_key", null: false
    t.boolean "index_rubygems", default: false, null: false
    t.boolean "push_rubygem", default: false, null: false
    t.boolean "yank_rubygem", default: false, null: false
    t.boolean "add_owner", default: false, null: false
    t.boolean "remove_owner", default: false, null: false
    t.boolean "access_webhooks", default: false, null: false
    t.boolean "show_dashboard", default: false, null: false
    t.datetime "last_accessed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "mfa", default: false, null: false
    t.datetime "soft_deleted_at"
    t.string "soft_deleted_rubygem_name"
    t.datetime "expires_at", precision: nil
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["hashed_key"], name: "index_api_keys_on_hashed_key", unique: true
    t.index ["owner_type", "owner_id"], name: "index_api_keys_on_owner"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "audits", force: :cascade do |t|
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.bigint "admin_github_user_id", null: false
    t.text "audited_changes"
    t.string "comment"
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_github_user_id"], name: "index_audits_on_admin_github_user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audits_on_auditable"
  end

  create_table "deletions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "rubygem"
    t.string "number"
    t.string "platform"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_deletions_on_user_id"
  end

  create_table "dependencies", id: :serial, force: :cascade do |t|
    t.string "requirements"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "rubygem_id"
    t.integer "version_id"
    t.string "scope"
    t.string "unresolved_name"
    t.index ["rubygem_id"], name: "index_dependencies_on_rubygem_id"
    t.index ["unresolved_name"], name: "index_dependencies_on_unresolved_name"
    t.index ["version_id"], name: "index_dependencies_on_version_id"
  end

  create_table "gem_downloads", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id", null: false
    t.integer "version_id", null: false
    t.bigint "count"
    t.index ["count"], name: "index_gem_downloads_on_count", order: :desc
    t.index ["rubygem_id", "version_id"], name: "index_gem_downloads_on_rubygem_id_and_version_id", unique: true
    t.index ["version_id", "rubygem_id", "count"], name: "index_gem_downloads_on_version_id_and_rubygem_id_and_count"
  end

  create_table "gem_name_reservations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_gem_name_reservations_on_name", unique: true
  end

  create_table "gem_typo_exceptions", force: :cascade do |t|
    t.string "name"
    t.text "info"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "link_verifications", force: :cascade do |t|
    t.string "linkable_type", null: false
    t.bigint "linkable_id", null: false
    t.string "uri", null: false
    t.datetime "last_verified_at"
    t.datetime "last_failure_at"
    t.integer "failures_since_last_verification", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linkable_id", "linkable_type", "uri"], name: "index_link_verifications_on_linkable_and_uri"
    t.index ["linkable_type", "linkable_id"], name: "index_link_verifications_on_linkable"
  end

  create_table "linksets", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id"
    t.string "home"
    t.string "wiki"
    t.string "docs"
    t.string "mail"
    t.string "code"
    t.string "bugs"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["rubygem_id"], name: "index_linksets_on_rubygem_id"
  end

  create_table "log_tickets", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "directory"
    t.integer "backend", default: 0
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "processed_count"
    t.index ["directory", "key"], name: "index_log_tickets_on_directory_and_key", unique: true
  end

  create_table "maintenance_tasks_runs", force: :cascade do |t|
    t.string "task_name", null: false
    t.datetime "started_at", precision: nil
    t.datetime "ended_at", precision: nil
    t.float "time_running", default: 0.0, null: false
    t.bigint "tick_count", default: 0, null: false
    t.bigint "tick_total"
    t.string "job_id"
    t.string "cursor"
    t.string "status", default: "enqueued", null: false
    t.string "error_class"
    t.string "error_message"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "arguments"
    t.integer "lock_version", default: 0, null: false
    t.text "metadata"
    t.index ["task_name", "status", "created_at"], name: "index_maintenance_tasks_runs", order: { created_at: :desc }
  end

  create_table "oidc_api_key_roles", force: :cascade do |t|
    t.bigint "oidc_provider_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "api_key_permissions", null: false
    t.string "name", null: false
    t.jsonb "access_policy", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token", limit: 32, null: false
    t.datetime "deleted_at"
    t.index ["oidc_provider_id"], name: "index_oidc_api_key_roles_on_oidc_provider_id"
    t.index ["token"], name: "index_oidc_api_key_roles_on_token", unique: true
    t.index ["user_id"], name: "index_oidc_api_key_roles_on_user_id"
  end

  create_table "oidc_id_tokens", force: :cascade do |t|
    t.bigint "oidc_api_key_role_id", null: false
    t.jsonb "jwt", null: false
    t.bigint "api_key_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_id"], name: "index_oidc_id_tokens_on_api_key_id"
    t.index ["oidc_api_key_role_id"], name: "index_oidc_id_tokens_on_oidc_api_key_role_id"
  end

  create_table "oidc_providers", force: :cascade do |t|
    t.text "issuer"
    t.jsonb "configuration"
    t.jsonb "jwks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issuer"], name: "index_oidc_providers_on_issuer", unique: true
  end

  create_table "ownership_calls", force: :cascade do |t|
    t.bigint "rubygem_id"
    t.bigint "user_id"
    t.text "note"
    t.boolean "status", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rubygem_id"], name: "index_ownership_calls_on_rubygem_id"
    t.index ["user_id"], name: "index_ownership_calls_on_user_id"
  end

  create_table "ownership_requests", force: :cascade do |t|
    t.bigint "rubygem_id"
    t.bigint "ownership_call_id"
    t.bigint "user_id"
    t.text "note"
    t.integer "status", limit: 2, default: 0, null: false
    t.integer "approver_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ownership_call_id"], name: "index_ownership_requests_on_ownership_call_id"
    t.index ["rubygem_id"], name: "index_ownership_requests_on_rubygem_id"
    t.index ["user_id"], name: "index_ownership_requests_on_user_id"
  end

  create_table "ownerships", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id"
    t.integer "user_id"
    t.string "token"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "push_notifier", default: true, null: false
    t.datetime "confirmed_at", precision: nil
    t.datetime "token_expires_at", precision: nil
    t.boolean "owner_notifier", default: true, null: false
    t.integer "authorizer_id"
    t.boolean "ownership_request_notifier", default: true, null: false
    t.index ["rubygem_id"], name: "index_ownerships_on_rubygem_id"
    t.index ["user_id", "rubygem_id"], name: "index_ownerships_on_user_id_and_rubygem_id", unique: true
    t.index ["user_id"], name: "index_ownerships_on_user_id"
  end

  create_table "rubygems", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "indexed", default: false, null: false
    t.index "regexp_replace(upper((name)::text), '[_-]'::text, ''::text, 'g'::text)", name: "dashunderscore_typos_idx"
    t.index "upper((name)::text) varchar_pattern_ops", name: "index_rubygems_upcase"
    t.index ["indexed"], name: "index_rubygems_on_indexed"
    t.index ["name"], name: "index_rubygems_on_name", unique: true
  end

  create_table "sendgrid_events", force: :cascade do |t|
    t.string "sendgrid_id", null: false
    t.string "email"
    t.string "event_type"
    t.datetime "occurred_at", precision: nil
    t.jsonb "payload", null: false
    t.string "status", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_sendgrid_events_on_email"
    t.index ["sendgrid_id"], name: "index_sendgrid_events_on_sendgrid_id", unique: true
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["rubygem_id"], name: "index_subscriptions_on_rubygem_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", limit: 128
    t.string "salt", limit: 128
    t.string "token", limit: 128
    t.datetime "token_expires_at", precision: nil
    t.boolean "email_confirmed", default: false, null: false
    t.string "api_key"
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "email_reset"
    t.string "handle"
    t.boolean "hide_email", default: true
    t.string "twitter_username"
    t.string "unconfirmed_email"
    t.datetime "remember_token_expires_at", precision: nil
    t.integer "mfa_level", default: 0
    t.integer "mail_fails", default: 0
    t.string "blocked_email"
    t.string "webauthn_id"
    t.string "full_name"
    t.string "totp_seed"
    t.string "mfa_hashed_recovery_codes", default: [], array: true
    t.boolean "public_email", default: false, null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["handle"], name: "index_users_on_handle"
    t.index ["id", "confirmation_token"], name: "index_users_on_id_and_confirmation_token"
    t.index ["id", "token"], name: "index_users_on_id_and_token"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["token"], name: "index_users_on_token"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.text "authors"
    t.text "description"
    t.string "number"
    t.integer "rubygem_id"
    t.datetime "built_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "summary"
    t.string "platform"
    t.datetime "created_at", precision: nil
    t.boolean "indexed", default: true
    t.boolean "prerelease"
    t.integer "position"
    t.boolean "latest"
    t.string "full_name"
    t.integer "size"
    t.string "licenses"
    t.text "requirements"
    t.string "required_ruby_version"
    t.string "sha256"
    t.hstore "metadata", default: {}, null: false
    t.datetime "yanked_at", precision: nil
    t.string "required_rubygems_version", limit: 255
    t.string "info_checksum"
    t.string "yanked_info_checksum"
    t.bigint "pusher_id"
    t.text "cert_chain"
    t.string "canonical_number"
    t.bigint "pusher_api_key_id"
    t.string "gem_platform"
    t.string "gem_full_name"
    t.string "spec_sha256", limit: 44
    t.index "lower((full_name)::text)", name: "index_versions_on_lower_full_name"
    t.index "lower((gem_full_name)::text)", name: "index_versions_on_lower_gem_full_name"
    t.index ["built_at"], name: "index_versions_on_built_at"
    t.index ["canonical_number", "rubygem_id", "platform"], name: "index_versions_on_canonical_number_and_rubygem_id_and_platform", unique: true
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["full_name"], name: "index_versions_on_full_name"
    t.index ["indexed", "yanked_at"], name: "index_versions_on_indexed_and_yanked_at"
    t.index ["indexed"], name: "index_versions_on_indexed"
    t.index ["number"], name: "index_versions_on_number"
    t.index ["position", "rubygem_id"], name: "index_versions_on_position_and_rubygem_id"
    t.index ["prerelease"], name: "index_versions_on_prerelease"
    t.index ["pusher_api_key_id"], name: "index_versions_on_pusher_api_key_id"
    t.index ["pusher_id"], name: "index_versions_on_pusher_id"
    t.index ["rubygem_id", "number", "platform"], name: "index_versions_on_rubygem_id_and_number_and_platform", unique: true
    t.index ["rubygem_id"], name: "index_versions_on_rubygem_id"
  end

  create_table "web_hooks", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "url"
    t.integer "failure_count", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "rubygem_id"
    t.text "disabled_reason"
    t.datetime "disabled_at", precision: nil
    t.datetime "last_success", precision: nil
    t.datetime "last_failure", precision: nil
    t.integer "successes_since_last_failure", default: 0
    t.integer "failures_since_last_success", default: 0
    t.index ["user_id", "rubygem_id"], name: "index_web_hooks_on_user_id_and_rubygem_id"
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "external_id", null: false
    t.string "public_key", null: false
    t.string "nickname", null: false
    t.bigint "sign_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_webauthn_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_webauthn_credentials_on_user_id"
  end

  create_table "webauthn_verifications", force: :cascade do |t|
    t.string "path_token", limit: 128
    t.datetime "path_token_expires_at"
    t.string "otp"
    t.datetime "otp_expires_at"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_webauthn_verifications_on_user_id", unique: true
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "oidc_api_key_roles", "oidc_providers"
  add_foreign_key "oidc_api_key_roles", "users"
  add_foreign_key "oidc_id_tokens", "api_keys"
  add_foreign_key "oidc_id_tokens", "oidc_api_key_roles"
  add_foreign_key "ownerships", "users", on_delete: :cascade
  add_foreign_key "versions", "api_keys", column: "pusher_api_key_id"
  add_foreign_key "webauthn_credentials", "users"
  add_foreign_key "webauthn_verifications", "users"
end
