# frozen_string_literal: true

class DiscourseRedhive::Api::MeController < DiscourseRedhive::Api::BaseController
  def show
    user = current_user

    render json: {
      user_id: user.id,
      username: user.username,
      name: user.name,
      redhive_role: user.custom_fields[DiscourseRedhive::ROLE_FIELD],
      trust_level: user.trust_level,
      created_at: user.created_at.iso8601,
      post_count: user.post_count,
      topic_count: user.topic_count,
      avatar_url: user.avatar_template_url.gsub("{size}", "120"),
    }
  end
end
