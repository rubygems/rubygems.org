# frozen_string_literal: true

# A complete, unpaginated gem list with progressively enhanced name filtering.
class GemListComponent < CardComponent
  prop :title
  prop :count
  prop :current
  prop :options

  def view_template
    super(data: { controller: "gem-filter" }) do
      head(class: "flex-wrap gap-3") do
        title(@title, icon: "gems", count: @count)
        if @count.positive?
          div(class: "gem-filter-controls flex flex-wrap items-center gap-3 w-full xl:w-auto") do
            filter_input
            div(data: { gem_filter_target: "sort" }) do
              render GemSortComponent.new(current: @current, options: @options)
            end
          end
        end
      end
      if @count.positive?
        p(hidden: true, role: "status", class: "text-b3 text-neutral-600 dark:text-neutral-400 mb-4",
          data: { gem_filter_target: "status", all: t(".all", count: @count), matches: t(".matches", count: "%{count}", total: @count) })
        p(hidden: true, class: "text-b2 py-6", data: { gem_filter_target: "empty" }) { t(".no_results") }
      end
      yield self
    end
  end

  private

  def filter_input
    div(hidden: true, class: "w-full sm:w-[300px]", data: { gem_filter_target: "controls" }) do
      div(class: "relative") do
        div(class: "absolute left-3 inset-y-0 flex items-center pointer-events-none text-neutral-600", aria: { hidden: "true" }) do
          icon_tag("search", size: 5)
        end
        label do
          span(class: "sr-only") { t(".label") }
          input(type: "search", autocomplete: "off", aria: { label: t(".label") }, placeholder: t(".placeholder"),
                class: "w-full rounded border border-neutral-300 dark:border-neutral-700 bg-white dark:bg-black pl-10 pr-10 text-b3 " \
                       "focus:border-orange focus:ring-orange",
                data: { gem_filter_target: "input", action: "input->gem-filter#filter keydown.esc->gem-filter#clear" })
        end
        button(type: "button", hidden: true, aria: { label: t(".clear") },
               class: "absolute right-0 top-0 h-[38px] w-10 rounded text-neutral-600 dark:text-neutral-400 " \
                      "hover:text-orange focus-visible:outline-orange",
               data: { gem_filter_target: "clear", action: "gem-filter#clear" }) do
          plain "×"
        end
      end
    end
  end
end
