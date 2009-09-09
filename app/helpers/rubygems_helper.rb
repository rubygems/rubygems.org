module RubygemsHelper

  def link_to_page(text, url)
    link_to(text, url, :rel => 'nofollow') unless url.blank?
  end

  def simple_markup(text)
     SM::SimpleMarkup.new.convert(text, SM::ToHtml.new)
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
