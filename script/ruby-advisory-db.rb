RUBY_ADVISORY_GIT = 'https://github.com/rubysec/ruby-advisory-db.git'
CLONE_PATH = "/tmp/ruby-advisory-db/"

if Dir.exists?(CLONE_PATH)
  Dir.chdir(CLONE_PATH) do
    system "git pull --quiet origin master"
  end
else
  system "git clone --quiet #{RUBY_ADVISORY_GIT} #{CLONE_PATH}"
end

vulnerabilities = Dir["#{CLONE_PATH}/gems/**/*.yml"]
  .map { _1.split('/')[-2..] }
  .each_with_object({}) { |elt, hash| hash[elt[0]] ||= []; hash[elt[0]] << elt[1] }

cves_cache = {}

vulnerabilities.each do |gem_name, cves|
  puts gem_name
  gem = Rubygem.includes(:versions).where(name: gem_name).first
  next unless gem

  Version.transaction do
    gem.versions.find_each do |version|
      version.vulnerabilities.clear

      gem_version = Gem::Version.new(version.number)

      cves.each do |cve|
        cve_file_path = "#{CLONE_PATH}/gems/#{gem_name}/#{cve}"
        yaml = cves_cache.fetch(cve_file_path) do
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
          vulnerability = Vulnerability.where(identifier: cve.gsub('.yml', '')).first_or_create! do |vuln|
            vuln.url = yaml.dig('url')
            vuln.title = yaml.dig('title')
            vuln.severity = if cvss_v3 = yaml.dig('cvss_v3')
              case cvss_v3
              when 0.1..3.9
                :low
              when 4.0..6.9
                :medium
              when 7.0..8.9
                :high
              when 9.0..10.0
                :critical
              end
            elsif cvss_v2 = yaml.dig('cvss_v2')
              case cvss_v2
              when 0.0..3.9
                :low
              when 4.0..6.9
                :medium
              when 7.0..10.0
                :high
              end
            else
              :unknown
            end
          end
          version.vulnerabilities << vulnerability
        end
      end
    rescue Gem::Requirement::BadRequirementError => e
      puts "Error #{e.class} #{e.message}"
    end
  end
end
