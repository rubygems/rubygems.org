namespace :extraneous_dependencies do
  def fetch_spec_deps(full_name)
    spec_uri = URI("https://rubygems.org/quick/Marshal.4.8/#{full_name}.gemspec.rz")
    http = Net::HTTP.new(spec_uri.host, spec_uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(spec_uri.request_uri)
    res = http.request(request)

    raise StandardError, "fetch deps request for #{full_name} failed #{res.inspect}" unless res.code == "200"

    spec_obj = Marshal.load(Gem::Util.inflate(res.body))

    spec_run_deps = spec_obj.dependencies.map do |s|
      s.name.downcase if s.type == :runtime && Rubygem.where(name: s.name).present?
    end.compact.sort

    spec_dev_deps = spec_obj.dependencies.map do |s|
      s.name.downcase if s.type == :development && Rubygem.where(name: s.name).present?
    end.compact.sort

    [spec_run_deps, spec_dev_deps]
  end

  desc "Remove dependencies from DB where it doesn't match the gemspec"
  task clean: :environment do
    ActiveRecord::Base.logger.level = 1
    versions = Version.joins("inner join dependencies on versions.id = dependencies.version_id")
      .where("date_trunc('day', dependencies.created_at) = '2009-09-02 00:00:00'::timestamp")
      .where("versions.indexed = 'true'")
      .distinct("versions.id")

    total              = versions.count
    processed          = 0
    errored            = 0
    dev_mis_match      = 0
    run_mis_match      = 0
    mis_match_versions = 0

    Rails.logger.info "[extraneous_dependencies:clean] found #{total} versions for clean up"
    versions.each do |version|
      print format("\r%.2f%% (%d/%d) complete", processed.to_f / total * 100.0, processed, total)

      spec_run_deps, spec_dev_deps = fetch_spec_deps(version.full_name)

      db_run_deps = {}
      db_dev_deps = {}
      db_deps = version.dependencies.to_a
      db_deps.each do |d|
        db_run_deps[d.id.to_s] = d.rubygem.name.downcase if d.scope == "runtime" && d.rubygem.present?
        db_dev_deps[d.id.to_s] = d.rubygem.name.downcase if d.scope == "development" && d.rubygem.present?
      end

      deps_to_delete = []
      if spec_run_deps != db_run_deps.values.sort
        db_run_deps.each do |id, name|
          deps_to_delete << id unless spec_run_deps.include?(name)
        end

        run_mis_match += 1
        Rails.logger.info("[extraneous_dependencies:clean] spec and db run deps don't match "\
          "for: #{version.full_name} spec: #{spec_run_deps} db: #{db_run_deps}")
      end

      if spec_dev_deps != db_dev_deps.values.sort
        unique_dev_deps = []
        db_dev_deps.sort.to_h.each do |id, name|
          if unique_dev_deps.include?(name)
            deps_to_delete << id
          else
            unique_dev_deps << name
          end
        end

        dev_mis_match += 1
        Rails.logger.info("[extraneous_dependencies:clean] spec and db dev deps don't match "\
          "for: #{version.full_name} spec: #{spec_dev_deps} db: #{db_dev_deps}")
      end

      if deps_to_delete.present?
        mis_match_versions += 1
        Rails.logger.info("[extraneous_dependencies:clean] deleting dependencies with ids: #{deps_to_delete}")
        Dependency.destroy(deps_to_delete)
      end
    rescue StandardError => e
      errored += 1
      Rails.logger.error("[extraneous_dependencies:clean] skipping #{version.inspect} - #{e.message}")
    ensure
      processed += 1
    end

    Rails.logger.info("[extraneous_dependencies:clean] #{total_deleted_deps} dependencies deleted")
    Rails.logger.info("[extraneous_dependencies:clean] #{errored}/#{processed} errors")
    Rails.logger.info("[extraneous_dependencies:clean] #{mis_match_versions}/#{processed} version mismatches " \
      "(run_deps: #{run_mis_match}, dev_deps: #{dev_mis_match})")
  end
end
