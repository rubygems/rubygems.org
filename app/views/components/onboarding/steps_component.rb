# frozen_string_literal: true

class Onboarding::StepsComponent < ApplicationComponent
  include Phlex::DeferredRender

  include Phlex::Rails::Helpers::LinkTo

  def initialize(current_step)
    @current_step = current_step
    @steps = []
    super()
  end

  def view_template(&)
    nav(class: "mb-10 flex items-start text-start text-neutral-800 dark:text-white") do
      @steps.each_with_index do |step, idx|
        step_item(idx + 1, *step)
        connector(idx + 1) unless idx == @steps.size - 1
      end
    end
  end

  def step(name, link)
    @steps << [name, link]
  end

  private

  STEP = "w-8 h-8 flex items-center justify-center rounded font-bold"
  ACTIVE_STEP = "#{STEP} bg-orange hover:bg-orange-600 text-white".freeze
  PENDING_STEP = "#{STEP} bg-neutral-300 dark:bg-neutral-700 text-neutral-700 dark:text-white".freeze

  def step_item(step, name, link)
    a(href: link, class: "relative z-10 w-20 flex flex-col items-center space-y-2 text-center text-b3") do
      span(class: @current_step >= step ? ACTIVE_STEP : PENDING_STEP, aria_current: "step") { step }
      p(class: "") { name }
    end
  end

  def connector(step)
    color = @current_step > step ? "border-orange-500" : "border-neutral-300 dark:border-neutral-700"
    span(class: "flex-grow mt-4 -mx-6 border-t-2 #{color}")
  end
end
