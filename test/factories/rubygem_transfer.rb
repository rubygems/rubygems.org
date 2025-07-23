FactoryBot.define do
  factory :rubygem_transfer do
    rubygem { association :rubygem }
    created_by { association :user }
    organization { association :organization }

    before(:create) do |rubygem_transfer|
      rubygem_transfer.rubygem.ownerships.create_with(
        authorizer: rubygem_transfer.created_by,
        confirmed_at: Time.zone.now
      ).find_or_create_by!(
        user: rubygem_transfer.created_by,
        role: :owner
      )

      rubygem_transfer.organization.memberships
        .create_with(
          confirmed_at: Time.zone.now
        ).find_or_create_by!(
          user: rubygem_transfer.created_by,
          role: :owner
        )
    end
  end
end
