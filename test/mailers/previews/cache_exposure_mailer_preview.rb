# frozen_string_literal: true

class CacheExposureMailerPreview < ActionMailer::Preview
  def cache_exposure_notice
    CacheExposureMailer.cache_exposure_notice(User.last)
  end

  def cache_exposure_inactive_notice
    CacheExposureMailer.cache_exposure_inactive_notice(User.last)
  end
end
