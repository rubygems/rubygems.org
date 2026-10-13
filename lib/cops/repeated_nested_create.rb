# frozen_string_literal: true

require "rubocop-factory_bot"

# FactoryBot/CreateList skips method-call arguments to preserve per-iteration
# evaluation. Report nested factories for review, but never autocorrect them:
# factory associations may make them redundant, or they may be intentional.
class RuboCop::Cop::FactoryBot::RepeatedNestedCreate < RuboCop::Cop::Base
  MSG = "Review nested factory creation: prefer create_list with factory associations when equivalent; " \
        "otherwise document why each iteration needs a fresh record."

  def_node_matcher :repeat_count, "(send (int $_) :times)"
  def_node_matcher :factory_create?, "(send {nil? (const {nil? cbase} :FactoryBot)} :create sym ...)"

  def on_block(node)
    count = repeat_count(node.send_node)
    return unless count && count > 1
    return unless factory_create?(node.body)
    return if uses_block_argument?(node)
    return unless node.body.arguments.any? { |argument| argument.each_node(:send).any? { |call| factory_create?(call) } }

    add_offense(node.send_node)
  end

  private

  def uses_block_argument?(node)
    names = node.argument_list.map(&:name)
    node.body.each_descendant(:lvar).any? { |variable| names.include?(variable.children.first) }
  end
end
