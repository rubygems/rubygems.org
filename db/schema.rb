# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_22_144428) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "announcements", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "queue"
  end

  create_table "deletions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "rubygem"
    t.string "number"
    t.string "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_deletions_on_user_id"
  end

  create_table "dependencies", id: :serial, force: :cascade do |t|
    t.string "requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.index ["rubygem_id", "version_id"], name: "index_gem_downloads_on_rubygem_id_and_version_id", unique: true
    t.index ["version_id", "rubygem_id", "count"], name: "index_gem_downloads_on_version_id_and_rubygem_id_and_count"
  end

  create_table "linksets", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id"
    t.string "home"
    t.string "wiki"
    t.string "docs"
    t.string "mail"
    t.string "code"
    t.string "bugs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rubygem_id"], name: "index_linksets_on_rubygem_id"
  end

  create_table "log_tickets", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "directory"
    t.integer "backend", default: 0
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "processed_count"
    t.index ["directory", "key"], name: "index_log_tickets_on_directory_and_key", unique: true
  end

  create_table "ownerships", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id"
    t.integer "user_id"
    t.string "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "notifier", default: true, null: false
    t.index ["rubygem_id"], name: "index_ownerships_on_rubygem_id"
    t.index ["user_id"], name: "index_ownerships_on_user_id"
  end

  create_table "rubygems", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.index "upper((name)::text) varchar_pattern_ops", name: "index_rubygems_upcase"
    t.index ["name"], name: "index_rubygems_on_name", unique: true
  end

  create_table "sendgrid_events", force: :cascade do |t|
    t.string "sendgrid_id", null: false
    t.string "email"
    t.string "event_type"
    t.datetime "occurred_at"
    t.jsonb "payload", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_sendgrid_events_on_email"
    t.index ["sendgrid_id"], name: "index_sendgrid_events_on_sendgrid_id", unique: true
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "rubygem_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rubygem_id"], name: "index_subscriptions_on_rubygem_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", limit: 128
    t.string "salt", limit: 128
    t.string "token", limit: 128
    t.datetime "token_expires_at"
    t.boolean "email_confirmed", default: false, null: false
    t.string "api_key"
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "email_reset"
    t.string "handle"
    t.boolean "hide_email"
    t.string "twitter_username"
    t.string "unconfirmed_email"
    t.datetime "remember_token_expires_at"
    t.string "mfa_seed"
    t.integer "mfa_level", default: 0
    t.string "mfa_recovery_codes", default: [], array: true
    t.integer "mail_fails", default: 0
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
    t.datetime "built_at"
    t.datetime "updated_at"
    t.text "summary"
    t.string "platform"
    t.datetime "created_at"
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
    t.datetime "yanked_at"
    t.string "required_rubygems_version"
    t.string "info_checksum"
    t.string "yanked_info_checksum"
    t.bigint "pusher_id"
    t.index "lower((full_name)::text)", name: "index_versions_on_lower_full_name"
    t.index ["built_at"], name: "index_versions_on_built_at"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["full_name"], name: "index_versions_on_full_name"
    t.index ["indexed"], name: "index_versions_on_indexed"
    t.index ["number"], name: "index_versions_on_number"
    t.index ["position"], name: "index_versions_on_position"
    t.index ["prerelease"], name: "index_versions_on_prerelease"
    t.index ["pusher_id"], name: "index_versions_on_pusher_id"
    t.index ["rubygem_id", "number", "platform"], name: "index_versions_on_rubygem_id_and_number_and_platform", unique: true
    t.index ["rubygem_id"], name: "index_versions_on_rubygem_id"
  end

  create_table "web_hooks", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "url"
    t.integer "failure_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "rubygem_id"
    t.index ["user_id", "rubygem_id"], name: "index_web_hooks_on_user_id_and_rubygem_id"
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.bigint "user_id"
    t.string "external_id", null: false
    t.text "public_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nickname", null: false
    t.integer "sign_count", default: 0, null: false
    t.index ["user_id"], name: "index_webauthn_credentials_on_user_id"
  end

  add_foreign_key "webauthn_credentials", "users"
end
