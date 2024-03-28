class AddLinksetForeignKey < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key "linksets", "rubygems", name: "linksets_rubygem_id_fk", validate: false
  end
end
