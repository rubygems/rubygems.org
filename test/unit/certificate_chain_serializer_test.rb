require "test_helper"

class CertificateChainSerializerTest < ActiveSupport::TestCase
  context ".load" do
    setup do
      @cert_chain = File.read(File.expand_path("../certs/chain.pem", __dir__))
    end

    should "return an empty array when no certificates are present" do
      assert_empty CertificateChainSerializer.load("")
      assert_empty CertificateChainSerializer.load(nil)
    end

    should "return an array of certificates when certificates are present" do
      certs = CertificateChainSerializer.load(@cert_chain)
      assert_equal 2, certs.size
      assert_equal "379469669351564281569116418161349711273802", certs[0].serial.to_s
      assert_equal "85078157426496920958827089468591623647", certs[1].serial.to_s
    end
  end

  context ".dump" do
    setup do
      @certs = Array.new(2) do
        key = OpenSSL::PKey::RSA.new(1024)
        public_key = key.public_key

        subject = "/C=FI/O=Test/OU=Test/CN=Test"

        cert = OpenSSL::X509::Certificate.new
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
        cert.not_before = Time.current
        cert.not_after = 1.year.from_now
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2
        cert.sign(key, OpenSSL::Digest.new("SHA256"))
        cert
      end
    end

    should "return an nil when no certificates are present" do
      assert_nil CertificateChainSerializer.dump([])
      assert_nil CertificateChainSerializer.dump(nil)
    end

    should "return a certificate chain string when certificates are present" do
      assert_equal @certs.map(&:to_pem).join, CertificateChainSerializer.dump(@certs)
    end

    should "return a certificate chain when the chain certificates are in PEMs" do
      pems = @certs.map(&:to_pem)
      assert_equal pems.join, CertificateChainSerializer.dump(pems)
    end

    should "strip out excessive newlines from the certificate PEMs" do
      pems = @certs.map { |cert| "#{cert.to_pem}\n\n\n" }
      assert_equal @certs.map(&:to_pem).join, CertificateChainSerializer.dump(pems)
    end
  end
end
