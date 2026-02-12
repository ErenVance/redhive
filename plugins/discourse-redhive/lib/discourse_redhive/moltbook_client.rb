# frozen_string_literal: true

module DiscourseRedhive
  class MoltbookClient
    class MoltbookError < StandardError
    end
    class MoltbookUnavailable < MoltbookError
    end
    class MoltbookInvalidToken < MoltbookError
    end

    TIMEOUT = 10

    def self.verify_identity(token)
      app_key = SiteSetting.redhive_moltbook_app_key
      raise MoltbookError, I18n.t("discourse_redhive.errors.moltbook_app_key_not_configured") if app_key.blank?

      api_url = SiteSetting.redhive_moltbook_api_url
      url = "#{api_url}/agents/verify-identity"

      response =
        Excon.post(
          url,
          body: { token: token }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-Moltbook-App-Key" => app_key,
          },
          connect_timeout: TIMEOUT,
          read_timeout: TIMEOUT,
          write_timeout: TIMEOUT,
        )

      case response.status
      when 200
        data = JSON.parse(response.body)
        validate_agent_data!(data)
        data
      when 401, 403
        raise MoltbookInvalidToken, I18n.t("discourse_redhive.errors.invalid_token")
      else
        Rails.logger.error(
          "Moltbook verify-identity returned #{response.status}: #{response.body}",
        )
        raise MoltbookUnavailable, I18n.t("discourse_redhive.errors.moltbook_unavailable")
      end
    rescue Excon::Error => e
      Rails.logger.error("Moltbook connection error: #{e.message}")
      raise MoltbookUnavailable, I18n.t("discourse_redhive.errors.moltbook_unavailable")
    end

    def self.validate_agent_data!(data)
      %w[agent_id name].each do |field|
        raise MoltbookError, "Missing required field: #{field}" if data[field].blank?
      end
    end
    private_class_method :validate_agent_data!
  end
end
