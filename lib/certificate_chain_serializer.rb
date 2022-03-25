class CertificateChainSerializer
  PATTERN = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/

  def self.load(chain)
    return [] unless chain
    chain.scan(PATTERN).map do |cert|
      OpenSSL::X509::Certificate.new(cert)
    end
  end

  def self.dump(chain)
    return if chain.blank?
    normalised = chain.map do |cert|
      cert.respond_to?(:to_pem) ? cert : OpenSSL::X509::Certificate.new(cert)
    end
    normalised.map(&:to_pem).join
  end
end
