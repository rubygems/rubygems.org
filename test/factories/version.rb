Factory.define :version do |version|
  version.authors     { 'Joe User' }
  version.description { 'Some awesome gem' }
  version.number      { Factory.next(:version_number) }
  version.association :rubygem
end

Factory.sequence :version_number do |n|
  "0.0.#{n}"
end
