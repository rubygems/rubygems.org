# frozen_string_literal: true

namespace :compact_index_v2 do
  desc "Generate/update the baseline v2 versions.list file"
  task update_versions_file: :environment do
    UpdateVersionsListJob.perform_now(version: 2)
  end
end
