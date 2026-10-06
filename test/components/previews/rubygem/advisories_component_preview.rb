# frozen_string_literal: true

class Rubygem::AdvisoriesComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  def moderate
    render Rubygem::AdvisoriesComponent.new(
      advisories: [
        Advisory::OSV.new(
          identifier: "GHSA-mm33-5vfq-3mm3",
          aliases: ["CVE-2022-22577"],
          summary: "Cross-site Scripting Vulnerability in Action Pack",
          severity: "moderate",
          url: "https://github.com/advisories/GHSA-mm33-5vfq-3mm3",
          ranges: ["introduced" => "0"]
        )
      ],
      version: Version.new(number: "1.0.0")
    )
  end

  def critical
    render Rubygem::AdvisoriesComponent.new(
      advisories: [
        Advisory::OSV.new(
          identifier: "GHSA-crit-ical-0001",
          aliases: ["CVE-2024-0001"],
          summary: "Remote code execution in example gem",
          severity: "critical",
          url: "https://github.com/advisories/GHSA-crit-ical-0001",
          ranges: ["introduced" => "0"]
        ),
        Advisory::OSV.new(
          identifier: "GHSA-mode-rate-0002",
          summary: "Information disclosure",
          severity: "moderate",
          url: "https://github.com/advisories/GHSA-mode-rate-0002",
          ranges: ["introduced" => "0"]
        )
      ],
      version: Version.new(number: "1.0.0")
    )
  end
end
