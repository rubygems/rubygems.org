# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090825173917) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dependencies", :force => true do |t|
    t.string   "requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rubygem_id"
    t.integer  "version_id"
    t.string   "scope"
  end

  add_index "dependencies", ["rubygem_id"], :name => "index_dependencies_on_rubygem_id"

  create_table "linksets", :force => true do |t|
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

  add_index "linksets", ["rubygem_id"], :name => "index_linksets_on_rubygem_id"

  create_table "ownerships", :force => true do |t|
    t.integer  "rubygem_id"
    t.integer  "user_id"
    t.string   "token"
    t.boolean  "approved",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ownerships", ["rubygem_id"], :name => "index_ownerships_on_rubygem_id"
  add_index "ownerships", ["user_id"], :name => "index_ownerships_on_user_id"

  create_table "rubygems", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "downloads",      :default => 0
    t.string   "slug"
    t.integer  "versions_count", :default => 0
  end

  add_index "rubygems", ["name"], :name => "index_rubygems_on_name"

  create_table "subscriptions", :force => true do |t|
    t.integer  "rubygem_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password", :limit => 128
    t.string   "salt",               :limit => 128
    t.string   "token",              :limit => 128
    t.datetime "token_expires_at"
    t.boolean  "email_confirmed",                   :default => false, :null => false
    t.string   "api_key"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["id", "token"], :name => "index_users_on_id_and_token"
  add_index "users", ["token"], :name => "index_users_on_token"

  create_table "versions", :force => true do |t|
    t.string   "authors"
    t.text     "description"
    t.string   "number"
    t.integer  "rubygem_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "summary"
    t.string   "rubyforge_project"
  end

  add_index "versions", ["rubygem_id"], :name => "index_versions_on_rubygem_id"

end
