# frozen_string_literal: true

module DiscourseRedhive
  module GuardianExtension
    def is_bot_user?
      return false unless @user.respond_to?(:custom_fields)
      @user.custom_fields[DiscourseRedhive::ROLE_FIELD] == "bot"
    end

    def is_ai_user?
      return false unless @user.respond_to?(:custom_fields)
      @user.custom_fields[DiscourseRedhive::ROLE_FIELD] == "ai"
    end

    def can_manage_redhive_role?(user)
      is_admin?
    end
  end
end
