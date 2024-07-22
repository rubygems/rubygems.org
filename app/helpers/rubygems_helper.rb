module RubygemsHelper
  def pluralized_licenses_header(version)
    t("rubygems.show.licenses_header", count: version&.licenses&.length || 0)
  end

  def formatted_licenses(license_names)
    if license_names.blank?
      t("rubygems.show.no_licenses")
    else
      Array(license_names).join ", "
    end
  end

  def link_to_page(id, url, verified: false)
    classes = %w[gem__link t-list__item]
    classes << "gem__link__verified" if verified
    link_to(t("rubygems.aside.links.#{id}"), url, rel: "nofollow", class: classes, id: id) if url.present?
  end

  def link_to_directory
    ("A".."Z").map do |letter|
      link_to(letter, rubygems_path(letter: letter), class: "gems__nav-link")
    end.join("\n").html_safe
  end

  def simple_markup(text)
    if /^==+ [A-Z]/.match?(text)
      options = RDoc::Options.new
      options.pipe = true
      sanitize RDoc::Markup.new.convert(text, RDoc::Markup::ToHtml.new(options))
    else
      tag.p(escape_once(sanitize(text.strip)))
    end
  end

  def subscribe_link(rubygem)
    if signed_in?
      if rubygem.subscribers.find_by_id(current_user.id)
        link_to t(".links.unsubscribe"), rubygem_subscription_path(rubygem.slug),
          class: [:toggler, "gem__link", "t-list__item"], id: "unsubscribe",
          method: :delete
      else
        link_to t(".links.subscribe"), rubygem_subscription_path(rubygem.slug),
          class: %w[toggler gem__link t-list__item], id: "subscribe",
          method: :post
      end
    else
      link_to t(".links.subscribe"), sign_in_path,
        class: [:toggler, "gem__link", "t-list__item"], id: :subscribe
    end
  end

  def unsubscribe_link(rubygem)
    return unless signed_in?
    style = "t-item--hidden" unless rubygem.subscribers.find_by_id(current_user.id)

    link_to t("rubygems.aside.links.unsubscribe"), rubygem_subscription_path(rubygem.slug),
      class: [:toggler, "gem__link", "t-list__item", style], id: "unsubscribe",
      method: :delete, remote: true
  end

  def change_diff_link(rubygem, latest_version)
    return if latest_version.yanked?

    diff_url = "https://my.diffend.io/gems/#{rubygem.name}/prev/#{latest_version.slug}"

    link_to t("rubygems.aside.links.review_changes"), diff_url,
      class: "gem__link t-list__item"
  end

  def atom_link(rubygem)
    link_to t(".links.rss"), rubygem_versions_path(rubygem.slug, format: "atom"),
      class: "gem__link t-list__item", id: :rss
  end

  def reverse_dependencies_link(rubygem)
    link_to_page :reverse_dependencies, rubygem_reverse_dependencies_path(rubygem.slug)
  end

  def badge_link(rubygem)
    badge_url = "https://badge.fury.io/rb/#{rubygem.name}/install"
    link_to t("rubygems.aside.links.badge"), badge_url, class: "gem__link t-list__item", id: :badge
  end

  def report_abuse_link(rubygem)
    subject = "Reporting Abuse on #{rubygem.name}"
    report_abuse_url = "mailto:support@rubygems.org" \
                       "?subject=" + subject
    link_to t("rubygems.aside.links.report_abuse"), report_abuse_url.html_safe, class: "gem__link t-list__item"
  end

  def ownership_link(rubygem)
    link_to I18n.t("rubygems.aside.links.ownership"), rubygem_owners_path(rubygem.slug), class: "gem__link t-list__item"
  end

  def rubygem_trusted_publishers_link(rubygem)
    link_to t("rubygems.aside.links.trusted_publishers"), rubygem_trusted_publishers_path(rubygem.slug), class: "gem__link t-list__item"
  end

  def oidc_api_key_role_links(rubygem)
    roles = current_user.oidc_api_key_roles.for_rubygem(rubygem)

    links = roles.map do |role|
      link_to(
        t("rubygems.aside.links.oidc.api_key_role.name", name: role.name),
        profile_oidc_api_key_role_path(role.token),
        class: "gem__link t-list__item"
      )
    end
    links << link_to(
      t("rubygems.aside.links.oidc.api_key_role.new"),
      new_profile_oidc_api_key_role_path(rubygem: rubygem.name, scopes: ["push_rubygem"]),
      class: "gem__link t-list__item"
    )

    safe_join(links)
  end

  def resend_owner_confirmation_link(rubygem)
    link_to I18n.t("rubygems.aside.links.resend_ownership_confirmation"),
            resend_confirmation_rubygem_owners_path(rubygem.slug), class: "gem__link t-list__item"
  end

  def rubygem_adoptions_link(rubygem)
    link_to "Adoption",
      rubygem_adoptions_path(rubygem.slug), class: "gem__link t-list__item"
  end

  def rubygem_security_events_link(rubygem)
    link_to "Security Events",
      security_events_rubygem_path(rubygem.slug), class: "gem__link t-list__item"
  end

  def links_to_owners(rubygem)
    rubygem.owners.sort_by(&:id).inject("") { |link, owner| link << link_to_user(owner) }.html_safe
  end

  def links_to_owners_without_mfa(rubygem)
    rubygem.owners.without_mfa.sort_by(&:id).inject("") { |link, owner| link << link_to_user(owner) }.html_safe
  end

  def link_to_user(user)
    link_to avatar(48, "gravatar-#{user.id}", user), profile_path(user.display_id),
      alt: user.display_handle, title: user.display_handle
  end

  def link_to_pusher(api_key_owner)
    case api_key_owner
    when OIDC::TrustedPublisher::GitHubAction
      image_tag "github_icon.png", width: 48, height: 48, theme: :light, alt: "GitHub", title: api_key_owner.name
    else
      raise ArgumentError, "unknown api_key_owner type #{api_key_owner.class}"
    end
  end

  def nice_date_for(time)
    time.to_date.to_fs(:long)
  end

  def show_all_versions_link?(rubygem)
    rubygem.versions_count > 5 || rubygem.yanked_versions?
  end

  def latest_version_number(rubygem)
    return rubygem.version if rubygem.respond_to?(:version)
    (rubygem.latest_version || rubygem.versions.last)&.number
  end

  def link_to_github(rubygem)
    candidates = [rubygem.links.source_code_uri, rubygem.links.homepage_uri].compact

    candidates.lazy.filter_map { |link| URI(link) }.find do |link_uri|
      link_uri.host == "github.com"
    end
  rescue URI::InvalidURIError
    nil
  end

  def github_params(rubygem)
    link = link_to_github(rubygem)
    return unless link

    {
      user: link.path.split("/").second,
      repo: link.path.split("/").third,
      type: "star",
      count: "true",
      size: "large"
    }
  end
end
