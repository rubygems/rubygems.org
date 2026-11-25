# frozen_string_literal: true

class FooterComponent < ApplicationComponent
  # We need the viewbox from the svg to scale accurately across screen sizes
  #   view_box must be "0 0 <width> <height>".
  Supporter = Data.define(:name, :url, :icon, :view_box) do
    def initialize(name:, url:, icon:, view_box:)
      raise ArgumentError, "#{name}: icon is required" if icon.blank?
      unless view_box.to_s.match?(/\A0 0 \d+(\.\d+)? \d+(\.\d+)?\z/)
        raise ArgumentError, "#{name}: view_box must be \"0 0 <width> <height>\", got #{view_box.inspect}"
      end

      super
    end

    def width = view_box.split[2]
    def height = view_box.split[3]
  end

  OPERATOR = Supporter.new("Ruby Central", "https://rubycentral.org/", "ruby-central-footer", "0 0 291 75")

  TIERS = {
    ruby_alliance: [
      Supporter.new("Gusto", "https://gusto.com/", "gusto-footer", "0 0 981.93 371.84"),
      Supporter.new("Sentry", "https://sentry.io/welcome/", "sentry-footer", "0 0 200 44"),
      Supporter.new("Shopify", "https://www.shopify.com/", "shopify-footer", "0 0 280 80"),
      Supporter.new("thoughtbot", "https://thoughtbot.com/", "thoughtbot-footer", "0 0 412 80"),
      Supporter.new("Rubyroid Labs", "https://rubyroidlabs.com/", "rubyroid-labs-footer", "0 0 211 38")
    ],
    rubygems_supporters: [
      Supporter.new("CloudAMQP", "https://www.cloudamqp.com/", "cloudamqp-footer", "0 0 326 80"),
      Supporter.new("Def Method", "https://www.defmethod.com/", "def-method-footer", "0 0 319 80"),
      Supporter.new("Kajabi", "https://www.kajabi.com/", "kajabi-footer", "0 0 341 80"),
      Supporter.new("NaCl", "https://www.netlab.jp/", "nacl-footer", "0 0 209 82"),
      Supporter.new("SerpApi", "https://serpapi.com/?utm_source=rubygems.org", "serpapi-footer", "0 0 189 80")
    ],
    infrastructure_donors: [
      Supporter.new("AWS", "https://aws.amazon.com/", "aws-footer", "0 0 135 80"),
      Supporter.new("Datadog", "https://www.datadoghq.com/", "datadog-footer", "0 0 799.7 196"),
      Supporter.new("Fastly", "https://www.fastly.com/", "fastly-footer", "0 0 207 80")
    ]
  }.freeze

  # Tiers that show a random subset of their supporters on each render, and how
  # many. Tiers not listed here show every supporter.
  ROTATING_TIERS = { rubygems_supporters: 3 }.freeze

  CONTAINER = "w-full max-w-screen-xl mx-auto"
  NAV_LINK_CLASS = "hover:text-neutral-600 dark:hover:text-neutral-400"
  LABEL_CLASS = "text-b4 uppercase tracking-widest font-semibold"
  DIVIDER_COLOR = "border-black/10 dark:border-white/15"
  LOGO_BOX = "flex items-center justify-center rounded px-3 border " \
             "border-black/10 bg-black/5 dark:border-white/10 dark:bg-black/20 " \
             "hover:bg-black/10 dark:hover:bg-black/30"

  # Use dependency injection for deterministic tests!
  def initialize(random: Random.new)
    super()
    @random = random
  end

  def view_template
    footer do
      nav_section
      supporters_section
    end
  end

  private

  def nav_section
    div(class: "px-6 md:px-8 py-6 bg-orange-100 dark:bg-orange-950 text-neutral-800 dark:text-neutral-200") do
      div(class: "#{CONTAINER} flex flex-col lg:flex-row lg:items-center gap-4 justify-between") do
        nav(class: "min-w-0") do
          ul(class: "flex flex-wrap gap-x-5 gap-y-2 text-b3 md:text-b2") do
            nav_link(t("layouts.application.footer.about"), page_path("about"))
            nav_link(t("layouts.application.footer.docs"), "https://guides.rubygems.org/command-reference/#gem-install")
            nav_link(t("layouts.application.footer.policies"), policies_path)
            nav_link(t("layouts.application.footer.status"), "https://status.rubygems.org")
            nav_link(t("layouts.application.footer.security"), page_path("security"))
            nav_link(t("pages.supporters.title"), supporters_path)
            nav_link(t("layouts.application.footer.help"), "mailto:support@rubygems.org")
          end
        end
        social_links
      end
    end
  end

  def nav_link(text, href)
    li { a(href:, class: NAV_LINK_CLASS) { text } }
  end

  def social_links
    div(class: "flex shrink-0 gap-4") do
      a(href: "https://github.com/rubygems/rubygems.org", aria: { label: t("layouts.application.footer.github") }) { icon_tag("github") }
      a(href: "https://ruby.social/users/rubygems", aria: { label: t("layouts.application.footer.mastodon") }) { icon_tag("mastodon") }
      a(href: "https://x.com/rubygems", aria: { label: t("layouts.application.footer.x") }) { icon_tag("x-twitter") }
      a(href: "https://bsky.app/profile/rubygems.bsky.social", aria: { label: t("layouts.application.footer.bluesky") }) { icon_tag("bluesky") }
    end
  end

  def supporters_section
    div(class: "px-6 md:px-8 py-8 bg-orange-200 dark:bg-orange-900 text-neutral-900 dark:text-neutral-100",
        data: { testid: "footer-supporters" }) do
      div(class: "#{CONTAINER} flex flex-col gap-6") do
        div(class: "flex flex-col lg:flex-row gap-6 lg:gap-0") do
          operated_by
          div(class: "flex-1 min-w-0 lg:pl-7") do
            div(class: "flex items-baseline justify-between mb-3") do
              tier_label(:ruby_alliance)
              see_all_link("hidden lg:inline")
            end
            logo_grid(supporters_for(:ruby_alliance), cols: "grid-cols-3 md:grid-cols-5", box: "h-16", logo: "h-9!")
          end
        end

        hr(class: DIVIDER_COLOR)

        div(class: "grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-0") do
          div(class: "md:pr-7") { tier(:rubygems_supporters) }
          hr(class: "md:hidden #{DIVIDER_COLOR}")
          div(class: "md:pl-7 md:border-l #{DIVIDER_COLOR}") { tier(:infrastructure_donors) }
        end

        see_all_link("lg:hidden")
      end
    end
  end

  def operated_by
    div(class: "flex items-center gap-4 lg:pr-7 lg:border-r #{DIVIDER_COLOR}", data: { testid: "footer-operator" }) do
      span(class: LABEL_CLASS) { t("layouts.application.footer.operated_by") }
      a(href: OPERATOR.url, aria: { label: OPERATOR.name }) { logo(OPERATOR, "h-10!") }
    end
  end

  def tier(key)
    div(class: "mb-3") { tier_label(key) }
    logo_grid(supporters_for(key), cols: "grid-cols-3", box: "h-14", logo: "h-8!")
  end

  def tier_label(key)
    h2(class: LABEL_CLASS) { t("layouts.application.footer.#{key}") }
  end

  def supporters_for(key)
    supporters = TIERS.fetch(key)
    count = ROTATING_TIERS[key]
    return supporters unless count

    supporters.sample(count, random: @random).sort_by { supporters.index(it) }
  end

  def logo_grid(supporters, cols:, box:, logo:)
    div(class: "grid #{cols} gap-2") do
      supporters.each do |supporter|
        a(href: supporter.url, class: "#{LOGO_BOX} #{box}", aria: { label: supporter.name }) do
          logo(supporter, logo)
        end
      end
    end
  end

  def see_all_link(visibility)
    a(href: supporters_path, class: "text-b4 font-semibold hover:underline #{visibility}") do
      plain t("layouts.application.footer.see_all_supporters")
      plain " →"
    end
  end

  # aspect-ratio is needed because icon_tag's square width/height attributes set the SVG in a square box
  #   causing wider svgs to shrink to unreadable sizes.
  # max-w-full lets wide svgs shrink inside narrow boxes on small screens and stay readable.
  def logo(supporter, height)
    icon_tag(supporter.icon, size: 8, class: "#{height} w-auto! max-w-full",
             viewBox: supporter.view_box,
             style: "aspect-ratio: #{supporter.width} / #{supporter.height}")
  end
end
