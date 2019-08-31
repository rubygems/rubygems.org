class CreateGemTypoExceptions < ActiveRecord::Migration[5.2]
  def change
    create_table :gem_typo_exceptions do |t|
      t.string :name
      t.text :info

      t.timestamps
    end
  end
end
