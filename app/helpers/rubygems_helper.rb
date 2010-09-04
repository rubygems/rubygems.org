module RubygemsHelper

  def link_to_page(text, url)
    link_to(text, url, :rel => 'nofollow') if url.present?
  end

  def link_to_directory
    ("A".."Z").map { |letter| link_to(letter, rubygems_path(:letter => letter)) }.join
  end

  def simple_markup(text)
    if text =~ /^==+ [A-Z]/
      RDoc::Markup::ToHtml.new.convert(text)
    else
      content_tag :p, text
    end
  end

  def subscribe_link(rubygem)
    if signed_in?
      subscribe = link_to 'Subscribe', rubygem_subscription_path(rubygem),
        :remote => true,
        :method => :post,
        :id     => 'subscribe',
        :class  => 'toggler',
        :style  => rubygem.subscribers.find_by_id(current_user.try(:id)) ? 'display:none' : 'display:inline-block'
    else
      link_to 'Subscribe', sign_in_path, :id => :subscribe, :class => :toggler
    end
  end

  def unsubscribe_link(rubygem)
    if signed_in?
      link_to 'Unsubscribe', rubygem_subscription_path(rubygem),
        :remote  => true,
        :method  => :delete,
        :id    => 'unsubscribe',
        :class => :toggler,
        :style => rubygem.subscribers.find_by_id(current_user.try(:id)) ? 'display:inline-block' : 'display:none'
    end
  end

  def download_link(version)
    link_to "Download", "/downloads/#{version.full_name}.gem", :id => :download
  end

  def documentation_link(version, linkset)
    link_to 'Documentation', documentation_path(version), :id => :docs if linkset.docs.blank?
  end

  def documentation_path(version)
    "http://rubydoc.info/gems/#{version.rubygem.name}/#{version.number}/frames"
  end
end
