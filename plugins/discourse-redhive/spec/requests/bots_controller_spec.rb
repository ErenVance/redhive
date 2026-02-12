# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::BotsController" do
  before { SiteSetting.redhive_enabled = true }

  describe "POST /redhive/bot/register" do
    context "with valid params" do
      it "creates a new bot user and returns API key" do
        expect {
          post "/redhive/bot/register.json", params: { name: "TestBot", description: "A test bot" }
        }.to change(User, :count).by(1).and change(ApiKey, :count).by(1)

        expect(response.status).to eq(201)
        body = response.parsed_body
        expect(body["user_id"]).to be_present
        expect(body["username"]).to start_with("bot-")
        expect(body["api_key"]).to be_present

        user = User.find(body["user_id"])
        expect(user.custom_fields[DiscourseRedhive::ROLE_FIELD]).to eq("bot")
        expect(user.active).to eq(true)
        expect(user.user_profile.bio_raw).to eq("A test bot")
      end

      it "does not create UserAssociatedAccount" do
        expect {
          post "/redhive/bot/register.json", params: { name: "TestBot" }
        }.not_to change(UserAssociatedAccount, :count)
      end

      it "returns existing user info when bot name is already registered" do
        post "/redhive/bot/register.json", params: { name: "TestBot" }
        expect(response.status).to eq(201)
        first_user_id = response.parsed_body["user_id"]

        post "/redhive/bot/register.json", params: { name: "TestBot" }
        expect(response.status).to eq(200)
        body = response.parsed_body
        expect(body["user_id"]).to eq(first_user_id)
        expect(body["message"]).to be_present
        expect(body).not_to have_key("api_key")
      end

      it "does not create duplicate users for same name" do
        post "/redhive/bot/register.json", params: { name: "TestBot" }
        expect {
          post "/redhive/bot/register.json", params: { name: "TestBot" }
        }.not_to change(User, :count)
      end

      it "sets bio when description is provided" do
        post "/redhive/bot/register.json", params: { name: "TestBot", description: "My bot bio" }
        user = User.find(response.parsed_body["user_id"])
        expect(user.user_profile.bio_raw).to eq("My bot bio")
      end

      it "works without description" do
        post "/redhive/bot/register.json", params: { name: "TestBot" }
        expect(response.status).to eq(201)
        expect(response.parsed_body["api_key"]).to be_present
      end

      it "creates API key with granular scopes" do
        post "/redhive/bot/register.json", params: { name: "TestBot" }
        user = User.find(response.parsed_body["user_id"])
        api_key = ApiKey.find_by(user: user)
        expect(api_key.scope_mode).to eq("granular")
        expect(api_key.api_key_scopes.count).to eq(7)
      end
    end

    context "with invalid params" do
      it "returns 400 when name is missing" do
        post "/redhive/bot/register.json", params: {}
        expect(response.status).to eq(400)
      end

      it "returns 422 when name is too short" do
        post "/redhive/bot/register.json", params: { name: "X" }
        expect(response.status).to eq(422)
      end

      it "returns 422 when name is too long" do
        post "/redhive/bot/register.json", params: { name: "A" * 61 }
        expect(response.status).to eq(422)
      end
    end

    context "when username is taken by non-bot user" do
      fab!(:human_user) { Fabricate(:user, username: "bot-testbot") }

      before do
        human_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "human"
        human_user.save_custom_fields
      end

      it "returns 409 conflict" do
        post "/redhive/bot/register.json", params: { name: "TestBot" }
        expect(response.status).to eq(409)
      end
    end

    context "when plugin is disabled" do
      before { SiteSetting.redhive_enabled = false }

      it "returns 404" do
        post "/redhive/bot/register.json", params: { name: "TestBot" }
        expect(response.status).to eq(404)
      end
    end
  end
end
