# frozen_string_literal: true

namespace :compact_index do
  namespace :backfill do
    def resolve_format(version_key)
      key = version_key&.to_sym || :v2
      format = CompactIndex.active_formats.find { |f| f.version_key == key }
      format || CompactIndex::Format.new(
        version_key: key,
        gem_version_class: CompactIndex.const_get(key.upcase)::GemVersion
      )
    end

    desc "Backfill info checksums for a format version (VERSION_KEY=v2)"
    task checksums: :environment do
      format = resolve_format(ENV["VERSION_KEY"])
      col = format.checksum_column

      rubygems = Rubygem.joins(:versions).where(versions: { indexed: true, col => nil }).distinct
      total = rubygems.count
      i = 0

      puts "Backfilling #{col} for #{total} rubygems..."

      rubygems.find_each do |rubygem|
        gem_info = GemInfo.new(rubygem.name, cached: false)
        versions = gem_info.compact_index_info_for(format)
        checksum = Digest::MD5.hexdigest(CompactIndex.info(versions))

        last_version = rubygem.versions.where(indexed: true).order(:created_at).last
        last_version&.update_columns(col => checksum)

        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end

      puts
      puts "Done."
    end

    desc "Backfill yanked info checksums for a format version (VERSION_KEY=v2)"
    task yanked_checksums: :environment do
      format = resolve_format(ENV["VERSION_KEY"])
      col = format.yanked_checksum_column

      without_checksum = Version.where(indexed: false, col => nil).where.not(yanked_at: nil)
      total = without_checksum.count
      i = 0

      puts "Backfilling #{col} for #{total} versions..."

      without_checksum.find_each do |version|
        gem_info = GemInfo.new(version.rubygem.name, cached: false)
        versions = gem_info.compact_index_info_for(format)
        checksum = Digest::MD5.hexdigest(CompactIndex.info(versions))

        version.update_columns(col => checksum)

        i += 1
        print format("\r%.2f%% (%d/%d) complete", i.to_f / total * 100.0, i, total)
      end

      puts
      puts "Done."
    end

    desc "Generate versions file for a format version (VERSION_KEY=v2)"
    task generate_versions_file: :environment do
      format = resolve_format(ENV["VERSION_KEY"])
      versions_path = format.versions_file_path

      if versions_path.nil?
        puts "Error: versions_file_location_#{format.version_key} not configured in rubygems.yml"
        exit 1
      end

      ts = Time.now.utc.iso8601
      versions_file = CompactIndex::VersionsFile.new(versions_path)
      gems = GemInfo.compact_index_public_versions_for(ts, format)

      missing = gems.select { |g| g.versions.any? { |v| v.info_checksum.nil? } }
      if missing.any?
        puts "Error: #{missing.size} gem(s) missing #{format.checksum_column}. Run compact_index:backfill:checksums first."
        puts "First 10: #{missing.map(&:name).first(10).join(', ')}"
        exit 1
      end

      versions_file.create(gems, ts)
      puts "Generated #{versions_path} with #{gems.size} gems at #{ts}"
    end
  end
end
