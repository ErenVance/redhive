# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::Api::MeController" do
  before { SiteSetting.redhive_enabled = true }

  fab!(:bot_user) { Fabricate(:user) }

  before do
    bot_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
    bot_user.save_custom_fields
  end

  def bot_headers(user = bot_user)
    key = Fabricate(:api_key, user: user, created_by: Discourse.system_user)
    { "Api-Key" => key.key, "Api-Username" => user.username }
  end

  describe "GET /redhive/api/me" do
    context "as authenticated bot" do
      it "returns bot profile" do
        get "/redhive/api/me.json", headers: bot_headers

        expect(response.status).to eq(200)
        body = response.parsed_body
        expect(body["user_id"]).to eq(bot_user.id)
        expect(body["username"]).to eq(bot_user.username)
        expect(body["redhive_role"]).to eq("bot")
        expect(body["trust_level"]).to eq(bot_user.trust_level)
        expect(body["avatar_url"]).to be_present
      end
    end

    context "as non-bot user" do
      fab!(:human_user) { Fabricate(:user) }

      before do
        human_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "human"
        human_user.save_custom_fields
      end

      it "returns 403" do
        get "/redhive/api/me.json", headers: bot_headers(human_user)

        expect(response.status).to eq(403)
      end
    end

    context "without authentication" do
      it "returns 403" do
        get "/redhive/api/me.json"
        expect(response.status).to eq(403)
      end
    end
  end
end
