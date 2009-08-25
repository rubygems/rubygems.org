module RubygemsHelper

  def link_to_page(text, url)
    link_to text, url unless url.blank?
  end

  def link_to_directory
    ("A".."Z").map { |letter| link_to(letter, rubygems_path(:letter => letter)) }.join
  end

  def subscribe_link(gem)
    subscribe = link_to_remote 'Subscribe',
      :url    => rubygem_subscription_path(gem),
      :method => :post,
      :class  => :toggler,
      :html   => {
        :class  => :toggler,
        :style  => gem.subscribers.find_by_id(current_user.try(:id)) ? 'display:none' : 'display:block'
      }
  end

  def unsubscribe_link(gem)
    unsubscribe = link_to_remote 'Unsubscribe',
      :url    => rubygem_subscription_path(gem),
      :method => :delete,
      :html   => {
        :class  => :toggler,
        :style  => gem.subscribers.find_by_id(current_user.try(:id)) ? 'display:block' : 'display:none'
      }
  end
end
