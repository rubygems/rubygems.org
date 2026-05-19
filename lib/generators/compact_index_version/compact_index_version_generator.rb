# frozen_string_literal: true

# Generates all files needed for a new compact index version.
#
# Usage:
#   rails generate compact_index_version                    # next version, same fields
#   rails generate compact_index_version rust_version       # next version, adds rust_version
#   rails generate compact_index_version size rust_version  # next version, adds size and rust_version
#
# Generates:
#   - lib/compact_index/gem_version_vN.rb (version class with schema)
#   - app/models/gem_info/format_vN.rb (format registration)
#   - db/migrate/..._add_info_checksum_vN_to_versions.rb
#   - Updates config/rubygems.yml with versions_file_location_vN
class CompactIndexVersionGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  argument :new_fields, type: :array, default: [], banner: "field1 field2 ..."

  def determine_next_version
    @next_version_number = current_max_version + 1
    @version_key = "v#{@next_version_number}"
    @class_suffix = "V#{@next_version_number}"
    say_status :create, "Compact index #{@version_key}", :green
  end

  def compute_schema
    @fields = (previous_version_fields + new_fields.map(&:to_sym)).uniq
    say_status :schema, @fields.join(", "), :cyan
  end

  def create_gem_version_class
    create_file "lib/compact_index/gem_version_#{@version_key}.rb", <<~RUBY
      # frozen_string_literal: true

      module CompactIndex
        class GemVersion#{@class_suffix} < BaseGemVersion
          define_schema #{@fields.map { |f| ":#{f}" }.join(", ")}
        end
      end
    RUBY
  end

  def create_format_class
    create_file "app/models/gem_info/format_#{@version_key}.rb", <<~RUBY
      # frozen_string_literal: true

      class GemInfo
        class Format#{@class_suffix} < Format
          def initialize
            super(
              version_key: :#{@version_key},
              gem_version_class: CompactIndex::GemVersion#{@class_suffix}
            )
          end
        end
      end
    RUBY
  end

  def create_migration
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    create_file "db/migrate/#{timestamp}_add_info_checksum_#{@version_key}_to_versions.rb", <<~RUBY
      # frozen_string_literal: true

      class AddInfoChecksum#{@class_suffix}ToVersions < ActiveRecord::Migration[7.2]
        def change
          safety_assured do
            change_table :versions, bulk: true do |t|
              t.string :info_checksum_#{@version_key}
              t.string :yanked_info_checksum_#{@version_key}
            end
          end
        end
      end
    RUBY
  end

  def register_in_formats
    inject_into_file "app/models/gem_info.rb",
      after: /FORMATS = \{[^}]*\n/ do
      ""
    end

    # Insert before the closing }.freeze
    gsub_file "app/models/gem_info.rb",
      /([ \t]*)(}.freeze)/ do |_match|
      "#{$1}#{@version_key}: Format#{@class_suffix}.new,\n#{$1}#{$2}"
    end
  end

  def add_versions_file_config
    config_key = "versions_file_location_#{@version_key}"
    gsub_file "config/rubygems.yml",
      /(versions_file_location(?:_v\d+)?:[^\n]*\n)(?!\s*versions_file_location)/ do |match|
      "#{match}  #{config_key}: \"./config/versions_#{@version_key}.list\"\n"
    end
  end

  def display_instructions
    say ""
    say "✅ Generated compact index #{@version_key}!", :green
    say ""
    if new_fields.any?
      say "Manual step:", :yellow
      say "  Add #{new_fields.join(', ')} to app/models/gem_info.rb:"
      say "    • requirements_and_dependencies group_by_columns"
      say "    • row_to_hash destructure"
      say ""
    end
    say "Next steps:", :cyan
    say "  1. rails db:migrate"
    say "  2. Deploy (new pushes start writing #{@version_key} immediately)"
    say "  3. Backfill: Maintenance::BackfillCompactIndexChecksumsTask(format_version: '#{@version_key}')"
    say "  4. Bootstrap: rake compact_index:regenerate_versions_file[#{@version_key}]"
    say ""
  end

  private

  def current_max_version
    Dir.glob(Rails.root.join("app/models/gem_info/format_v*.rb"))
      .map { |f| File.basename(f, ".rb").delete_prefix("format_v").to_i }
      .max || 1
  end

  def previous_version_fields
    prev_key = "v#{current_max_version}"
    prev_format = GemInfo::FORMATS[prev_key.to_sym]
    prev_format&.gem_version_class&.fields || CompactIndex::GemVersion.fields
  end
end
