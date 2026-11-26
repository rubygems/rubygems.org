# frozen_string_literal: true

class CreateTemporaryPushGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :temporary_push_grants do |t|
      t.references :rubygem, type: :integer, null: false, foreign_key: true
      t.references :grantee, type: :integer, null: false, foreign_key: { to_table: :users }
      t.references :original_grant, foreign_key: { to_table: :temporary_push_grants }, index: { unique: true }
      t.references :api_key, foreign_key: true, index: { unique: true }

      t.string :version, null: false
      t.string :source_commit, null: false
      t.string :request_url, null: false
      t.text :justification, null: false
      t.text :correction_reason
      t.string :requester_github_login, null: false
      t.string :grantee_github_login, null: false

      t.datetime :outreach_sent_at, null: false
      t.datetime :response_deadline_at, null: false
      t.text :shortened_response_reason

      t.string :technical_reviewer
      t.text :technical_review_notes
      t.datetime :technical_reviewed_at
      t.string :technical_review_digest

      t.datetime :activated_at
      t.datetime :expires_at
      t.datetime :suspended_at
      t.text :suspension_reason
      t.datetime :revoked_at
      t.text :revocation_reason

      t.timestamps
    end

    create_table :temporary_push_grant_artifacts do |t|
      t.references :temporary_push_grant, null: false, foreign_key: true, index: false
      t.string :platform, null: false
      t.string :sha256, null: false
      t.references :version, type: :integer, foreign_key: true, index: { unique: true }

      t.timestamps
    end
    add_index :temporary_push_grant_artifacts, %i[temporary_push_grant_id platform], unique: true

    create_table :temporary_push_grant_approvals do |t|
      t.references :temporary_push_grant, null: false, foreign_key: true, index: false
      t.references :admin_github_user, null: false, foreign_key: true
      t.text :conflict_disclosure, null: false
      t.string :scope_digest, null: false

      t.timestamps
    end
    add_index :temporary_push_grant_approvals, %i[temporary_push_grant_id admin_github_user_id], unique: true
  end
end
