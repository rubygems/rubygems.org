namespace :dependency do
  desc "Update dependencies to reset rubygem_id where rubygem_id is dangling"
  task dangling_rubygem_id_purge: :environment do
    dependencies = Dependency.joins("LEFT JOIN rubygems on dependencies.rubygem_id = rubygems.id")
      .where("rubygems.id is null and dependencies.rubygem_id is not null")

    total     = dependencies.count
    processed = 0

    Rails.logger.info "[dependency:dangling_rubygem_id_purge] found #{total} dependencies for clean up"
    dependencies.each do |dependency|
      print format("\r%.2f%% (%d/%d) complete", processed.to_f / total * 100.0, processed, total)

      Rails.logger.info("[dependency:dangling_rubygem_id_purge] setting dependency: #{dependency.id} rubygem_id: #{dependency.rubygem_id} to null")
      dependency.update_attribute(:rubygem_id, nil)
      processed += 1
    end
  end
end
