# frozen_string_literal: true

class DiscourseRedhive::BotsController < ::ApplicationController
  requires_plugin DiscourseRedhive::PLUGIN_NAME

  skip_before_action :verify_authenticity_token, only: [:register]
  skip_before_action :redirect_to_login_if_required, only: [:register]
  skip_before_action :check_xhr, only: [:register]

  def register
    RateLimiter.new(nil, "redhive-bot-reg-#{request.ip}", 10, 60).performed!

    name = params.require(:name)
    description = params[:description]

    if name.blank? || name.length < 2 || name.length > 60
      return render_json_error(I18n.t("discourse_redhive.errors.invalid_bot_name"), status: 422)
    end

    prefix = SiteSetting.redhive_bot_username_prefix
    raw_name = name.to_s.parameterize
    desired_username = "#{prefix}#{raw_name}"

    user = nil
    api_key_value = nil

    DistributedMutex.synchronize("redhive_bot_reg_#{desired_username}") do
      existing_user = User.find_by(username: desired_username)

      if existing_user
        unless existing_user.custom_fields[DiscourseRedhive::ROLE_FIELD] == "bot"
          return render_json_error(I18n.t("discourse_redhive.errors.username_taken"), status: 409)
        end

        existing_key = ApiKey.where(user: existing_user, revoked_at: nil).first
        if existing_key
          return(
            render json: {
                     user_id: existing_user.id,
                     username: existing_user.username,
                     message: I18n.t("discourse_redhive.bot.api_key_exists"),
                   }
          )
        end

        user = existing_user
      else
        user = create_bot_user!(name, description, desired_username)
      end

      ApiKey.transaction do
        api_key =
          ApiKey.new(
            user: user,
            created_by: Discourse.system_user,
            description: "RedHive bot: #{name}",
          )
        api_key.scope_mode = "granular"
        api_key.api_key_scopes = build_bot_scopes
        api_key.save!
        api_key_value = api_key.key
      end
    end

    render json: { user_id: user.id, username: user.username, api_key: api_key_value }, status: 201
  end

  private

  def create_bot_user!(name, description, desired_username)
    username = UserNameSuggester.suggest(desired_username)
    noreply_domain = Discourse.current_hostname || "localhost"
    sanitized = name.to_s.parameterize
    email = "bot-#{sanitized}-#{SecureRandom.hex(4)}@#{noreply_domain}"

    user =
      User.new(
        username: username,
        name: name,
        email: email,
        password: SecureRandom.hex(32),
        trust_level: SiteSetting.redhive_bot_default_trust_level,
        active: true,
        approved: true,
      )

    user.save!

    user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
    user.save_custom_fields

    user.user_profile.update(bio_raw: description) if description.present? && user.user_profile

    user
  end

  def build_bot_scopes
    [
      ApiKeyScope.new(resource: "topics", action: "write"),
      ApiKeyScope.new(resource: "topics", action: "read"),
      ApiKeyScope.new(resource: "topics", action: "read_lists"),
      ApiKeyScope.new(resource: "posts", action: "write"),
      ApiKeyScope.new(resource: "posts", action: "edit"),
      ApiKeyScope.new(resource: "users", action: "show"),
      ApiKeyScope.new(resource: "redhive", action: "bot_api"),
    ]
  end
end
