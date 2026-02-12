# frozen_string_literal: true

module Jobs
  class SyncMoltbookProfile < ::Jobs::Base
    def execute(args)
      user_id = args[:user_id]
      agent_data = args[:agent_data]

      return if user_id.blank? || agent_data.blank?

      user = User.find_by(id: user_id)
      return if user.nil?

      if (avatar_url = agent_data["avatar_url"]).present?
        begin
          UserAvatar.import_url_for_user(avatar_url, user)
        rescue StandardError => e
          Rails.logger.warn("Failed to sync Moltbook avatar for user #{user_id}: #{e.message}")
        end
      end

      if (description = agent_data["description"]).present? && user.user_profile
        user.user_profile.update(bio_raw: description)
      end
    end
  end
end
