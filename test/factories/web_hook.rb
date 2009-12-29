Factory.define :web_hook do |web_hook|
  web_hook.url { 'http://example.org' }
  web_hook.association :user
  web_hook.association :rubygem
end

Factory.define :global_web_hook, :parent => :web_hook do |web_hook|
  web_hook.rubygem { nil }
end
