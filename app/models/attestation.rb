class Attestation < ApplicationRecord
  belongs_to :version

  validates :body, :media_type, presence: true
  attribute :body, :jsonb

  def sigstore_bundle
    Sigstore::SBundle.new(
      Sigstore::Bundle::V1::Bundle.decode_json_hash(body, registry: Sigstore::REGISTRY)
    )
  end

  def display_data # rubocop:disable Metrics/MethodLength
    bundle = sigstore_bundle
    leaf_certificate = bundle.leaf_certificate

    issuer = leaf_certificate.extension(Sigstore::Internal::X509::Extension::FulcioIssuer).issuer
    log_index = bundle.verification_material.tlog_entries.first.log_index

    extensions = leaf_certificate.openssl.extensions.to_h do |ext|
      [ext.oid, if (ext.oid =~ /\A1\.3\.6\.1\.4\.1\.57264\.1\.(\d+)\z/) && ::Regexp.last_match(1).to_i >= 8
                  OpenSSL::ASN1.decode(ext.value_der).value
                else
                  ext.value
                end]
    end

    repo = extensions["1.3.6.1.4.1.57264.1.5"]
    commit = extensions["1.3.6.1.4.1.57264.1.3"]
    ref  =  extensions["1.3.6.1.4.1.57264.1.14"]
    san  =  extensions["subjectAltName"]
    build_file_url = extensions["1.3.6.1.4.1.57264.1.21"]

    case issuer
    when "https://token.actions.githubusercontent.com"
      san =~ %r{\AURI:https://github\.com/#{Regexp.escape(repo)}/(.+)@#{Regexp.escape(ref)}\z}
      build_file_string = ::Regexp.last_match(1)
      {
        ci_platform: "GitHub Actions",
        source_commit_string: "#{repo}@#{commit[0, 7]}",
        source_commit_url: "https://github.com/#{repo}/tree/#{commit}",
        build_file_string:, build_file_url:,
        build_summary_url: "https://github.com/#{repo}/actions/#{build_file_string.delete_prefix('.github/')}"
      }
    else
      raise "Unhandled issuer: #{issuer.inspect}"
    end.merge(
      log_index:
    )
  end
end
