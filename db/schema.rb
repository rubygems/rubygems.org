# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161222090545) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "announcements", force: :cascade do |t|
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
  end

  create_table "deletions", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "rubygem"
    t.string   "number"
    t.string   "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "deletions", ["user_id"], name: "index_deletions_on_user_id", using: :btree

  create_table "dependencies", force: :cascade do |t|
    t.string   "requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rubygem_id"
    t.integer  "version_id"
    t.string   "scope"
    t.string   "unresolved_name"
  end

  add_index "dependencies", ["rubygem_id"], name: "index_dependencies_on_rubygem_id", using: :btree
  add_index "dependencies", ["unresolved_name"], name: "index_dependencies_on_unresolved_name", using: :btree
  add_index "dependencies", ["version_id"], name: "index_dependencies_on_version_id", using: :btree

  create_table "gem_downloads", force: :cascade do |t|
    t.integer "rubygem_id",           null: false
    t.integer "version_id",           null: false
    t.integer "count",      limit: 8
  end

  add_index "gem_downloads", ["rubygem_id", "version_id"], name: "index_gem_downloads_on_rubygem_id_and_version_id", unique: true, using: :btree
  add_index "gem_downloads", ["version_id", "rubygem_id", "count"], name: "index_gem_downloads_on_version_id_and_rubygem_id_and_count", using: :btree

  create_table "linksets", force: :cascade do |t|
    t.integer  "rubygem_id"
    t.string   "home"
    t.string   "wiki"
    t.string   "docs"
    t.string   "mail"
    t.string   "code"
    t.string   "bugs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "linksets", ["rubygem_id"], name: "index_linksets_on_rubygem_id", using: :btree

  create_table "log_tickets", force: :cascade do |t|
    t.string   "key"
    t.string   "directory"
    t.integer  "backend",         default: 0
    t.string   "status"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "processed_count"
  end

  add_index "log_tickets", ["directory", "key"], name: "index_log_tickets_on_directory_and_key", unique: true, using: :btree

  create_table "ownerships", force: :cascade do |t|
    t.integer  "rubygem_id"
    t.integer  "user_id"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ownerships", ["rubygem_id"], name: "index_ownerships_on_rubygem_id", using: :btree
  add_index "ownerships", ["user_id"], name: "index_ownerships_on_user_id", using: :btree

  create_table "rubygems", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "rubygems", ["name"], name: "index_rubygems_on_name", unique: true, using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "rubygem_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["rubygem_id"], name: "index_subscriptions_on_rubygem_id", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "encrypted_password", limit: 128
    t.string   "salt",               limit: 128
    t.string   "token",              limit: 128
    t.datetime "token_expires_at"
    t.boolean  "email_confirmed",                default: false, null: false
    t.string   "api_key"
    t.string   "confirmation_token", limit: 128
    t.string   "remember_token",     limit: 128
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "email_reset"
    t.string   "handle"
    t.boolean  "hide_email"
    t.string   "twitter_username"
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["handle"], name: "index_users_on_handle", using: :btree
  add_index "users", ["id", "confirmation_token"], name: "index_users_on_id_and_confirmation_token", using: :btree
  add_index "users", ["id", "token"], name: "index_users_on_id_and_token", using: :btree
  add_index "users", ["remember_token"], name: "index_users_on_remember_token", using: :btree
  add_index "users", ["token"], name: "index_users_on_token", using: :btree

  create_table "versions", force: :cascade do |t|
    t.text     "authors"
    t.text     "description"
    t.string   "number"
    t.integer  "rubygem_id"
    t.datetime "built_at"
    t.datetime "updated_at"
    t.text     "summary"
    t.string   "platform"
    t.datetime "created_at"
    t.boolean  "indexed",                   default: true
    t.boolean  "prerelease"
    t.integer  "position"
    t.boolean  "latest"
    t.string   "full_name"
    t.integer  "size"
    t.string   "licenses"
    t.text     "requirements"
    t.string   "required_ruby_version"
    t.string   "sha256"
    t.hstore   "metadata",                  default: {},   null: false
    t.datetime "yanked_at"
    t.string   "required_rubygems_version"
    t.string   "info_checksum"
    t.string   "yanked_info_checksum"
    t.string   "pushed_by"
  end

  add_index "versions", ["built_at"], name: "index_versions_on_built_at", using: :btree
  add_index "versions", ["created_at"], name: "index_versions_on_created_at", using: :btree
  add_index "versions", ["full_name"], name: "index_versions_on_full_name", using: :btree
  add_index "versions", ["indexed"], name: "index_versions_on_indexed", using: :btree
  add_index "versions", ["number"], name: "index_versions_on_number", using: :btree
  add_index "versions", ["position"], name: "index_versions_on_position", using: :btree
  add_index "versions", ["prerelease"], name: "index_versions_on_prerelease", using: :btree
  add_index "versions", ["rubygem_id", "number", "platform"], name: "index_versions_on_rubygem_id_and_number_and_platform", unique: true, using: :btree
  add_index "versions", ["rubygem_id"], name: "index_versions_on_rubygem_id", using: :btree

  create_table "web_hooks", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "url"
    t.integer  "failure_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rubygem_id"
  end

end
