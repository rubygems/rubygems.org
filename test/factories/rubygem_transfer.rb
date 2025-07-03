FactoryBot.define do
  factory :rubygem_transfer do
    rubygem { association :rubygem }
    created_by { association :user }
    organization { association :organization }

    before(:create) do |rubygem_transfer|
      rubygem_transfer.rubygem.ownerships.create!(
        user: rubygem_transfer.created_by,
        role: :owner,
        authorizer: rubygem_transfer.created_by,
        confirmed_at: Time.zone.now
      )

      rubygem_transfer.organization.memberships.create!(
        user: rubygem_transfer.created_by,
        role: :owner,
        confirmed_at: Time.zone.now
      )
    end
  end
end
