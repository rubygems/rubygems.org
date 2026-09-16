# frozen_string_literal: true

class AfterVersionWriteJob < ApplicationJob
  queue_as :default

  def perform(version:)
    version.transaction do
      rubygem = version.rubygem
      notify_pushed(rubygem.push_notifiable_owners, version)
      notify_pushed(rubygem.organization.push_notifiable_members, version) if rubygem.organization.present?
      Indexer.perform_later
      UploadVersionsFileJob.perform_later
      UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)
      UploadNamesFileJob.perform_later
      ReindexRubygemJob.perform_later(rubygem:)
      StoreVersionContentsJob.perform_later(version:)
      version.update!(indexed: true)
      gem_info = GemInfo.new(rubygem.name, cached: false)

      version.info_checksum_v2 = gem_info.info_checksum
      version.save(validate: false)

      SetLinksetHomeJob.perform_later(version:)
    end
  end

  def owner
    arguments.dig(0, :version).pusher_api_key&.owner
  end

  private

  def notify_pushed(users, version)
    users.each do |notified_user|
      Mailer.gem_pushed(owner, version.id, notified_user.id).deliver_later
    end
  end
end
