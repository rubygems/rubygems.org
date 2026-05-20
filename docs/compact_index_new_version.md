# Adding a New Compact Index Version

## Prerequisites

- The current format is stable and serving
- You know what field(s) the new version adds

## Steps

### 1. Create the GemVersion class

Create `lib/compact_index/v<N>/gem_version.rb`:

```ruby
# lib/compact_index/v2/gem_version.rb
require_relative "../gem_version"

module CompactIndex
  module V2
    class GemVersion < CompactIndex::GemVersion
      attribute :created_at
    end
  end
end
```

### 2. Add DB columns

Create a migration to add checksum columns to the versions table:

```bash
bin/rails generate migration AddCompactIndexV<N>ColumnsToVersions
```

```ruby
class AddCompactIndexV2ColumnsToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :info_checksum_v2, :string
    add_column :versions, :yanked_info_checksum_v2, :string
  end
end
```

```bash
bin/rails db:migrate
```

### 3. Add versions file location to config

In `config/rubygems.yml`, add for each environment:

```yaml
versions_file_location_v2: "./config/versions_v2.list"
```

### 4. Enable the format

In `lib/compact_index.rb`:

```ruby
require_relative "compact_index/v2/gem_version"

module CompactIndex
  CURRENT_FORMAT = Format.new(version_key: :v1)
  NEXT_FORMAT    = Format.new(version_key: :v2, gem_version_class: V2::GemVersion)
  # ...
end
```

Deploy. New pushes and yanks now write both V1 and V2 checksums.
This ensures no gems pushed during the backfill window are missing V2 data.

### 5. Backfill checksums

Fill in V2 checksums for all existing gems:

```bash
bin/rails compact_index:backfill:checksums VERSION_KEY=v2
bin/rails compact_index:backfill:yanked_checksums VERSION_KEY=v2
```

### 6. Generate the versions file

Create the initial versions file from scratch (requires all checksums to be present):

```bash
bin/rails compact_index:backfill:generate_versions_file VERSION_KEY=v2
```

### 7. Switch serving to V2

Once backfill is complete and the versions file is generated, flip the Flipper flag
to start serving V2 to clients:

```ruby
Flipper.enable(:compact_index_next_format)
```

This can be done from the admin panel at `/features` — no deploy needed.

### 8. Verify

```bash
# Should now return V2 format (with new field)
curl -s https://rubygems.org/info/<gem>
```

## Rolling Back

Disable the Flipper flag to revert serving to V1 — no deploy needed:

```ruby
Flipper.disable(:compact_index_next_format)
```

To stop writing V2 entirely, also set `NEXT_FORMAT = nil` and deploy.

## Rolling Up (Retiring the Old Version)

Once V2 is stable and V1 is no longer needed:

### 1. Move the pointer

```ruby
CURRENT_FORMAT = Format.new(version_key: :v2)
NEXT_FORMAT    = nil
```

### 2. Roll the field into BASE_FIELDS

In `lib/compact_index/gem_version.rb`, add the new field to `BASE_FIELDS`:

```ruby
BASE_FIELDS = %i[number platform checksum info_checksum
                 dependencies ruby_version rubygems_version
                 created_at].freeze
```

### 3. Delete the old version directory

```bash
rm -rf lib/compact_index/v2/
```

Remove the require from `compact_index.rb`.

### 4. Clean up

- Drop old DB columns (e.g., `info_checksum`, `yanked_info_checksum` for V1)
- Delete old S3 files (`info/*`, `versions`, `names`)
- Remove old versions file location from `rubygems.yml`
- Remove the old migration file

