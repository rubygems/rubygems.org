require "test_helper"

class RubyAdvisoryDbTest < SystemTest
  test "it sets the correct number of vulnerabilities" do
    advisories = [
      { patched_versions: ['>= 5.0.0.beta1.1', '~> 4.2.5, >= 4.2.5.1', '~> 4.1.14, >= 4.1.14.1'], unaffected_versions: [] },
      { patched_versions: ['~> 4.1.14, >= 4.1.14.2'], unaffected_versions: ['>= 4.2.0'] },
      { patched_versions: ["~> 4.2.7.1", "~> 4.2.8", ">= 5.0.0.1"], unaffected_versions: ["< 3.0.0"] },
      { patched_versions: ['~> 4.2.11, >= 4.2.11.1', '~> 5.0.7, >= 5.0.7.2', '~> 5.1.6, >= 5.1.6.2', '~> 5.2.2, >= 5.2.2.1', '>= 6.0.0.beta3'], unaffected_versions: [] },
      { patched_versions: ['>= 6.0.0.beta3', '~> 5.2.2, >= 5.2.2.1', '~> 5.1.6, >= 5.1.6.2', '~> 5.0.7, >= 5.0.7.2', '~> 4.2.11, >= 4.2.11.1'], unaffected_versions: [] },
      { patched_versions: ["~> 5.2.4, >= 5.2.4.4", ">= 6.0.3.3"], unaffected_versions: [] },
      { patched_versions: ['~> 5.2.4, >= 5.2.4.2', '>= 6.0.2.2'] },
      { patched_versions: [">= 4.2.11.2"] },
      { patched_versions: ["~> 5.2.4, >= 5.2.4.3", ">= 6.0.3.1"], unaffected_versions: [] },
      { patched_versions: ["~> 5.2.7, >= 5.2.7.1", "~> 6.0.4, >= 6.0.4.8", "~> 6.1.5, >= 6.1.5.1", ">= 7.0.2.4"], unaffected_versions: [] },
      {}
    ]

    count = 0

    advisories.each do |advisory|
      vulnerable = (advisory[:patched_versions] || []).none? do |patched_version|
        Gem::Requirement.new(patched_version.split(',')).satisfied_by?(Gem::Version.new('7.0.4'))
      end

      unaffected = advisory[:unaffected_versions]&.any? do |unaffected_version|
        Gem::Requirement.new(unaffected_version.split(',')).satisfied_by?(Gem::Version.new('7.0.4'))
      end

      if unaffected
        next
      elsif vulnerable
        count += 1
      end
    rescue Gem::Requirement::BadRequirementError => e
      puts "Error #{e.class} #{e.message}"
    end

    assert count == 1
  end
end
