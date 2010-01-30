module RubygemsHelper

  def link_to_page(text, url)
    link_to(text, url, :rel => 'nofollow') unless url.blank?
  end

  def link_to_directory
    ("A".."Z").map { |letter| link_to(letter, rubygems_path(:letter => letter)) }.join
  end

  def simple_markup(text)
    if text =~ /^==+ [A-Z]/
      SM::SimpleMarkup.new.convert(text, SM::ToHtml.new)
    else
      content_tag :p, h(text)
    end
  end

  def clippy(text, bgcolor='#AADD44')
    html = <<-EOF
            <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
                    width="110"
                    height="32"
                    id="clippy" >
            <param name="movie" value="/clippy.swf"/>
            <param name="allowScriptAccess" value="always" />
            <param name="quality" value="high" />
            <param name="scale" value="noscale" />
            <param NAME="FlashVars" value="text=#{text}">
            <param name="wmode" value="transparent">
            <embed src="/clippy.swf"
                   width="110"
                   height="32"
                   name="clippy"
                   quality="high"
                   allowScriptAccess="always"
                   type="application/x-shockwave-flash"
                   pluginspage="http://www.macromedia.com/go/getflashplayer"
                   FlashVars="text=#{text}"
                   wmode="transparent"
            />
            </object>
          EOF
  end

  def subscribe_link(gem)
    if signed_in?
      subscribe = link_to_remote 'Subscribe',
        :url     => rubygem_subscription_path(gem),
        :method  => :post,
        :class   => :toggler,
        :html    => {
          :id    => 'subscribe',
          :class => :toggler,
          :style => gem.subscribers.find_by_id(current_user.try(:id)) ? 'display:none' : 'display:block'
        }
    else
      link_to 'Subscribe', sign_up_path, :id => :subscribe, :class => :toggler
    end
  end

  def unsubscribe_link(gem)
    link_to_remote('Unsubscribe',
      :url     => rubygem_subscription_path(gem),
      :method  => :delete,
      :class   => :toggler,
      :html    => {
        :id    => 'unsubscribe',
        :class => :toggler,
        :style => gem.subscribers.find_by_id(current_user.try(:id)) ? 'display:inline-block' : 'display:none'
      }) if signed_in?
  end
  
  def download_link(version)
    link_to "Download", "/downloads/#{version.full_name}.gem", :id => :download
  end
end
