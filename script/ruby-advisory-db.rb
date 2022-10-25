PATH=File.expand_path("~/Projects/ruby-advisory-db")

vulnerabilities = Dir['/home/ylecuyer/Projects/ruby-advisory-db/gems/**/*.yml']
  .map { _1.split('/')[-2..] }
  .each_with_object({}) { |elt, hash| hash[elt[0]] ||= []; hash[elt[0]] << elt[1] }

vulnerabilities.each do |gem_name, cves|
  puts gem_name
  gem = Rubygem.includes(:versions).where(name: gem_name).first
  next unless gem

  gem.versions.update_all(cve_count: 0, cves: '')

  cves_cache = {}

  Version.transaction do
    gem.versions.find_each do |version|
      gem_version = Gem::Version.new(version.number)

      cves.each do |cve|
        cve_file_path = "#{PATH}/gems/#{gem_name}/#{cve}"

        yaml = if cves_cache.key?(cve_file_path)
                 cves_cache[cve_file_path]
               else
                 cves_cache[cve_file_path] = YAML.load_file(cve_file_path)
               end

        patched_versions = yaml.dig("patched_versions") || []
        unaffected_versions = yaml.dig("unaffected_versions")

        unaffected = unaffected_versions&.any? do |unaffected_version|
          Gem::Requirement.new(unaffected_version.split(',')).satisfied_by?(gem_version)
        end

        next if unaffected

        vulnerable = patched_versions.none? do |patched_version|
          Gem::Requirement.new(patched_version.split(',')).satisfied_by?(gem_version)
        end

        if vulnerable
          version.cve_count += 1
        end

        version.save(touch: false, validate: false) if version.cve_count != 0
        version.cves = (version.cves.split(' / ') + [cve.gsub('.yml', '')]).join(' / ')
      end
    rescue Gem::Requirement::BadRequirementError => e
      puts "Error #{e.class} #{e.message}"
    end
  end
end
