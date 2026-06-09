# frozen_string_literal: true

module LocaleRouting
  DEFAULT_LOCALE = I18n.default_locale.to_s.freeze
  SUPPORTED_LOCALES = I18n.available_locales.map(&:to_s).freeze
  NON_DEFAULT_LOCALES = (SUPPORTED_LOCALES - [DEFAULT_LOCALE]).freeze
  PATH_CONSTRAINT = /#{NON_DEFAULT_LOCALES.map { |locale| Regexp.escape(locale) }.join('|')}/

  def self.default_locale?(locale)
    locale.to_s == DEFAULT_LOCALE
  end

  def self.localized_redirect(path)
    lambda { |params, _request|
      locale = params[:locale].presence
      locale ? "/#{locale}#{path}" : path
    }
  end

  def self.strip_default_locale_redirect
    lambda { |params, request|
      # Collapse any leading slashes from the wildcard segment before building the
      # redirect path. Without this, a crafted request such as `/en/%2Fevil.com`
      # makes `params[:path]` start with "/", producing a protocol-relative
      # Location ("//evil.com") that escapes the origin (open redirect).
      rest = params[:path].to_s.sub(%r{\A/+}, "")
      path = rest.empty? ? "/" : "/#{rest}"
      request.query_string.present? ? "#{path}?#{request.query_string}" : path
    }
  end
end
