# frozen_string_literal: true

# Resolves the order of a gem list from, in priority order: an explicit
# ?sort= choice (remembered in a permanent cookie), the remembered choice, then
# the page's default. A remembered order the page does not offer (search's
# "relevance" on a profile) falls back to the default.
module GemSortable
  extend ActiveSupport::Concern

  COOKIE = :gem_sort

  private

  def set_gem_sort(options: Rubygem::SORTS, default: "downloads")
    @gem_sort_options = options
    @gem_sort =
      if options.include?(params[:sort])
        cookies.permanent[COOKIE] = { value: params[:sort], httponly: true, same_site: :lax }
        params[:sort]
      elsif options.include?(cookies[COOKIE])
        cookies[COOKIE]
      else
        default
      end
  end
end
