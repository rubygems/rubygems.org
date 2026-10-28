# frozen_string_literal: true

class Maintenance::BackfillLinksetLinksToVersionMetadataTask < MaintenanceTasks::Task
  def collection
    Version.includes(:rubygem, rubygem: [:linkset])
  end

  def process(version)
    linkset = version.rubygem.linkset
    return unless linkset

    if version.metadata_uri_set?
      # only the homepage does not respect #metadata_uri_set?
      backfill_links(version, linkset, Links::LINKS.slice("home"))
    else
      backfill_links(version, linkset, Links::LINKS)
    end
  end

  private

  def backfill_links(version, linkset, links)
    # would need a transaction since we're updating multiple attributes and
    # metadata_uri_set? needs to be updated atomically to keep the backfill idempotent,
    # but there is only a single update being issued here

    changes = false
    links.each do |short, long|
      next if version.metadata[long].present?

      value = linkset[short.to_sym]
      next unless value

      version.metadata[long] = value
      changes = true
    end
    version.save! if changes
  end
end
