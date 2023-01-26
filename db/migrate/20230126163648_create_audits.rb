class CreateAudits < ActiveRecord::Migration[7.0]
  def change
    create_table :audits do |t|
      t.references :auditable, polymorphic: true, index: true
      t.belongs_to :user
      t.text :audited_changes
      t.string :comment
      t.timestamps
    end
  end
end
