# frozen_string_literal: true

module LocaleSwitchHelper
  def default_locale_link_tags
    return unless request.get? || request.head?
    return if content_for?(:head)

    canonical_url = localized_url_for_current_page
    alternate_urls = I18n.available_locales.map do |locale|
      tag.link(rel: "alternate", hreflang: locale, href: localized_url_for_current_page(locale))
    end

    safe_join([
                tag.link(rel: "canonical", href: canonical_url),
                *alternate_urls,
                tag.link(rel: "alternate", hreflang: "x-default", href: canonical_url)
              ], "\n")
  end

  def locale_switch_path(locale)
    locale = nil if LocaleRouting.default_locale?(locale)
    url_for(
      locale_switch_path_parameters.merge(
        locale: locale,
        params: request.query_parameters.except(:locale, "locale"),
        only_path: true
      )
    )
  end

  private

  def localized_url_for_current_page(locale = I18n.default_locale)
    locale = nil if LocaleRouting.default_locale?(locale)
    url_for(request.path_parameters.merge(locale: locale, only_path: false))
  end

  def locale_switch_path_parameters
    return request.path_parameters if request.get? || request.head?

    form_path_parameters = case request.path_parameters[:action]
                           when "create"
                             request.path_parameters.merge(action: "new")
                           when "update"
                             request.path_parameters.merge(action: "edit")
                           else
                             request.path_parameters
                           end

    return form_path_parameters if locale_switch_path_routable?(form_path_parameters)

    { controller: "home", action: "index" }
  end

  def locale_switch_path_routable?(path_parameters)
    url_for(path_parameters.merge(only_path: true))
    true
  rescue ActionController::UrlGenerationError
    false
  end
end
