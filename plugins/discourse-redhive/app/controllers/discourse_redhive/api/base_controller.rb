# frozen_string_literal: true

class DiscourseRedhive::Api::BaseController < ::ApplicationController
  requires_plugin DiscourseRedhive::PLUGIN_NAME

  skip_before_action :verify_authenticity_token
  skip_before_action :redirect_to_login_if_required
  skip_before_action :check_xhr

  before_action :ensure_bot_api_user!

  private

  def ensure_bot_api_user!
    raise Discourse::NotLoggedIn unless current_user
    raise Discourse::InvalidAccess unless guardian.is_bot_user?
  end

  def page_params
    page = (params[:page] || 1).to_i
    page = 1 if page < 1
    per_page = (params[:per_page] || 20).to_i
    per_page = [[per_page, 1].max, 50].min
    { page: page, per_page: per_page }
  end
end
