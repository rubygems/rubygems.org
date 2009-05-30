Factory.define :version do |version|
  version.authors     { 'Joe User' }
  version.description { 'Some awesome gem' }
  version.number      { '0.0.0' }
  version.association :rubygem
end
