# frozen_string_literal: true

class Organizations::Teams::MembersComponent < ApplicationComponent
  prop :team
  prop :members
  prop :addable_memberships
  prop :can_manage

  def view_template
    div(data: { testid: "team-members" }) do
      render CardComponent.new do |card|
        card.head { card.title t(".members"), icon: "organizations", count: @members.size }
        @members.empty? ? empty_state : member_list(card)
      end

      add_members_form if @can_manage && @addable_memberships.any?
    end
  end

  private

  def organization = @team.organization

  def empty_state
    p(class: "text-b2 italic text-neutral-600 dark:text-neutral-400", data: { testid: "team-members-empty" }) { t(".no_members") }
  end

  def member_list(card)
    card.divided_list do
      @members.each do |membership|
        card.list_item(data: { testid: "team-member" }) do
          div(class: "flex flex-row w-full items-center justify-between gap-4") do
            user_summary(membership.user, handle_testid: "team-member-handle")
            remove_button(membership) if @can_manage
          end
        end
      end
    end
  end

  def remove_button(membership)
    render ButtonComponent.new(t(".remove"), organization_team_member_path(organization, @team, membership),
      method: :delete, style: :plain, color: :red, size: :small, data: { testid: "remove-team-member" })
  end

  def add_members_form
    render CardComponent.new do |card|
      card.head { card.title t(".add_members") }
      form(action: organization_team_members_path(organization, @team), method: "post", data: { testid: "add-team-members" }) do
        input(type: "hidden", name: "authenticity_token", value: view_context.form_authenticity_token)
        div(class: "grid grid-cols-1 md:grid-cols-2 gap-4 mb-6") do
          @addable_memberships.each { |membership| member_option(membership) }
        end
        div(class: "flex justify-end") do
          render ButtonComponent.new(t(".add_selected"), type: :submit, size: :small, data: { testid: "add-team-members-submit" })
        end
      end
    end
  end

  def member_option(membership)
    label(class: "flex items-start gap-3 cursor-pointer", data: { testid: "add-member-option" }) do
      input(type: "checkbox", name: "membership_ids[]", value: membership.id, class: "mt-1 rounded border-neutral-300 dark:border-neutral-700")
      user_summary(membership.user, show_email: true)
    end
  end

  def user_summary(user, handle_testid: nil, show_email: false)
    div(class: "flex flex-col") do
      p(class: "text-neutral-800 dark:text-white") do
        span(class: "font-semibold", data: { testid: handle_testid }) { user.handle }
        span(class: "ml-2 text-neutral-600 dark:text-neutral-400") { user.full_name } if user.full_name.present?
      end
      p(class: "text-b3 text-neutral-600 dark:text-neutral-400") { user.email } if show_email && user.public_email?
    end
  end
end
