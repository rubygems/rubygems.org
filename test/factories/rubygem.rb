FactoryGirl.define do
  sequence :name do |n|
    "RubyGem#{n}"
  end

  factory :rubygem do
    linkset
    name
  end

  factory :rubygem_with_downloads, :parent => :rubygem do
    after_create do |r|
      $redis[Download.key(r)] = r['downloads']
    end
  end
end
