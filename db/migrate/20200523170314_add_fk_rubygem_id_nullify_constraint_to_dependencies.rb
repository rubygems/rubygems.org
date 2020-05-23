class AddFkRubygemIdNullifyConstraintToDependencies < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :dependencies, :rubygems, on_delete: :nullify
  end
end
