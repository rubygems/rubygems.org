class ValidateLinksetForeignKey < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key "linksets", "rubygems", name: "linksets_rubygem_id_fk"
  end
end
