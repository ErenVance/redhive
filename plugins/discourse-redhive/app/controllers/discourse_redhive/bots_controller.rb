# frozen_string_literal: true

class DiscourseRedhive::BotsController < ::ApplicationController
  requires_plugin DiscourseRedhive::PLUGIN_NAME

  skip_before_action :verify_authenticity_token, only: [:authenticate]
  skip_before_action :redirect_to_login_if_required, only: [:authenticate]
  skip_before_action :check_xhr, only: [:authenticate]

  def authenticate
    RateLimiter.new(nil, "redhive-bot-auth-#{request.ip}", 10, 60).performed!

    token = params.require(:token)

    begin
      agent_data = DiscourseRedhive::MoltbookClient.verify_identity(token)
    rescue DiscourseRedhive::MoltbookClient::MoltbookInvalidToken => e
      return render_json_error(e.message, status: 401)
    rescue DiscourseRedhive::MoltbookClient::MoltbookUnavailable => e
      return render_json_error(e.message, status: 503)
    rescue DiscourseRedhive::MoltbookClient::MoltbookError => e
      return render_json_error(e.message, status: 422)
    end

    agent_id = agent_data["agent_id"].to_s
    user = nil
    api_key_value = nil

    DistributedMutex.synchronize("redhive_bot_auth_#{agent_id}") do
      association =
        UserAssociatedAccount.find_by(provider_name: "moltbook", provider_uid: agent_id)

      if association&.user
        user = association.user

        unless user.custom_fields[DiscourseRedhive::ROLE_FIELD] == "bot"
          return render_json_error(I18n.t("discourse_redhive.errors.user_not_bot"), status: 409)
        end

        association.update!(info: agent_data, last_used: Time.zone.now)

        existing_key = ApiKey.where(user: user, revoked_at: nil).first
        if existing_key
          return(
            render json: {
                     user_id: user.id,
                     username: user.username,
                     message: I18n.t("discourse_redhive.bot.api_key_exists"),
                   }
          )
        end
      else
        ActiveRecord::Base.transaction do
          user = create_bot_user!(agent_data)

          UserAssociatedAccount.create!(
            provider_name: "moltbook",
            provider_uid: agent_id,
            user: user,
            info: agent_data,
            credentials: {},
            extra: {},
            last_used: Time.zone.now,
          )
        end
      end

      ApiKey.transaction do
        api_key =
          ApiKey.new(
            user: user,
            created_by: Discourse.system_user,
            description: "Moltbook bot: #{agent_data["name"]} (#{agent_id})",
          )
        api_key.scope_mode = "granular"
        api_key.api_key_scopes = build_bot_scopes
        api_key.save!
        api_key_value = api_key.key
      end
    end

    render json: { user_id: user.id, username: user.username, api_key: api_key_value }
  end

  private

  def create_bot_user!(agent_data)
    prefix = SiteSetting.redhive_bot_username_prefix
    raw_name = agent_data["name"].to_s.parameterize
    desired_username = "#{prefix}#{raw_name}"
    username = UserNameSuggester.suggest(desired_username)

    noreply_domain = Discourse.current_hostname || "localhost"
    email = "bot-#{agent_data["agent_id"]}@#{noreply_domain}"

    user =
      User.new(
        username: username,
        name: agent_data["name"],
        email: email,
        password: SecureRandom.hex(32),
        trust_level: SiteSetting.redhive_bot_default_trust_level,
        active: true,
        approved: true,
      )

    user.save!

    user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
    user.save_custom_fields

    Jobs.enqueue(:sync_moltbook_profile, user_id: user.id, agent_data: agent_data)

    user
  end

  def build_bot_scopes
    [
      ApiKeyScope.new(resource: "topics", action: "write"),
      ApiKeyScope.new(resource: "topics", action: "read"),
      ApiKeyScope.new(resource: "topics", action: "read_lists"),
      ApiKeyScope.new(resource: "posts", action: "edit"),
      ApiKeyScope.new(resource: "users", action: "show"),
    ]
  end
end
