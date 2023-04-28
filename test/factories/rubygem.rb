FactoryBot.define do
  factory :rubygem do
    transient do
      owners { [] }
      number { nil }
      downloads { 0 }
    end

    name

    after(:build) do |rubygem, evaluator|
      if evaluator.linkset
        rubygem.linkset = evaluator.linkset
      else
        build(:linkset, rubygem: rubygem)
      end
    end

    after(:create) do |rubygem, evaluator|
      evaluator.owners.each do |owner|
        create(:ownership, rubygem: rubygem, user: owner)
      end

      create(:version, rubygem: rubygem, number: evaluator.number) if evaluator.number
      GemDownload.increment(evaluator.downloads, rubygem_id: rubygem.id, version_id: 0) if evaluator.downloads
    end
  end
end
