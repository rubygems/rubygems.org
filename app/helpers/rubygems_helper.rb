module RubygemsHelper

  def link_to_page(text, url)
    link_to text, url unless url.blank?
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
            <param name="bgcolor" value="#{bgcolor}">
            <embed src="/clippy.swf"
                   width="110"
                   height="32"
                   name="clippy"
                   quality="high"
                   allowScriptAccess="always"
                   type="application/x-shockwave-flash"
                   pluginspage="http://www.macromedia.com/go/getflashplayer"
                   FlashVars="text=#{text}"
                   bgcolor="#{bgcolor}"
            />
            </object>
          EOF
  end
end
