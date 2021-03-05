class CreateApiKeys < ActiveRecord::Migration[5.2]
  def change
    create_table :api_keys do |t|
      t.references :user, foreign_key: true, index: true, null: false
      t.string     :name, null: false
      t.string     :hashed_key, null: false, index: { unique: true }
      t.boolean    :index_rubygems, null: false, default: false
      t.boolean    :push_rubygem, null: false, default: false
      t.boolean    :yank_rubygem, null: false, default: false
      t.boolean    :add_owner, null: false, default: false
      t.boolean    :remove_owner, null: false, default: false
      t.boolean    :access_webhooks, null: false, default: false
      t.boolean    :show_dashboard, null: false, default: false
      t.datetime   :last_accessed_at, default: nil
      t.timestamps
    end
  end
end
