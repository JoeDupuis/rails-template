# frozen_string_literal: true

module NoticeI18n
  extend ActiveSupport::Concern

  def success_message model
    t(".success", default: :"application.#{action_name}.success", name: model.model_name.human)
  end
end
