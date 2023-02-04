class CreateAudits < ActiveRecord::Migration[7.0]
  def change
    create_table :audits do |t|
      t.references :auditable, polymorphic: true, index: true
      t.belongs_to :admin_github_user
      t.text :audited_changes
      t.string :comment
      t.string :action
      t.timestamps
    end
  end
end
