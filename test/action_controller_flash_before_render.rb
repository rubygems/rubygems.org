# frozen_string_literal: true

# Using `flash` assignment before `render` will persist the message for too long.
# Check https://guides.rubyonrails.org/action_controller_overview.html#flash-now
#
# @safety
#   This cop's autocorrection is unsafe because it replaces `flash` by `flash.now`.
#   Even though it is usually a mistake, it might be used intentionally.
#
# @example
#   # bad
#   flash[:alert] = "Warning!"
#   render :index
#
#   # good
#   flash.now[:alert] = "Warning!"
#   render :index
#
class RuboCop::Cop::Rails::ActionControllerFlashBeforeRender < RuboCop::Cop::Cop
  extend RuboCop::Cop::AutoCorrector

  MSG = "Use `flash.now` before `render`."

  def_node_search :flash_assignment?, <<~PATTERN
    ^(send (send nil? :flash) :[]= ...)
  PATTERN

  def_node_search :render?, <<~PATTERN
    (send nil? :render ...)
  PATTERN

  RESTRICT_ON_SEND = [:flash].freeze

  def on_send(node)
    expression = flash_assignment?(node)
    return unless expression

    context = node.parent.parent
    return unless context

    siblings = context.descendants
    return unless siblings.any? { |sibling| render?(sibling) }

    add_offense(node) do |corrector|
      corrector.replace(node, "flash.now")
    end
  end
end
