# frozen_string_literal: true

module LocaleRouting
  DEFAULT_LOCALE = I18n.default_locale.to_s.freeze
  SUPPORTED_LOCALES = I18n.available_locales.map(&:to_s).freeze
  NON_DEFAULT_LOCALES = (SUPPORTED_LOCALES - [DEFAULT_LOCALE]).freeze
  PATH_CONSTRAINT = /#{NON_DEFAULT_LOCALES.map { |locale| Regexp.escape(locale) }.join('|')}/

  def self.default_locale?(locale)
    locale.to_s == DEFAULT_LOCALE
  end
end
