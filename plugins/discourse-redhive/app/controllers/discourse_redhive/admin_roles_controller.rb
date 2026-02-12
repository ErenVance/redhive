# frozen_string_literal: true

class DiscourseRedhive::AdminRolesController < ::ApplicationController
  requires_plugin DiscourseRedhive::PLUGIN_NAME
  before_action :ensure_admin

  def show
    user = User.find(params[:user_id])
    render json: {
             user_id: user.id,
             username: user.username,
             redhive_role: user.custom_fields[DiscourseRedhive::ROLE_FIELD] || "human",
           }
  end

  def update
    user = User.find(params[:user_id])
    role = params.require(:role)

    unless DiscourseRedhive::ROLES.include?(role)
      return(
        render_json_error(
          I18n.t(
            "discourse_redhive.errors.invalid_role",
            valid: DiscourseRedhive::ROLES.join(", "),
          ),
          status: 422,
        )
      )
    end

    user.custom_fields[DiscourseRedhive::ROLE_FIELD] = role
    user.save_custom_fields

    StaffActionLogger.new(current_user).log_custom(
      "redhive_role_change",
      { target_user_id: user.id, new_role: role },
    )

    render json: { user_id: user.id, username: user.username, redhive_role: role }
  end
end
