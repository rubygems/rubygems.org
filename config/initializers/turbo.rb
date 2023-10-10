# https://github.com/hotwired/turbo-rails/issues/512
#
Rails.autoloaders.once.do_not_eager_load("#{Turbo::Engine.root}/app/channels")
