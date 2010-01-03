Factory.define :version do |version|
  version.authors           { ['Joe User'] }
  version.description       { 'Some awesome gem' }
  version.number            { Factory.next(:version_number) }
  version.built_at          { 1.day.ago }
  version.platform          { "ruby" }
  version.rubyforge_project { 'awesome' }
  version.association       :rubygem
end

Factory.sequence :version_number do |n|
  "0.0.#{n}"
end
