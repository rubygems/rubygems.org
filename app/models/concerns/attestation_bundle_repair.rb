module AttestationBundleRepair
  extend ActiveSupport::Concern

  def repairable?
    verification = body["verificationMaterial"]
    return false if verification.blank?

    missing_kind_version?(verification) || double_encoded_certificate?(verification)
  end

  def repair!
    verification = body["verificationMaterial"]
    return false if verification.blank?

    new_body = body.deep_dup
    new_verification = new_body["verificationMaterial"]
    changes = []

    repair_kind_version!(new_verification, changes) if missing_kind_version?(verification)
    repair_certificate!(new_verification, changes) if double_encoded_certificate?(verification)

    return false if changes.empty?

    update!(body: new_body)
    changes
  end

  private

  def missing_kind_version?(verification)
    verification["tlogEntries"]&.any? { |entry| !entry.key?("kindVersion") }
  end

  def double_encoded_certificate?(verification)
    return false unless (raw_bytes = verification.dig("certificate", "rawBytes"))

    decoded = Base64.strict_decode64(raw_bytes)
    decoded.start_with?("-----BEGIN CERTIFICATE-----")
  rescue ArgumentError
    false
  end

  def repair_kind_version!(verification, changes)
    verification["tlogEntries"]&.each_with_index do |entry, idx|
      next if entry.key?("kindVersion")
      entry["kindVersion"] = { "kind" => "dsse", "version" => "0.0.1" }
      changes << "Added missing kindVersion to tlogEntry #{idx}"
    end
  end

  def repair_certificate!(verification, changes)
    raw_bytes = verification.dig("certificate", "rawBytes")
    return unless raw_bytes

    decoded = Base64.strict_decode64(raw_bytes)
    return unless decoded.start_with?("-----BEGIN CERTIFICATE-----")

    cert = OpenSSL::X509::Certificate.new(decoded)
    verification["certificate"]["rawBytes"] = Base64.strict_encode64(cert.to_der)
    changes << "Converted double-encoded PEM certificate to DER"
  rescue ArgumentError, OpenSSL::X509::CertificateError => e
    Rails.logger.warn("Failed to repair certificate: #{e.message}")
  end
end
