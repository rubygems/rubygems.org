class GemValidator::Package
  class PackageError < GemValidator::Error; end
  # Raised when we encounter an unexpected file
  class UnexpectedFileEntry < PackageError; end

  # Raised when there are multiple of the same file
  class MultipleFilesError < PackageError; end
  class MultipleChecksumFiles < MultipleFilesError; end
  class MultipleDataFiles < MultipleFilesError; end
  class MultipleMetadataFiles < MultipleFilesError; end
  class MultipleSignatureFiles < MultipleFilesError; end

  # Raised when a particular file is missing
  class MissingFileError < PackageError; end
  class MissingDataFile < MissingFileError; end
  class MissingMetadataFile < MissingFileError; end
  class MissingChecksumsFile < MissingFileError; end
  class MissingSignatureFile < MissingFileError; end

  # Raised when a file fails validation
  class FileFormatError < PackageError; end
  class InvalidGemspec < FileFormatError; end
  class InvalidChecksums < FileFormatError; end

  # Raised when a gz file is too large
  class OutOfBounds < PackageError; end
  class MetadataOutOfBounds < OutOfBounds; end
  class ChecksumOutOfBounds < OutOfBounds; end
  class SignatureOutOfBounds < OutOfBounds; end

  # Raised on Checksum related errors
  class ChecksumError < PackageError; end
  class WrongChecksum < ChecksumError; end
  class MissingChecksum < ChecksumError; end

  # Raised on security policy verification
  class SignatureVerificationError < PackageError; end

  # File name constants
  METADATA = "metadata".freeze
  METADATA_GZ = "metadata.gz".freeze
  DATA_TAR_GZ = "data.tar.gz".freeze
  CHECKSUMS_YAML_GZ = "checksums.yaml.gz".freeze
  SIGNATURE_SUFFIX = ".sig".freeze

  # Checksum algorithm
  SHA256_ALGORITHM = "SHA256".freeze

  # Size limits
  DEFAULT_MAX_SIZE = 10 * 1024 * 1024
  READ_CHUNK_SIZE = 1 << 14 # 16KB

  # Null Object pattern for security policy - no-op verification
  class NullSecurityPolicy
    def verify_signatures(_spec, _checksums, _signatures)
      # No-op: validation always passes with no policy
    end
  end

  NO_POLICY = NullSecurityPolicy.new.freeze

  # Value object for validation result
  ValidationResult = Data.define(:gemspec_ast, :files) do
    def spec
      gemspec_ast.to_ruby.tap do |s|
        s.reset_nil_attributes_to_default
        s.flatten_require_paths
      end
    end
  end

  class ChecksumIO
    attr_reader :checksum

    def initialize(io, checksum)
      @checksum = checksum
      @io = io
    end

    def readpartial(maxlen, buf = "".b)
      data = @io.readpartial(maxlen, buf)
      @checksum << data
      data
    end
  end

  def self.validate(io, security_policy = NO_POLICY,
    max_metadata_size: DEFAULT_MAX_SIZE, max_checksums_size: DEFAULT_MAX_SIZE, max_sig_size: DEFAULT_MAX_SIZE)
    new(io,
      security_policy: security_policy,
      max_metadata_size: max_metadata_size,
      max_checksums_size: max_checksums_size,
      max_sig_size: max_sig_size).validate
  end

  # Public class method for validating gemspec YAML (used by tests)
  def self.validate_gemspec_yaml(yaml)
    ast = Psych.parse(yaml)
    node = ast.children.first
    begin
      GemValidator.spec_validator.validate(GemValidator::Schema::SPECIFICATION, node, aliases: false)
    rescue YAMLSchema::Validator::Exception => e
      raise InvalidGemspec, "gemspec validation failed: #{e.message}"
    end
    ast
  rescue Psych::SyntaxError => e
    raise InvalidGemspec, "invalid YAML syntax at line #{e.line}: #{e.message}"
  end

  def initialize(io, security_policy: NO_POLICY,
    max_metadata_size: DEFAULT_MAX_SIZE, max_checksums_size: DEFAULT_MAX_SIZE, max_sig_size: DEFAULT_MAX_SIZE)
    @io = io
    @security_policy = security_policy
    @max_metadata_size = max_metadata_size
    @max_checksums_size = max_checksums_size
    @max_sig_size = max_sig_size

    @gemspec_ast = nil
    @reported_checksums = nil
    @calculated_checksums = {}
    @signatures = {}
    @files = []
  end

  def validate
    process_tar_entries
    validate_required_files!
    verify_checksums!
    verify_signatures!

    ValidationResult.new(@gemspec_ast, @files)
  end

  private

  def process_tar_entries
    gem_tar = Gem::Package::TarReader.new(@io)
    entry_count = 0

    gem_tar.each do |entry|
      entry_count += 1
      process_entry(entry)
    end

    raise PackageError, "gem package contains no entries" if entry_count.zero?
  end

  def process_entry(entry)
    filename = entry.header.name
    @files << filename

    case filename
    when METADATA, METADATA_GZ
      process_metadata_entry(entry)
    when DATA_TAR_GZ
      process_data_entry(entry)
    when CHECKSUMS_YAML_GZ
      process_checksums_entry(entry)
    else
      process_signature_or_unexpected(entry, filename)
    end
  end

  def process_metadata_entry(entry)
    raise MultipleMetadataFiles, "duplicate metadata file: already processed metadata, found #{entry.header.name}" if @gemspec_ast

    @gemspec_ast, checksum = validate_metadata_entry(entry)
    @calculated_checksums[entry.header.name] = checksum
  end

  def process_data_entry(entry)
    raise MultipleDataFiles, "duplicate data.tar.gz file found" if @calculated_checksums.key?(DATA_TAR_GZ)

    @calculated_checksums[DATA_TAR_GZ] = validate_data_entry(entry)
  end

  def process_checksums_entry(entry)
    raise MultipleChecksumFiles, "duplicate checksums.yaml.gz file found" if @reported_checksums

    @reported_checksums, checksums_checksum = validate_checksums_entry(entry)

    # A quirk of RubyGems is that the Gem file contains a yaml file
    # that contains checksums of the other two files. Of course, it can't
    # contain a checksum of itself.
    #
    # When gems are signed, it creates a signature of the checksum of
    # each file, including checksums.yaml.gz.  During packaging, we
    # calculate a checksum of checksums.yaml.gz, but it is ephemeral and
    # only used to generate `checksums.yaml.gz.sig`.
    #
    # To verify the signatures, we just recalculate the checksum of this
    # particular file and use it to verify the signature.  That's why
    # we're sticking this checksum in the "reported" checksums as well
    # as the calculated checksums.
    @calculated_checksums[CHECKSUMS_YAML_GZ] = checksums_checksum
    @reported_checksums[SHA256_ALGORITHM][CHECKSUMS_YAML_GZ] = checksums_checksum.hexdigest
  end

  def process_signature_or_unexpected(entry, filename)
    raise UnexpectedFileEntry, "unexpected gem file entry: #{filename.dump}" unless filename.end_with?(SIGNATURE_SUFFIX)

    process_signature_entry(entry, filename)
  end

  def process_signature_entry(entry, filename)
    raise SignatureOutOfBounds, "signature is too large" if entry.size > @max_sig_size

    base_filename = filename.delete_suffix(SIGNATURE_SUFFIX)
    raise MultipleSignatureFiles, "duplicate signatures files found" if @signatures.key?(base_filename)

    @signatures[base_filename] = entry.read
  end

  def validate_required_files!
    raise MissingMetadataFile, "missing metadata.gz file" unless @gemspec_ast
    raise MissingDataFile, "missing data.tar.gz file" unless @calculated_checksums.key?(DATA_TAR_GZ)

    # If the package has a signature for checksums.yaml.gz, but it
    # doesn't have the actual file, report an error
    raise MissingChecksumsFile, "missing checksums.yaml.gz file" if @signatures.key?(CHECKSUMS_YAML_GZ) && !@reported_checksums
  end

  def verify_checksums!
    return unless @reported_checksums&.key?(SHA256_ALGORITHM)

    # RubyGems' signature verification only cares about SHA256, so we'll
    # only validate it here (if it's available)
    #
    # https://github.com/ruby/rubygems/blob/f778bf7baf70b2b9c140d1d6adbc0c0bef313eb7/lib/rubygems/security/policy.rb#L225-L227
    # https://github.com/ruby/rubygems/blob/f778bf7baf70b2b9c140d1d6adbc0c0bef313eb7/lib/rubygems/security.rb#L337
    calculated_hex = @calculated_checksums.transform_values(&:hexdigest)
    reported_sha256 = @reported_checksums[SHA256_ALGORITHM]

    missing = calculated_hex.keys - reported_sha256.keys
    raise MissingChecksum, "expected checksum for #{missing.first.dump} but found none" if missing.any?

    calculated_hex.each do |filename, calculated_sha|
      reported_sha = reported_sha256[filename]
      raise WrongChecksum, "expected #{filename.dump} to have #{calculated_sha} but was #{reported_sha}" if calculated_sha != reported_sha
    end
  end

  def verify_signatures!
    spec = GemValidator::YAMLGemspec.new(@gemspec_ast)

    if @signatures.empty?
      raise MissingSignatureFile, "Cert chain provided, but no signatures found" unless spec.cert_chain.empty?
      return
    end

    missing_sig = (@calculated_checksums.keys - @signatures.keys).first
    raise MissingSignatureFile, "missing signature for #{missing_sig}" if missing_sig

    raise InvalidGemspec, "missing signing certificate" if spec.cert_chain.empty?

    verify_with_security_policy!(spec)
  end

  def verify_with_security_policy!(spec)
    verification_checksums = { SHA256_ALGORITHM => @calculated_checksums }
    @security_policy.verify_signatures(spec, verification_checksums, @signatures)
  rescue OpenSSL::PKey::PKeyError, Gem::Security::Exception
    raise SignatureVerificationError, "couldn't verify gem signature"
  end

  def validate_data_entry(entry)
    checksum = OpenSSL::Digest.new(SHA256_ALGORITHM)
    size = entry.header.size
    while size.positive?
      rd = [size, READ_CHUNK_SIZE].min
      checksum << entry.read(rd)
      size -= rd
    end
    checksum
  end

  def validate_metadata_entry(entry)
    checksum = OpenSSL::Digest.new(SHA256_ALGORITHM)

    yaml = if entry.header.name == METADATA_GZ
             checksum_io = ChecksumIO.new(entry, checksum)
             Zlib::GzipReader.wrap(checksum_io, external_encoding: Encoding::UTF_8) do |gzio|
               self.class.limit_read(gzio, METADATA_GZ, @max_metadata_size, exception: MetadataOutOfBounds)
             end
           else
             data = entry.read(entry.header.size)
             checksum << data
             data
           end

    [self.class.validate_gemspec_yaml(yaml), checksum]
  end

  def validate_checksums_entry(entry)
    checksum_io = ChecksumIO.new(entry, OpenSSL::Digest.new(SHA256_ALGORITHM))

    yaml = Zlib::GzipReader.wrap(checksum_io, external_encoding: Encoding::UTF_8) do |gzio|
      self.class.limit_read(gzio, CHECKSUMS_YAML_GZ, @max_checksums_size, exception: ChecksumOutOfBounds)
    end

    ast = Psych.parse(yaml)
    node = ast.children.first

    begin
      YAMLSchema::Validator.validate(GemValidator::Schema::CHECKSUMS, node)
      [ast.to_ruby, checksum_io.checksum]
    rescue YAMLSchema::Validator::Exception => e
      raise InvalidChecksums, "checksums validation failed: #{e.message}"
    end
  rescue Psych::SyntaxError => e
    raise InvalidChecksums, "invalid YAML syntax in checksums at line #{e.line}: #{e.message}"
  end

  class << self
    def limit_read(io, name, limit, exception:)
      bytes = io.read(limit + 1) || "".b
      raise exception, "#{name} is too big (over #{limit} bytes)" if bytes.bytesize > limit
      bytes
    end
  end
end
