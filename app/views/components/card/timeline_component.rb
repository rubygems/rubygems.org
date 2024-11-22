# frozen_string_literal: true

class Card::TimelineComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::TimeAgoInWords

  def view_template(&)
    div(class: "flex grow ml-2 border-l-2 border-neutral-300") do
      div(class: "flex flex-col grow -mt-2", &)
    end
  end

  def timeline_item(datetime, user_link = nil, &)
    # this block is shifted left to align the dots with the line
    div(class: "flex items-start -ml-2 mb-4") do
      # Dot
      div(class: "relative z-10 top-0.5 left-[1px] w-3 h-3 bg-orange-600 rounded-full flex-shrink-0 mt-1")

      # Content
      div(class: "flex-1 flex-col ml-5 md:ml-7 pb-4 border-b border-neutral-300 dark:border-neutral-700") do
        div(class: "flex items-center justify-between") do
          span(class: "text-b3 text-neutral-600") do
            helpers.local_time_ago(datetime, class: "text-b3 text-neutral-600")
          end
          span(class: "text-b3 text-neutral-800 dark:text-white max-h-6") { user_link } if user_link
        end

        div(class: "flex flex-wrap w-full items-center justify-between", &)
      end
    end
  end

  def link_to_user(user)
    link_to(profile_path(user.display_id), alt: user.display_handle, title: user.display_handle, class: "flex items-center") do
      span(class: "w-6 h-6 inline-block mr-2 rounded") { helpers.avatar(48, "gravatar-#{user.id}", user) }
      span { user.display_handle }
    end
  end

  def link_to_api_key(api_key_owner)
    case api_key_owner
    when OIDC::TrustedPublisher::GitHubAction
      div(class: "flex items-center") do
        span(class: "w-6 h-6 inline-block mr-2 rounded") do
          image_tag "github_icon.png", width: 48, height: 48, theme: :light, alt: "GitHub", title: api_key_owner.name
        end
        span { "GitHub Actions" }
      end
    else
      raise ArgumentError, "unknown api_key_owner type #{api_key_owner.class}"
    end
  end

  def link_to_pusher(version)
    if version.pusher.present?
      link_to_user(version.pusher)
    elsif version.pusher_api_key&.owner.present?
      link_to_api_key(version.pusher_api_key.owner)
    end
  end
end
