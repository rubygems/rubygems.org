require "test_helper"

class GemValidator::RubygemValidatorTest < Minitest::Test
  include GemHelpers

  def setup
    @key = Gem::Security.create_key "ec"
    @pub_key = @key.to_pem
    @spec = new_gemspec("test-signed", "1.0.0", "W signed gem", "ruby")
  end

  # Valid rubygem tests

  def test_valid_gem_dev_deps
    @spec.add_runtime_dependency "racc", "~> 1.6"
    @spec.add_development_dependency "hatstone", "~> 1.0.0"
    gem_io = build_gem @spec

    assert GemValidator::Package.validate gem_io
  end

  def test_valid_no_date
    @spec.date = nil
    gem_io = build_gem @spec

    assert GemValidator::Package.validate gem_io
  end

  def test_valid_gem_is_great
    gem_io = build_gem @spec

    assert_match(/date:/, @spec.to_yaml)
    assert GemValidator::Package.validate gem_io
  end

  def test_valid_gem_non_gz_metadata
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      file "metadata", spec_yaml
      data
      checksums(:auto)
    end

    assert GemValidator::Package.validate tar
  end

  def test_checksums_are_hash_of_hashes
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums(:auto) do
        sha1   "metadata.gz" => "abc123", "data.tar.gz" => "abc123"
        shaabc "metadata.gz" => "abc123", "data.tar.gz" => "abc123"
      end
    end

    assert GemValidator::Package.validate tar
  end

  # Invalid Rubygem tests

  def test_reject_multiple_signatures_with_same_name
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums(:auto)
      file "test.sig", "Hello World!"
      file "test.sig", "Hello World!"
    end

    assert_raises GemValidator::Package::MultipleSignatureFiles do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_signature_too_large
    signed_gemspec = new_gemspec("test-signed", "1.0.0", "a signed gem", "ruby") do |s|
      s.cert_chain = [@pub_key]
    end

    gem_tar = build_gem(signed_gemspec, key: @key)

    # Get actual signature size from the built gem
    gem_tar.rewind
    sig_size = nil
    Gem::Package::TarReader.new(gem_tar).each do |entry|
      if entry.header.name.end_with?(".sig")
        sig_size = entry.header.size
        break
      end
    end

    gem_tar.rewind
    assert_raises GemValidator::Package::SignatureOutOfBounds do
      GemValidator::Package.validate(gem_tar, max_sig_size: sig_size - 1)
    end
  end

  def test_reject_checksum_too_large
    gem_tar = build_gem(@spec)

    assert_raises GemValidator::Package::ChecksumOutOfBounds do
      GemValidator::Package.validate gem_tar, max_checksums_size: 2
    end
  end

  def test_reject_metadata_too_large
    gem_tar = build_gem(@spec)

    assert_raises GemValidator::Package::MetadataOutOfBounds do
      GemValidator::Package.validate gem_tar, max_metadata_size: 2
    end
  end

  def test_reject_invalid_gemspec
    tar = gem_tar_builder do
      metadata "hello"
    end

    e = assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate tar
    end
    assert_kind_of YAMLSchema::Validator::Exception, e.cause
  end

  def test_reject_non_gz_metadata_supported
    tar = gem_tar_builder do
      file "metadata", "hello"
    end

    e = assert_raises GemValidator::Package::InvalidGemspec do
      GemValidator::Package.validate tar
    end
    assert_kind_of YAMLSchema::Validator::Exception, e.cause
  end

  def test_reject_invalid_checksums
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums raw: Psych.dump("foo")
    end

    e = assert_raises GemValidator::Package::InvalidChecksums do
      GemValidator::Package.validate tar
    end
    assert_kind_of YAMLSchema::Validator::Exception, e.cause
  end

  def test_reject_checksums_with_invalid_yaml_syntax
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums raw: "key: value\n  bad_indent: broken\nanother: value"
    end

    e = assert_raises GemValidator::Package::InvalidChecksums do
      GemValidator::Package.validate tar
    end
    assert_kind_of Psych::SyntaxError, e.cause
  end

  def test_reject_extra_checksum
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums { sha256 "not-a-file.txt" => "abc123" }
    end

    assert_raises GemValidator::Package::InvalidChecksums do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_missing_checksum
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums { sha256 "metadata.gz" => "abc123" }
    end

    assert_raises GemValidator::Package::MissingChecksum do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_broken_checksums
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      data
      checksums do
        sha256 "metadata.gz" => "abc123", "data.tar.gz" => "abc123"
        sha512 "metadata.gz" => "abc123", "data.tar.gz" => "abc123"
      end
    end

    assert_raises GemValidator::Package::WrongChecksum do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_unexpected_files
    tar = gem_tar_builder do
      file "hello!", "wow"
    end

    assert_raises GemValidator::Package::UnexpectedFileEntry do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_multiple_metadata_files
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      metadata spec_yaml
    end

    assert_raises GemValidator::Package::MultipleMetadataFiles do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_missing_metadata
    tar = gem_tar_builder do
      data
      checksums { sha256({}) }
    end

    assert_raises GemValidator::Package::MissingMetadataFile do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_multiple_checksums
    tar = gem_tar_builder do
      checksums { sha256({}) }
      checksums { sha256({}) }
    end

    assert_raises GemValidator::Package::MultipleChecksumFiles do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_missing_data
    spec_yaml = @spec.to_yaml
    tar = gem_tar_builder do
      metadata spec_yaml
      checksums { sha256({}) }
    end

    assert_raises GemValidator::Package::MissingDataFile do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_empty_tar_archive
    tar = StringIO.new
    Gem::Package::TarWriter.new(tar) { |_| } # empty tar

    tar.rewind

    assert_raises GemValidator::Package::PackageError do
      GemValidator::Package.validate tar
    end
  end

  def test_reject_multiple_data_files
    tar = gem_tar_builder do
      data
      data
    end

    assert_raises GemValidator::Package::MultipleDataFiles do
      GemValidator::Package.validate tar
    end
  end
end
