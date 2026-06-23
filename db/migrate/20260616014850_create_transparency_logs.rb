# frozen_string_literal: true

class CreateTransparencyLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :transparency_log_events do |t|
      t.uuid :event_uuid, null: false
      t.string :event_type, null: false, limit: 100

      t.string :subject_type, null: false, limit: 50
      t.string :subject_name, null: false, limit: 255

      t.string :actor_type, null: false, limit: 50
      t.string :actor_id, null: false, limit: 128
      t.string :actor_handle, limit: 128

      t.string :authentication_method, null: false, limit: 100

      t.jsonb :canonical_payload, null: false, default: {}
      t.string :canonicalization_algorithm, null: false, limit: 64
      t.string :canonicalization_version, null: false, limit: 32

      t.string :payload_digest_algorithm, null: false, limit: 32
      t.binary :payload_digest, null: false

      t.string :signing_mode, null: false, limit: 50
      t.string :signing_key_id, null: false, limit: 128
      t.string :signing_algorithm, null: false, limit: 64
      t.binary :signature, null: false

      t.string :public_key_id, null: false, limit: 128
      t.binary :public_key_der, null: false

      t.jsonb :rekor_request_body, null: false, default: {}
      t.jsonb :rekor_response_body
      t.string :rekor_log_origin, limit: 255
      t.string :rekor_entry_kind, limit: 50
      t.string :rekor_entry_version, limit: 32
      t.bigint :rekor_log_index
      t.text :rekor_checkpoint
      t.jsonb :rekor_inclusion_proof
      t.datetime :rekor_submitted_at

      t.string :status, null: false, limit: 32, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.text :last_error

      t.timestamps

      t.index :event_uuid, unique: true
      t.index [:subject_type, :subject_name]
      t.index [:event_type, :created_at]
      t.index [:payload_digest_algorithm, :payload_digest],
        unique: true,
        name: "index_transparency_log_events_on_payload_digest"
      t.index :status
    end
  end
end
