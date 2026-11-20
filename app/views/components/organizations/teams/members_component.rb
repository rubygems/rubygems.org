# frozen_string_literal: true

class Organizations::Teams::MembersComponent < ApplicationComponent
  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::L

  TH = "py-2 px-3 text-b4 font-semibold text-neutral-900 dark:text-white align-bottom"
  TD = "py-3 px-3 align-middle text-b3 text-neutral-800 dark:text-neutral-200"
  MUTED = "text-b4 text-neutral-600 dark:text-neutral-400"

  prop :team
  prop :team_memberships
  prop :addable_memberships
  prop :can_manage

  def view_template
    div(data: { testid: "team-members" }) do
      render CardComponent.new do |card|
        card.head { card.title t(".members"), icon: "organizations", count: @team_memberships.size }
        @team_memberships.empty? ? empty_state : member_table
      end

      add_members_form if @can_manage && @addable_memberships.any?
    end
  end

  private

  def organization = @team.organization

  def empty_state
    p(class: "text-b2 italic text-neutral-600 dark:text-neutral-400", data: { testid: "team-members-empty" }) { t(".no_members") }
  end

  def member_table
    div(class: "overflow-x-auto") do
      table(class: "w-full text-left border-collapse", data: { testid: "team-members-table" }) do
        thead do
          tr(class: "border-b-2 border-neutral-300 dark:border-neutral-700") do
            th(scope: "col", class: TH) { t(".handle") }
            th(scope: "col", class: TH) { t(".name") }
            th(scope: "col", class: TH) { t(".email") }
            th(scope: "col", class: "#{TH} text-nowrap") { t(".added") }
            th(scope: "col", class: TH) { span(class: "sr-only") { t(".actions") } } if @can_manage
          end
        end
        tbody { @team_memberships.each { |team_membership| member_row(team_membership) } }
      end
    end
  end

  def member_row(team_membership)
    user = team_membership.membership.user
    tr(class: "border-b border-neutral-200 dark:border-neutral-800", data: { testid: "team-member" }) do
      td(class: "#{TD} font-semibold text-neutral-900 dark:text-white", data: { testid: "team-member-handle" }) { user.handle }
      td(class: TD, data: { testid: "team-member-name" }) { user.full_name.to_s }
      td(class: "#{TD} break-all", data: { testid: "team-member-email" }) { user.public_email? ? user.email : "" }
      td(class: "#{TD} #{MUTED} text-nowrap", data: { testid: "team-member-added" }) do
        added_on = team_membership.created_at.to_date
        time_tag(added_on, l(added_on, format: :long))
      end
      td(class: "#{TD} text-right") { remove_button(team_membership.membership) } if @can_manage
    end
  end

  def remove_button(membership)
    render ButtonComponent.new(t(".remove"), organization_team_member_path(organization, @team, membership),
      method: :delete, style: :outline, color: :red, size: :small, data: { testid: "remove-team-member" })
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
      user_summary(membership.user)
    end
  end

  def user_summary(user)
    div(class: "flex flex-col") do
      p(class: "text-neutral-800 dark:text-white") do
        span(class: "font-semibold") { user.handle }
        span(class: "ml-2 text-neutral-600 dark:text-neutral-400") { user.full_name } if user.full_name.present?
      end
      p(class: "text-b3 text-neutral-600 dark:text-neutral-400") { user.email } if user.public_email?
    end
  end
end
