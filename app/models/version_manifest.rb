# frozen_string_literal: true

class VersionManifest
  attr_reader :version, :contents

  delegate :gem, :fs, to: :contents

  def initialize(gem:, number:, platform: nil)
    platform = nil if platform == "ruby"
    @version = [number, platform.presence].compact.join("-")
    raise ArgumentError, "version number-platform must be valid: #{@version.inspect}" unless @version.match?(Rubygem::NAME_PATTERN)
    @contents = RubygemContents.new(gem: gem)
  end

  ##
  # Access stored content

  def paths
    fs.each_key(prefix: path_root).map { |key| key.delete_prefix path_root }
  end

  # @return [RubygemContents::Entry]
  def entry(path)
    path = path.to_s
    return if path.blank?
    response = fs.head path_key(path)
    return if response.blank? || response[:metadata].blank?
    RubygemContents::Entry.from_metadata(response[:metadata]) { |entry| content(entry.fingerprint) }
  end

  def checksums_file
    fs.get(checksums_key)
  end

  def checksums
    ShasumFormat.parse checksums_file
  end

  def content(fingerprint)
    contents.get fingerprint
  end

  def spec
    fs.get spec_key
  end

  ##
  # Store version content

  # @param [Gem::Package] package
  def store_package(package)
    entries = GemPackageEnumerator.new(package).filter_map do |tar_entry|
      Rails.error.handle(context: { gem: package.spec.full_name, entry: tar_entry.full_name }) do
        RubygemContents::Entry.from_tar_entry(tar_entry)
      end
    end
    store_entries entries
    store_spec package.spec
  end

  # Writing version contents is done in one pass, collecting all the checksums
  # and paths and writing them to the .sha256 checksums file at the end.
  # All files in the gem  must be enumerated so no checksums are missing
  # from the .sha256 file stored at the end.
  # @param [Enumerable<RubygemContents::Entry>] entries
  def store_entries(entries)
    path_checksums = {}
    entries.each do |entry|
      path_checksums[entry.path] = entry.sha256 if entry.sha256.present?
      store_entry entry
    end
    store_checksums path_checksums
  end

  # @param [RubygemContents::Entry] entry
  def store_entry(entry)
    store_path entry
    contents.store entry if entry.body_persisted?
  end

  # @param [RubygemContents::Entry] entry
  def store_path(entry)
    fs.store(
      path_key(entry.path),
      entry.fingerprint,
      content_type: "text/plain; charset=us-ascii",
      metadata: entry.metadata
    )
  end

  # @param [Hash<String, String>] checksums path => checksum
  def store_checksums(checksums)
    fs.store(
      checksums_key,
      ShasumFormat.generate(checksums),
      content_type: "text/plain"
    )
  end

  # @param [Gem::Specification] spec
  def store_spec(spec)
    ruby_spec = spec.to_ruby
    mime = Magic.buffer(ruby_spec, Magic::MIME)
    fs.store spec_key, ruby_spec, content_type: mime
  end

  def yank
    content_keys = unique_checksums.map { |checksum| contents.key checksum }
    path_keys = fs.each_key(prefix: path_root).to_a
    fs.remove(spec_key, path_keys, content_keys, checksums_key)
  end

  def unique_checksums
    candidates = checksums.values
    candidates = contents.keys if candidates.blank?
    return [] if candidates.empty?

    # starting with all candidates, remove checksums found in other versions
    fs.each_key(prefix: checksums_root).reduce(candidates) do |remaining, key|
      next remaining if key == checksums_key
      checksums = ShasumFormat.parse(fs.get(key)).values
      remaining.difference checksums
    end
  end

  def spec_key
    format RubygemContents::SPEC_KEY_FORMAT, gem: gem, version: version
  end

  def path_root
    format RubygemContents::PATH_ROOT_FORMAT, gem: gem, version: version
  end

  def path_key(path)
    format RubygemContents::PATH_KEY_FORMAT, gem: gem, version: version, path: path
  end

  def checksums_root
    format RubygemContents::CHECKSUMS_ROOT_FORMAT, gem: gem
  end

  def checksums_key(format: :sha256)
    format RubygemContents::CHECKSUMS_KEY_FORMAT, gem: gem, version: version, format:
  end

  def ==(other)
    other.is_a?(self.class) && other.version == version && other.gem == gem
  end
end
