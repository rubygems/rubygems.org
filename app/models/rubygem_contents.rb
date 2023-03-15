# frozen_string_literal: true

class RubygemContents
  CHECKSUMS_ROOT_FORMAT = "gems/%{gem}/checksums/"
  CHECKSUMS_KEY_FORMAT = "gems/%{gem}/checksums/%{version}.%{format}"
  CONTENT_ROOT_FORMAT = "gems/%{gem}/contents/"
  CONTENT_KEY_FORMAT = "gems/%{gem}/contents/%{fingerprint}"
  PATH_ROOT_FORMAT = "gems/%{gem}/paths/%{version}/"
  PATH_KEY_FORMAT = "gems/%{gem}/paths/%{version}/%{path}"
  SPEC_KEY_FORMAT = "gems/%{gem}/specs/%{gem}-%{version}.gemspec"

  attr_reader :gem

  def initialize(gem:)
    raise ArgumentError, "gem must be Rubygem#name" unless gem.try(:match?, Rubygem::NAME_PATTERN)
    @gem = gem
  end

  def fs
    RubygemFs.contents
  end

  def get(fingerprint)
    return if fingerprint.blank?
    fs.get key(fingerprint)
  end

  def keys
    fs.each_key(prefix: root).map { |key| key.delete_prefix root }
  end

  def store(entry)
    return unless entry.body_persisted?
    fs.store(
      key(entry.fingerprint),
      entry.body,
      content_type: entry.content_type,
      content_length: entry.size,
      checksum_sha256: entry.sha256
    )
    entry.fingerprint
  end

  def root
    format CONTENT_ROOT_FORMAT, gem: gem
  end

  def key(fingerprint)
    format CONTENT_KEY_FORMAT, gem: gem, fingerprint: fingerprint
  end

  def ==(other)
    other.is_a?(self.class) && other.gem == gem
  end
end
