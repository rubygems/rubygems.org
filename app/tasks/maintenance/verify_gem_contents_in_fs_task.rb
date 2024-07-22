# frozen_string_literal: true

class Maintenance::VerifyGemContentsInFsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  attribute :gem_name_pattern, :string
  attribute :version_pattern, :string
  attribute :platform_pattern, :string
  attribute :full_name_pattern, :string

  attribute :only_indexed, :boolean, default: true

  validate :patterns_are_valid

  def collection
    collection = Version.all
    collection = collection.indexed if only_indexed

    collection = collection.joins(:rubygem).where("rubygems.name ~ ?", gem_name_pattern) if gem_name_pattern.present?
    collection = matches_regexp(collection, :version, version_pattern) if version_pattern.present?
    collection = matches_regexp(collection, :platform, platform_pattern)  if platform_pattern.present?
    collection = matches_regexp(collection, :full_name, full_name_pattern) if full_name_pattern.present?

    collection
  end

  def process(version)
    logger.tagged(version_id: version.id, name: version.rubygem.name, number: version.number, platform: version.platform) do
      validate_checksum(version, "gem", "gems/#{version.gem_file_name}", version.sha256)
      validate_checksum(version, "spec", "quick/Marshal.4.8/#{version.full_name}.gemspec.rz", version.spec_sha256)
    end
  end

  private

  def patterns_are_valid
    %i[gem_name_pattern version_pattern platform_pattern full_name_pattern].each do |pattern|
      next if send(pattern).blank?
      begin
        Regexp.new(send(pattern))
      rescue RegexpError
        errors.add(pattern, "is not a valid regular expression")
      end
    end
  end

  def matches_regexp(collection, field, regexp)
    collection.where(collection.arel_table[field].matches_regexp(regexp))
  end

  def validate_checksum(version, name, path, expected_checksum)
    logger.warn "Version #{version.fullname} has no #{name} checksum" if expected_checksum.blank?
    contents = RubygemFs.instance.get(path)
    logger.warn "Version #{version.full_name} is missing #{name} contents (#{path})" if contents.blank?

    return unless contents.present? && expected_checksum.present?
    sha256 = Digest::SHA256.base64digest(contents)
    logger.error "#{path} has incorrect checksum (expected #{expected_checksum}, got #{sha256})" if sha256 != expected_checksum
  end
end
