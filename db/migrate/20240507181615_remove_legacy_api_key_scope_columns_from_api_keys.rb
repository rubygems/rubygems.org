class RemoveLegacyApiKeyScopeColumnsFromApiKeys < ActiveRecord::Migration[7.1]
  def change
    # The columns are ignored
    safety_assured do
      remove_columns :api_keys,
                     *%i[show_dashboard index_rubygems push_rubygem yank_rubygem add_owner remove_owner access_webhooks],
                     type: :boolean,
                     null: false,
                     default: false
    end
  end
end
