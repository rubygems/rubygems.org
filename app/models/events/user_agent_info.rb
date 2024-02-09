# frozen_string_literal: true

class Events::UserAgentInfo < ApplicationModel
  attribute :installer, :string
  attribute :device, :string
  attribute :os, :string
  attribute :user_agent, :string
  attribute :implementation, :string
  attribute :system, :string

  def to_s
    if installer == "Browser"
      browser_name
    elsif installer.present?
      installer_name
    else
      "Unknown user agent"
    end
  end

  private

  def browser_name
    return "Unknown browser" if user_agent == "Other"

    parenthetical_name(user_agent, [os, device])
  end

  def installer_name
    parenthetical_name(installer, [implementation, system])
  end

  def parenthetical_name(primary, parts)
    parenthetical = parts.reject { |part| part == "Other" }.compact_blank.join(" on ").presence
    if parenthetical
      "#{primary} (#{parenthetical})"
    else
      primary
    end
  end
end
