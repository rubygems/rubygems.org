Factory.define :dependency do |dependency|
  dependency.name { 'string' }
  dependency.rubygem_id { 1 }
  dependency.requirement { 'string' }
end
