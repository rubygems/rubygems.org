Factory.define :web_hook do |web_hook|
  web_hook.gem_name { 'string' }
  web_hook.user_id { 1 }
  web_hook.url { 'string' }
  web_hook.failure_count { 1 }
end
