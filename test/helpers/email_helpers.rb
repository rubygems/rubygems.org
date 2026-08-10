# frozen_string_literal: true

module EmailHelpers
  BUTTON_WIDTH = "210"
  BUTTON_BACKGROUND_COLOR = "#e9573f"
  BUTTON_TEXT_COLOR = "#ffffff"

  def assert_cta_button(url, label)
    assert_select_email do
      assert_select "table[width=?] td[bgcolor=?] div.text-btn a[href=?]",
                    BUTTON_WIDTH, BUTTON_BACKGROUND_COLOR, url, count: 1, text: label do |links|
        assert_equal BUTTON_TEXT_COLOR, effective_style_property(links.sole, "color")
        assert_select "span", text: label do |spans|
          assert_equal BUTTON_TEXT_COLOR, effective_style_property(spans.sole, "color")
        end
      end
    end
  end

  # Roadie inlines the layout's `a { color:#e9573f }` rule ahead of the template's own color, so a delivered
  # link declares `color` more than once and the last declaration is the one that renders.
  def effective_style_property(element, property)
    declarations = Crass.parse_properties(element[:style])
    declaration = declarations.rfind { |node| node[:node] == :property && node[:name] == property }

    declaration && declaration[:value]
  end

  def last_email_link
    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob
    confirmation_link
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def mails_count
    ActionMailer::Base.deliveries.size
  end

  def confirmation_link
    refute_empty ActionMailer::Base.deliveries
    body = last_email.parts[1].body.decoded.to_s
    link = %r{http://localhost(?::\d+)?/email_confirmations([^";]*)}.match(body)
    link[0]
  end
end
