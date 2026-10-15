# frozen_string_literal: true

class Maintenance::SeedFooterSponsorsTask < MaintenanceTasks::Task
  SPONSORS = [
    ["Ruby Central", "https://rubycentral.org/", "ruby-central", "open_source"],
    ["AWS", "https://aws.amazon.com/", "aws", "infrastructure"],
    ["DNSimple", "https://dnsimple.link/resolving-rubygems", "dnsimple", "infrastructure"],
    ["Datadog", "https://www.datadoghq.com/", "datadog", "infrastructure"],
    ["Fastly", "https://www.fastly.com/", "fastly", "infrastructure"],
    ["Honeybadger", "https://www.honeybadger.io/", "honeybadger", "infrastructure"],
    ["Mend", "https://mend.io/", "mend-io", "infrastructure"]
  ].freeze

  def collection
    SPONSORS.each_with_index.to_a
  end

  def process(entry)
    (name, website_url, asset, tier), position = entry
    # Serialize task reruns without adding a public-name uniqueness contract.
    Sponsor.transaction do
      Sponsor.connection.execute("SELECT pg_advisory_xact_lock(2026101401)")
      return if Sponsor.exists?(name: name)

      sponsor = Sponsor.new(name:, website_url:, tier:, position:, show_in_footer: true)
      # Active Storage uploads after the transaction commits, so the IO must
      # remain open until then rather than closing in a File.open block.
      io = StringIO.new(Rails.root.join("app/assets/images/sponsors/#{asset}.png").binread)
      sponsor.logo.attach(io:, filename: "#{asset}.png", content_type: "image/png")
      sponsor.save!
    end
  end
end
