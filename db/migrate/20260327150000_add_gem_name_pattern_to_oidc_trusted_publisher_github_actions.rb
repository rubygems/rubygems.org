# frozen_string_literal: true

class AddGemNamePatternToOIDCTrustedPublisherGitHubActions < ActiveRecord::Migration[7.2]
  def change
    add_column :oidc_trusted_publisher_github_actions, :gem_name_pattern, :string, null: true
  end
end
