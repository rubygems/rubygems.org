ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "called_before_save"
    t.boolean  "called_after_save"
    t.integer "id"
  end
end