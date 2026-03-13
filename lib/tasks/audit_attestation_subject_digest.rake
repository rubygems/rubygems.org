# frozen_string_literal: true

AuditResult = Data.define(:status, :detail) unless defined?(AuditResult)

desc "Audit attestation subject digests against version SHA256 hashes"
task audit_attestation_subject_digest: :environment do
  results = { match: 0, mismatch: 0, skipped: 0, error: 0 }
  mismatches = []

  scope = Attestation.includes(:version)
  if ENV["MAX_ATTESTATION_ID"].present?
    max_attestation_id = Integer(ENV["MAX_ATTESTATION_ID"])
    scope = scope.where(id: ..max_attestation_id)
  end
  total = scope.count

  puts "Auditing #{total} attestations..."

  scope.find_each do |attestation|
    result = audit_attestation(attestation)
    results[result.status] += 1

    case result.status
    when :mismatch
      mismatches << result.detail
    when :error
      warn result.detail
    when :skipped
      warn result.detail if result.detail
    end
  end

  puts
  puts "=== Audit Summary ==="
  puts "Total:    #{total}"
  puts "Match:    #{results[:match]}"
  puts "Mismatch: #{results[:mismatch]}"
  puts "Skipped:  #{results[:skipped]}"
  puts "Error:    #{results[:error]}"

  if mismatches.any?
    puts
    puts "=== Mismatched Attestations ==="
    mismatches.each { |m| puts m }
  end
end

def audit_attestation(attestation)
  bundle = attestation.sigstore_bundle

  return AuditResult.new(status: :skipped, detail: nil) unless bundle.dsse_envelope?

  envelope = bundle.dsse_envelope

  unless envelope.payloadType == "application/vnd.in-toto+json"
    return AuditResult.new(status: :skipped,
                           detail: "Attestation #{attestation.id}: unexpected payload type #{envelope.payloadType}")
  end

  in_toto = JSON.parse(envelope.payload)
  subject_digest = in_toto.dig("subject", 0, "digest", "sha256")

  unless subject_digest # rubocop:disable Style/IfUnlessModifier
    return AuditResult.new(status: :skipped, detail: "Attestation #{attestation.id}: missing subject SHA256 digest")
  end

  version_hex = attestation.version.sha256_hex

  unless version_hex
    return AuditResult.new(status: :skipped,
                           detail: "Attestation #{attestation.id}: version #{attestation.version_id} missing sha256")
  end

  if subject_digest == version_hex
    AuditResult.new(status: :match, detail: nil)
  else
    AuditResult.new(status: :mismatch,
                    detail: "Attestation #{attestation.id} (version #{attestation.version_id}): " \
                            "subject=#{subject_digest} version=#{version_hex}")
  end
rescue StandardError => e
  AuditResult.new(status: :error, detail: "Attestation #{attestation.id}: #{e.class}: #{e.message}")
end
