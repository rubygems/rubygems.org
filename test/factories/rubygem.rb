Factory.sequence(:name) { |n| "RubyGem#{n}" }

Factory.define :rubygem do |rubygem|
  rubygem.name        { Factory.next(:name) }
  rubygem.association :linkset
end

Factory.define :rubygem_with_downloads, :parent => :rubygem do |rubygem|
  rubygem.after_create do |r|
    $redis[Download.key(r)] = r['downloads']
  end
end
