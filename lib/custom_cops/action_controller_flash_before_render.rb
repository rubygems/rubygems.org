# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Using `flash` assignment before `render` will persist the message for too long.
      # Check https://guides.rubyonrails.org/action_controller_overview.html#flash-now
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
      class ActionControllerFlashBeforeRender < Base
        extend AutoCorrector

        MSG = 'Use `flash.now` before `render`.'

        def_node_search :flash_before_render?, <<~PATTERN
          ^(send (send nil? :flash) :[]= ...)
        PATTERN

        def_node_search :render?, <<~PATTERN
          (send nil? :render ...)
        PATTERN

        RESTRICT_ON_SEND = [:flash].freeze

        def on_send(node)
          expression = flash_before_render?(node)

          return unless expression

          context = node.parent.parent
          return unless context.descendants.any? { render?(_1) }

          add_offense(node) do |corrector|
            corrector.replace(node, 'flash.now')
          end
        end
      end
    end
  end
end
