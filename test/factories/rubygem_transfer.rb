FactoryBot.define do
  factory :rubygem_transfer do
    created_by { association :user }
    organization { association :organization }
    rubygems { [create(:rubygem).id] }

    before(:create) do |rubygem_transfer|
      rubygem_transfer.rubygems.each do |rubygem|
        next if rubygem.blank?
        Ownership.create_with(
          authorizer: rubygem_transfer.created_by,
          confirmed_at: Time.zone.now
        ).find_or_create_by!(
          rubygem_id: rubygem,
          user: rubygem_transfer.created_by,
          role: :owner
        )
      end

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
