FactoryBot.define do
  factory :x509_certificate, class: "OpenSSL::X509::Certificate" do
    subject { OpenSSL::X509::Name.parse("/DC=org/DC=example/CN=Test") }
    issuer { subject }
    version { 2 }
    serial { 1 }
    not_before { 1.day.ago }
    not_after { 1.year.from_now }
    public_key { OpenSSL::PKey::EC.generate("prime256v1") }
    transient do
      extension_factory { OpenSSL::X509::ExtensionFactory.new }
    end

    trait :key_usage do
      after(:build) do |cert, ctx|
        cert.add_extension(ctx.extension_factory.create_ext("keyUsage", "digitalSignature", true))
        cert.add_extension(ctx.extension_factory.create_ext("2.5.29.37", "critical,DER:30:0A:06:08:2B:06:01:05:05:07:03:03"))
      end
    end

    trait :github_actions_fulcio do
      after(:build) do |cert, ctx|
        {
          "1.3.6.1.4.1.57264.1.1" =>
                "https://token.actions.githubusercontent.com",
            "1.3.6.1.4.1.57264.1.2" =>
                "release",
            "1.3.6.1.4.1.57264.1.3" =>
                "f106999a2210a9a17b32b172f95518859a85ffed",
            "1.3.6.1.4.1.57264.1.4" =>
                "Release",
            "1.3.6.1.4.1.57264.1.5" =>
                "sigstore/sigstore-ruby",
            "1.3.6.1.4.1.57264.1.6" =>
                "refs/tags/v0.1.1",
            "1.3.6.1.4.1.57264.1.8" =>
                "https://token.actions.githubusercontent.com",
            "1.3.6.1.4.1.57264.1.9" =>
                ".Xhttps://github.com/sigstore/sigstore-ruby/.github/workflows/release.yml@refs/tags/v0.1.1",
            "1.3.6.1.4.1.57264.1.10" =>
                ".(f106999a2210a9a17b32b172f95518859a85ffed",
            "1.3.6.1.4.1.57264.1.11" =>
                ".githubHosted",
            "1.3.6.1.4.1.57264.1.12" =>
                ".)https://github.com/sigstore/sigstore-ruby",
            "1.3.6.1.4.1.57264.1.13" =>
                ".(f106999a2210a9a17b32b172f95518859a85ffed",
            "1.3.6.1.4.1.57264.1.14" =>
                "..refs/tags/v0.1.1",
            "1.3.6.1.4.1.57264.1.15" =>
                "..766398650",
            "1.3.6.1.4.1.57264.1.16" =>
                "..https://github.com/sigstore",
            "1.3.6.1.4.1.57264.1.17" =>
                "..71096353",
            "1.3.6.1.4.1.57264.1.18" =>
                ".Xhttps://github.com/sigstore/sigstore-ruby/.github/workflows/release.yml@refs/tags/v0.1.1",
            "1.3.6.1.4.1.57264.1.19" =>
                ".(f106999a2210a9a17b32b172f95518859a85ffed",
            "1.3.6.1.4.1.57264.1.20" =>
                "..release",
            "1.3.6.1.4.1.57264.1.21" =>
                ".Mhttps://github.com/sigstore/sigstore-ruby/actions/runs/11446323187/attempts/1",
            "1.3.6.1.4.1.57264.1.22" =>
                "..public"
        }.each do |oid, value|
          cert.add_extension(ctx.extension_factory.create_ext(oid, "ASN1:UTF8String:#{value}", false))
        end
      end
    end

    after(:build) do |cert, ctx|
      cert.sign(ctx.public_key, OpenSSL::Digest.new("SHA256"))
    end

    to_create { |instance| instance }
  end
end
