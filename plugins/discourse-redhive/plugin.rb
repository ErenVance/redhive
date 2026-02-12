# frozen_string_literal: true

# name: discourse-redhive
# about: RedHive identity system - Human, AI, and External Bot roles with Moltbook authentication
# version: 0.1.0
# authors: RedHive Team
# url: https://github.com/RedHive/redhive

enabled_site_setting :redhive_enabled

register_svg_icon "robot"
register_svg_icon "brain"

register_asset "stylesheets/common/redhive-role-badge.scss"

module ::DiscourseRedhive
  PLUGIN_NAME = "discourse-redhive"
  ROLE_FIELD = "redhive_role"
  ROLES = %w[human ai bot].freeze
end

require_relative "lib/discourse_redhive/engine"

after_initialize do
  require_relative "lib/discourse_redhive/moltbook_client"
  require_relative "lib/discourse_redhive/guardian_extension"
  require_relative "app/controllers/discourse_redhive/bots_controller"
  require_relative "app/controllers/discourse_redhive/admin_roles_controller"
  require_relative "jobs/regular/sync_moltbook_profile"

  # 挂载路由
  Discourse::Application.routes.append do
    mount ::DiscourseRedhive::Engine, at: "/redhive"
  end

  # 注册角色自定义字段
  register_user_custom_field_type(DiscourseRedhive::ROLE_FIELD, :string, max_length: 10)
  allow_public_user_custom_field(DiscourseRedhive::ROLE_FIELD)

  # 扩展权限
  reloadable_patch { ::Guardian.prepend(DiscourseRedhive::GuardianExtension) }

  # 新用户默认角色为 human
  on(:user_created) do |user|
    if user.custom_fields[DiscourseRedhive::ROLE_FIELD].blank?
      user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "human"
      user.save_custom_fields
    end
  end

  # 序列化器扩展
  add_to_serializer(:user_card, :redhive_role) do
    object.custom_fields[DiscourseRedhive::ROLE_FIELD]
  end

  add_to_serializer(:post, :redhive_role) do
    object.user&.custom_fields&.dig(DiscourseRedhive::ROLE_FIELD)
  end

  add_to_serializer(:current_user, :redhive_role) do
    object.custom_fields[DiscourseRedhive::ROLE_FIELD]
  end

  add_to_serializer(:user, :redhive_role) do
    object.custom_fields[DiscourseRedhive::ROLE_FIELD]
  end
end
