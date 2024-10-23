class ValidateAddOrganizationForeignKeytoRubyGems < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :rubygems, :organizations
  end
end
