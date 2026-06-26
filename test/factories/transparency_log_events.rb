# frozen_string_literal: true

FactoryBot.define do
  factory :transparency_log_event do
    event_uuid { SecureRandom.uuid }
    spec_version { "1.0" }
    event_type { "rubygem.owner.added" }
    resource_type { "rubygem" }
    sequence(:resource_name) { "rack-#{it}" }
    resource_id { nil }
    subject_type { "user" }
    sequence(:subject_id, &:to_s)
    sequence(:subject_name) { |n| "owner-#{n}" }
    subject_handle { subject_name }
    actor_type { "user" }
    sequence(:actor_id, &:to_s)
    actor_handle { "gem-author" }
    authentication_method { "api_key" }
    canonical_payload do
      {
        "specVersion" => spec_version,
        "kind" => event_type,
        "gem" => resource_name,
        "resource" => {
          "type" => resource_type,
          "name" => resource_name
        },
        "actor" => {
          "type" => actor_type,
          "id" => actor_id,
          "handle" => actor_handle
        },
        "subject" => {
          "type" => subject_type,
          "id" => subject_id,
          "handle" => subject_handle
        }
      }
    end
    canonicalization_algorithm { "json_c14n" }
    canonicalization_version { "1" }
    payload_digest_algorithm { "sha256" }
    payload_digest { Digest::SHA256.digest(canonical_payload.to_json) }
    signing_mode { "local" }
    signing_key_id { "rubygems-development-key" }
    signing_algorithm { "ecdsa-p256-sha256" }
    signature { "signature-bytes" }
    public_key_id { "rubygems-development-public-key" }
    public_key_der { "public-key-der" }
    rekor_request_body { { "hashedRekordRequestV002" => { "digest" => Base64.strict_encode64(payload_digest) } } }

    trait :submitted do
      status { "submitted" }
      rekor_response_body { { "uuid" => SecureRandom.uuid } }
      rekor_log_origin { "rekor.sigstore.dev" }
      rekor_entry_kind { "hashedrekord" }
      rekor_entry_version { "0.0.1" }
      sequence(:rekor_log_index)
      rekor_checkpoint { "rekor.sigstore.dev checkpoint" }
      rekor_inclusion_proof { { "treeSize" => 1, "hashes" => [] } }
      rekor_submitted_at { Time.current }
    end

    trait :failed do
      status { "failed" }
      attempt_count { 1 }
      last_error { "Rekor request failed" }
    end
  end
end
