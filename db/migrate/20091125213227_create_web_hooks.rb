class CreateWebHooks < ActiveRecord::Migration
  def self.up
    create_table      :web_hooks do |table|
      table.string    :gem_name
      table.integer   :user_id
      table.string    :url
      table.integer   :failure_count, default: 0
      table.timestamps
    end

  end

  def self.down
    drop_table :web_hooks
  end
end
