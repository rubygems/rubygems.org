namespace :ownership_request_notification do
  desc "Send email notification about ownership requests to the owners"
  task send: :environment do
    gems_with_requests = OwnershipRequest.where(created_at: 24.hours.ago..Time.current).pluck(:rubygem_id).uniq
    return unless gems_with_requests

    gems_with_requests.each do |rubygem_id|
      rubygem = Rubygem.find(rubygem_id)

      rubygem.ownership_request_notifiable_owners.each do |user|
        OwnersMailer.delay.new_ownership_requests(rubygem_id, user.id)
      end
    end
  end
end
