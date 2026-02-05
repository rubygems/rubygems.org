require "test_helper"

class GemValidator::SignedGemTest < Minitest::Test
  include GemHelpers

  class QuietPolicy < Gem::Security::Policy
    def alert_warning(message)
    end
  end

  KEY = Gem::Security.create_key "ec"
  PRIVATE_KEY = KEY.to_pem Gem::Security::KEY_CIPHER, "password"
  expiration_length_days = Gem.configuration.cert_expiration_length_days
  CERT = Gem::Security.create_cert_email("foo@example.com", KEY,
    Gem::Security::ONE_DAY * expiration_length_days)
  PUB_KEY = CERT.to_pem

  def setup
    @spec = new_gemspec("test-signed", "1.0.0", "a signed gem", "ruby") do |s|
      s.cert_chain = [PUB_KEY]
    end

    @push_policy = QuietPolicy.new(
      "Push Policy",
      verify_data:   true,
      verify_signer: true,
      verify_chain:  true,
      verify_root:   true,
      only_trusted:  false,
      only_signed:   false
    )
  end

  def test_always_reject_signing_key
    @spec.signing_key = "secret signing key"

    # I think `to_yaml` should always omit this, but we'll keep
    # the assert_match until we can fix upstream
    yaml = @spec.to_yaml

    assert_match(/secret signing key/, yaml)
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate_gemspec_yaml yaml
    end
  end

  def test_valid
    in_memory_gem = build_gem(@spec, key: KEY)

    package = Gem::Package.new in_memory_gem

    assert package.verify

    package = Gem::Package.new in_memory_gem, @push_policy

    assert package.verify
  end

  def test_has_cert_missing_all_sigs
    gem_io = build_gem(@spec, key: KEY)

    newgemio = StringIO.new("".b)
    Gem::Package::TarWriter.new(newgemio) do |newgem|
      read = Gem::Package::TarReader.new(gem_io)
      read.each do |entry|
        next if /sig$/.match?(entry.header.name)

        newgem.add_file_simple(entry.header.name, 0o444, entry.header.size) do |o|
          o.write entry.read(entry.header.size)
        end
      end
    end

    # RubyGems doesn't consider Spec + cert, _without_ sigs invalid,
    # but I think we should consider it invalid
    newgemio.rewind
    package = Gem::Package.new newgemio, @push_policy

    assert package.verify

    newgemio.rewind
    assert_raises GemValidator::Package::MissingSignatureFile do
      GemValidator::Package.validate newgemio
    end
  end

  def test_has_sigs_but_missing_cert
    @spec.cert_chain = []
    in_memory_gem = build_gem(@spec, key: KEY)

    package = Gem::Package.new in_memory_gem

    assert package.verify

    package = Gem::Package.new in_memory_gem, @push_policy
    assert_raises Gem::Security::Exception do
      assert package.verify
    end

    # If the gem file has signature files, but it's missing a cert_chain
    # then it's an invalid gemspec
    in_memory_gem.rewind
    assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate in_memory_gem
    end
  end

  def test_wrong_pub_key
    key = Gem::Security.create_key "ec"
    expiration_length_days = Gem.configuration.cert_expiration_length_days
    cert = Gem::Security.create_cert_email("foo@example.com", key,
      Gem::Security::ONE_DAY * expiration_length_days)
    pub_key = cert.to_pem

    spec = new_gemspec("test-signed", "1.0.0", "a signed gem", "ruby") do |s|
      s.cert_chain = [pub_key]
    end
    in_memory_gem = build_gem(spec, key: KEY)

    package = Gem::Package.new in_memory_gem, @push_policy
    assert_raises Gem::Security::Exception do
      assert package.verify
    end

    in_memory_gem.rewind
    assert_raises GemValidator::Package::SignatureVerificationError do
      GemValidator::Package.validate in_memory_gem, @push_policy
    end

    in_memory_gem.rewind

    assert GemValidator::Package.validate in_memory_gem
  end

  def test_wrong_private_key
    key = Gem::Security.create_key "ec"

    in_memory_gem = build_gem(@spec, key: key)

    package = Gem::Package.new in_memory_gem, @push_policy
    assert_raises Gem::Security::Exception do
      assert package.verify
    end

    in_memory_gem.rewind
    assert_raises GemValidator::Package::SignatureVerificationError do
      GemValidator::Package.validate in_memory_gem, @push_policy
    end

    in_memory_gem.rewind

    assert GemValidator::Package.validate in_memory_gem
  end

  def test_invalid_signatures # rubocop:disable Metrics/MethodLength
    gem_io = build_gem(@spec, key: KEY)

    ["metadata.gz.sig", "data.tar.gz.sig", "checksums.yaml.gz.sig"].each do |fname|
      gem_io.rewind
      newgemio = StringIO.new("".b)
      saw_signature = false
      bogus = "bogus signature"

      Gem::Package::TarWriter.new(newgemio) do |newgem|
        read = Gem::Package::TarReader.new(gem_io)
        read.each do |entry|
          if fname == entry.header.name
            saw_signature = true
            newgem.add_file_simple(entry.header.name, 0o444, bogus.bytesize) do |o|
              o.write bogus
            end
          else
            newgem.add_file_simple(entry.header.name, 0o444, entry.header.size) do |o|
              o.write entry.read(entry.header.size)
            end
          end
        end
      end

      assert saw_signature, "expected to see signature #{fname}"

      newgemio.rewind
      package = Gem::Package.new newgemio, @push_policy
      assert_raises OpenSSL::PKey::PKeyError do
        assert package.verify
      end

      newgemio.rewind
      # Detect missing signatures without a security policy
      assert_raises GemValidator::Package::SignatureVerificationError do
        GemValidator::Package.validate newgemio, @push_policy
      end
    end
  end

  def test_has_sig_but_missing_file # rubocop:disable Metrics/MethodLength
    gem_io = build_gem(@spec, key: KEY)

    ["metadata.gz", "data.tar.gz", "checksums.yaml.gz"].each do |fname|
      gem_io.rewind
      newgemio = StringIO.new("".b)
      saw_signature = false
      Gem::Package::TarWriter.new(newgemio) do |newgem|
        read = Gem::Package::TarReader.new(gem_io)
        read.each do |entry|
          if fname == entry.header.name
            saw_signature = true
            next
          end
          newgem.add_file_simple(entry.header.name, 0o444, entry.header.size) do |o|
            o.write entry.read(entry.header.size)
          end
        end
      end

      assert saw_signature, "expected to see file #{fname}"

      newgemio.rewind
      package = Gem::Package.new newgemio, @push_policy

      ex = {
        "metadata.gz" => Gem::Package::FormatError,
        "data.tar.gz" => Gem::Package::FormatError,
        "checksums.yaml.gz" => Gem::Security::Exception
      }[fname]

      assert_raises ex do
        assert package.verify
      end

      # Detect missing signatures without a security policy
      ex = {
        "metadata.gz" => GemValidator::Package::MissingMetadataFile,
        "data.tar.gz" => GemValidator::Package::MissingDataFile,
        "checksums.yaml.gz" => GemValidator::Package::MissingChecksumsFile
      }[fname]

      newgemio.rewind
      assert_raises ex do
        GemValidator::Package.validate newgemio, @push_policy
      end

      newgemio.rewind
      assert_raises ex do
        GemValidator::Package.validate newgemio
      end
    end
  end

  def test_missing_signatures
    gem_io = build_gem(@spec, key: KEY)

    ["metadata.gz.sig", "data.tar.gz.sig", "checksums.yaml.gz.sig"].each do |fname|
      gem_io.rewind
      newgemio = StringIO.new("".b)
      saw_signature = false
      Gem::Package::TarWriter.new(newgemio) do |newgem|
        read = Gem::Package::TarReader.new(gem_io)
        read.each do |entry|
          if fname == entry.header.name
            saw_signature = true
            next
          end
          newgem.add_file_simple(entry.header.name, 0o444, entry.header.size) do |o|
            o.write entry.read(entry.header.size)
          end
        end
      end

      assert saw_signature, "expected to see signature #{fname}"

      newgemio.rewind
      package = Gem::Package.new newgemio, @push_policy
      assert_raises Gem::Security::Exception do
        assert package.verify
      end

      newgemio.rewind
      # Detect missing signatures without a security policy
      assert_raises GemValidator::Package::MissingSignatureFile do
        GemValidator::Package.validate newgemio
      end
    end
  end
end
