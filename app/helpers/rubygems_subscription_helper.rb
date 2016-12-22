module RubygemsSubscriptionHelper
  def subscribe_link(rubygem)
    if signed_in?
      style = if rubygem.subscribers.find_by_id(current_user.id)
                'display:none'
              else
                'display:inline-block'
              end
      link_to t('.links.subscribe'), rubygem_subscription_path(rubygem),
        class: ['toggler', 'gem__link', 't-list__item'], id: 'subscribe',
        method: :post, remote: true, style: style
    else
      link_to t('.links.subscribe'), sign_in_path,
        class: [:toggler, 'gem__link', 't-list__item'], id: :subscribe
    end
  end

  def unsubscribe_link(rubygem)
    return unless signed_in?
    style = if rubygem.subscribers.find_by_id(current_user.id)
              'display:inline-block'
            else
              'display:none'
            end
    link_to t('.links.unsubscribe'), rubygem_subscription_path(rubygem),
      class: [:toggler, 'gem__link', 't-list__item'], id: 'unsubscribe',
      method: :delete, remote: true, style: style
  end
end
