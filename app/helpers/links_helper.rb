module LinksHelper
  def subscribe_link(rubygem)
    if signed_in?
      if rubygem.subscribers.find_by_id(current_user.id)
        link_to t(".links.unsubscribe"), rubygem_subscription_path(rubygem),
                class: [:toggler, "gem__link", "t-list__item"], id: "unsubscribe",
                method: :delete
      else
        link_to t(".links.subscribe"), rubygem_subscription_path(rubygem),
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

    link_to t(".links.unsubscribe"), rubygem_subscription_path(rubygem),
            class: [:toggler, "gem__link", "t-list__item", style], id: "unsubscribe",
            method: :delete, remote: true
  end

  def atom_link(rubygem)
    link_to t(".links.rss"), rubygem_versions_path(rubygem, format: "atom"),
            class: "gem__link t-list__item", id: :rss
  end

  def reverse_dependencies_link(rubygem)
    link_to_page :reverse_dependencies, rubygem_reverse_dependencies_path(rubygem)
  end

  def badge_link(rubygem)
    badge_url = "https://badge.fury.io/rb/#{rubygem.name}/install"
    link_to t(".links.badge"), badge_url, class: "gem__link t-list__item", id: :badge
  end

  def report_abuse_link(rubygem)
    encoded_title = CGI.escape("Reporting Abuse on #{rubygem.name}")
    report_abuse_url = "http://help.rubygems.org/discussion/new" \
      "?discussion[private]=1&discussion[title]=#{encoded_title}"
    link_to t(".links.report_abuse"), report_abuse_url.html_safe, class: "gem__link t-list__item"
  end
end
