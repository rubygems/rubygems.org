PATH=File.expand_path("~/Projects/ruby-advisory-db")

vulnerabilities = Dir['/home/ylecuyer/Projects/ruby-advisory-db/gems/**/*.yml']
  .map { _1.split('/')[-2..] }
  .each_with_object({}) { |elt, hash| hash[elt[0]] ||= []; hash[elt[0]] << elt[1] }

vulnerabilities.each do |gem_name, cves|
  puts gem_name
  gem = Rubygem.where(name: gem_name).first
  next unless gem

  gem.versions.update_all(cve_count: 0)

  cves.each do |cve|
    yaml = YAML.load_file("#{PATH}/gems/#{gem_name}/#{cve}")
    patched_versions = yaml.dig("patched_versions") || []
    unaffected_versions = yaml.dig("unaffected_versions")

    gem.versions.each do |version|
      vulnerable = patched_versions.none? do |patched_version|
        Gem::Requirement.new(patched_version.split(',')).satisfied_by?(Gem::Version.new(version.number))
      end

      unaffected = unaffected_versions&.any? do |unaffected_version|
        Gem::Requirement.new(unaffected_version.split(',')).satisfied_by?(Gem::Version.new(version.number))
      end

      if unaffected
        next
      elsif vulnerable
        version.cve_count += 1
      end

      version.save(validate: false)
    end
  rescue Gem::Requirement::BadRequirementError => e
    puts "Error #{e.class} #{e.message}"
  end
end
