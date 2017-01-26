namespace :memcached do
  desc "Flushes memcached cache"
  task flush: :environment do
    Rails.cache.clear
  end
end
