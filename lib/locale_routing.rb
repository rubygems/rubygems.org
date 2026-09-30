# frozen_string_literal: true

module LocaleRouting
  DEFAULT_LOCALE = I18n.default_locale.to_s.freeze
  SUPPORTED_LOCALES = I18n.available_locales.map(&:to_s).freeze
  PATH_CONSTRAINT = Regexp.union(SUPPORTED_LOCALES)

  def self.default_locale?(locale)
    locale.to_s == DEFAULT_LOCALE
  end

  def self.locale_param(locale)
    default_locale?(locale) ? nil : locale
  end
end
