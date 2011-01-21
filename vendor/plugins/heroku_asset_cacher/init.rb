require 'actionpack_overrides'
Rails.application.config.middleware.use HerokuAssetCacher
