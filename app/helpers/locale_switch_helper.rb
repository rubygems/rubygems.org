# frozen_string_literal: true

module LocaleSwitchHelper
  def default_search_engine_tags
    return if signed_in?
    return unless request.get? || request.head?
    return if request.query_string.present?

    canonical_link_tags { |locale| localized_url_for_current_page(locale) }
  end

  def canonical_link_tags
    canonical = tag.link(rel: "canonical", href: yield(I18n.locale))
    alternates = I18n.available_locales.map do |locale|
      tag.link(rel: "alternate", hreflang: locale, href: yield(locale))
    end
    x_default = tag.link(rel: "alternate", hreflang: "x-default", href: yield(I18n.default_locale))

    safe_join([canonical, *alternates, x_default], "\n")
  end

  def locale_switch_path(locale)
    url_for(
      locale_switch_path_parameters.merge(
        locale: LocaleRouting.locale_param(locale),
        params: request.query_parameters.except(:locale, "locale"),
        only_path: true
      )
    )
  end

  delegate :locale_param, to: :LocaleRouting

  private

  def localized_url_for_current_page(locale = I18n.locale)
    url_for(request.path_parameters.merge(locale: LocaleRouting.locale_param(locale), only_path: false))
  end

  def locale_switch_path_parameters
    return request.path_parameters if request.get? || request.head?

    form_action = { "create" => "new", "update" => "edit" }[request.path_parameters[:action]]
    if form_action
      form_path_parameters = request.path_parameters.merge(action: form_action)
      return form_path_parameters if locale_switch_path_routable?(form_path_parameters)
    end

    { controller: "home", action: "index" }
  end

  def locale_switch_path_routable?(path_parameters)
    url_for(path_parameters.merge(only_path: true))
    true
  rescue ActionController::UrlGenerationError
    false
  end
end
