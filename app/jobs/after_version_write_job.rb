class AfterVersionWriteJob < ApplicationJob
  queue_as :default

  def perform(version:)
    version.transaction do
      rubygem = version.rubygem
      version.rubygem.push_notifiable_owners.each do |notified_user|
        Mailer.gem_pushed(owner, version.id, notified_user.id).deliver_later
      end
      Indexer.perform_later
      UploadVersionsFileJob.perform_later
      UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)
      UploadNamesFileJob.perform_later
      ReindexRubygemJob.perform_later(rubygem:)
      StoreVersionContentsJob.perform_later(version:)
      version.update!(indexed: true)
      checksum = GemInfo.new(rubygem.name, cached: false).info_checksum
      version.update_attribute :info_checksum, checksum
      SetLinksetHomeJob.perform_later(version:)
    end
  end

  def owner
    arguments.dig(0, :version).pusher_api_key&.owner
  end
end
