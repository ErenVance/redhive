# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::BotsController" do
  before do
    SiteSetting.redhive_enabled = true
    SiteSetting.redhive_moltbook_app_key = "moltdev_test_key"
    SiteSetting.redhive_moltbook_api_url = "https://api.moltbook.ai/api/v1"
  end

  let(:valid_agent_data) do
    {
      "agent_id" => "agent_123",
      "name" => "TestBot",
      "description" => "A helpful test bot",
      "avatar_url" => "https://moltbook.ai/avatars/agent_123.png",
      "karma" => 42,
    }
  end

  describe "POST /redhive/bot/authenticate" do
    context "with valid Moltbook token" do
      before do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 200,
          body: valid_agent_data.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )
      end

      it "creates a new bot user and returns API key" do
        expect { post "/redhive/bot/authenticate.json", params: { token: "valid_token" } }.to change(User, :count).by(1).and change(ApiKey, :count).by(1)

        expect(response.status).to eq(200)
        body = response.parsed_body
        expect(body["user_id"]).to be_present
        expect(body["username"]).to start_with("bot-")
        expect(body["api_key"]).to be_present

        user = User.find(body["user_id"])
        expect(user.custom_fields[DiscourseRedhive::ROLE_FIELD]).to eq("bot")
        expect(user.active).to eq(true)
      end

      it "creates a UserAssociatedAccount" do
        post "/redhive/bot/authenticate.json", params: { token: "valid_token" }

        association =
          UserAssociatedAccount.find_by(provider_name: "moltbook", provider_uid: "agent_123")
        expect(association).to be_present
        expect(association.info["name"]).to eq("TestBot")
      end

      it "returns existing user info when bot authenticates again" do
        post "/redhive/bot/authenticate.json", params: { token: "valid_token" }
        expect(response.status).to eq(200)
        first_user_id = response.parsed_body["user_id"]

        post "/redhive/bot/authenticate.json", params: { token: "valid_token" }
        expect(response.status).to eq(200)
        body = response.parsed_body
        expect(body["user_id"]).to eq(first_user_id)
        expect(body["message"]).to be_present
        expect(body).not_to have_key("api_key")
      end

      it "does not create duplicate users for same agent" do
        post "/redhive/bot/authenticate.json", params: { token: "valid_token" }
        expect { post "/redhive/bot/authenticate.json", params: { token: "valid_token" } }.not_to change(User, :count)
      end

      it "enqueues SyncMoltbookProfile job for new users" do
        expect { post "/redhive/bot/authenticate.json", params: { token: "valid_token" } }.to change(
          Jobs::SyncMoltbookProfile.jobs,
          :size,
        ).by(1)
      end
    end

    context "with invalid Moltbook token" do
      before do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 401,
          body: { error: "invalid" }.to_json,
        )
      end

      it "returns 401" do
        post "/redhive/bot/authenticate.json", params: { token: "bad_token" }
        expect(response.status).to eq(401)
      end
    end

    context "when Moltbook is unavailable" do
      before do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 500,
          body: "error",
        )
      end

      it "returns 503" do
        post "/redhive/bot/authenticate.json", params: { token: "token" }
        expect(response.status).to eq(503)
      end
    end

    context "when token param is missing" do
      it "returns 400" do
        post "/redhive/bot/authenticate.json", params: {}
        expect(response.status).to eq(400)
      end
    end

    context "when plugin is disabled" do
      before { SiteSetting.redhive_enabled = false }

      it "returns 404" do
        post "/redhive/bot/authenticate.json", params: { token: "token" }
        expect(response.status).to eq(404)
      end
    end

    context "when Moltbook agent is linked to a non-bot user" do
      fab!(:human_user) { Fabricate(:user) }

      before do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 200,
          body: valid_agent_data.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )

        UserAssociatedAccount.create!(
          provider_name: "moltbook",
          provider_uid: "agent_123",
          user: human_user,
          info: valid_agent_data,
          credentials: {},
          extra: {},
          last_used: Time.zone.now,
        )

        human_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "human"
        human_user.save_custom_fields
      end

      it "returns 409 conflict" do
        post "/redhive/bot/authenticate.json", params: { token: "valid_token" }
        expect(response.status).to eq(409)
      end
    end
  end
end
