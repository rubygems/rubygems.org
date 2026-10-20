# frozen_string_literal: true

# Name filtering is local for complete lists, server-side for paginated lists.
class GemListComponent < CardComponent
  register_output_helper :turbo_frame_tag

  prop :title
  prop :count
  prop :current
  prop :options
  prop :collection, default: nil

  def view_template
    super(data: { controller: "gem-filter" }) do
      head(class: "flex-wrap gap-3") do
        title(@title, icon: "gems", count: @count)
        if @count.positive?
          div(class: "gem-filter-controls flex flex-wrap items-center gap-3 w-full xl:w-auto") do
            @collection ? filter_form : filter_input
            div(data: { gem_filter_target: "sort" }) do
              render GemSortComponent.new(current: @current, options: @options)
            end
          end
        end
      end
      if @collection
        paginated_results { yield self }
      else
        if @count.positive?
          p(hidden: true, role: "status", class: "text-b3 text-neutral-600 dark:text-neutral-400 mb-4",
            data: { gem_filter_target: "status", all: t(".all", count: @count), matches: t(".matches", count: "%{count}", total: @count) })
          p(hidden: true, class: "text-b2 py-6", data: { gem_filter_target: "empty" }) { t(".no_results") }
        end
        yield self
      end
    end
  end

  private

  def paginated_results
    turbo_frame_tag("organization-gems", data: { turbo: true, turbo_action: "advance" }) do
      if @count.positive?
        p(role: "status", class: "text-b3 text-neutral-600 dark:text-neutral-400 mb-4") do
          if view_context.params[:gem_filter].to_s.match?(Patterns::GEM_NAME_FILTER_TERM)
            plain t(".matches", count: @collection.total_count, total: @count)
          else
            plain t(".all", count: @count)
          end
        end
        p(class: "text-b2 py-6") { t(".no_results") } if @collection.total_count.zero?
      end
      yield
      paginate @collection, theme: "hammy", params: { sort: @current }
    end
  end

  def filter_form
    request = view_context.request
    form(action: request.path, method: "get", class: "flex flex-wrap gap-2 w-full sm:w-auto",
         data: { turbo: "true", turbo_frame: "organization-gems", gem_filter_target: "form", action: "submit->gem-filter#submit" }) do
      query = request.query_parameters.except("page", "gem_filter").merge("sort" => @current)
      URI.decode_www_form(query.to_query).each { |name, value| input(type: "hidden", name:, value:) }
      filter_input
      button(type: "submit", class: DropdownComponent::BUTTON, data: { gem_filter_target: "submit" }) { t(".apply") }
    end
  end

  def filter_input
    div(hidden: !@collection, class: "w-full sm:w-[300px]", data: { gem_filter_target: "controls" }) do
      div(class: "relative") do
        div(class: "absolute left-3 inset-y-0 flex items-center pointer-events-none text-neutral-600", aria: { hidden: "true" }) do
          icon_tag("search", size: 5)
        end
        label do
          span(class: "sr-only") { t(".label") }
          input(type: "search", autocomplete: "off", aria: { label: t(".label") }, placeholder: t(".placeholder"),
                name: @collection ? "gem_filter" : nil, value: @collection ? view_context.params[:gem_filter] : nil,
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
