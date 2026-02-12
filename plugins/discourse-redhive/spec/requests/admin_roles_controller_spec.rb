# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::AdminRolesController" do
  before { SiteSetting.redhive_enabled = true }

  fab!(:admin)
  fab!(:user)

  describe "GET /redhive/admin/users/:user_id/role" do
    context "as admin" do
      before { sign_in(admin) }

      it "returns the user's role" do
        user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "ai"
        user.save_custom_fields

        get "/redhive/admin/users/#{user.id}/role.json"

        expect(response.status).to eq(200)
        body = response.parsed_body
        expect(body["redhive_role"]).to eq("ai")
        expect(body["username"]).to eq(user.username)
      end

      it "returns human as default when no role is set" do
        get "/redhive/admin/users/#{user.id}/role.json"

        expect(response.status).to eq(200)
        expect(response.parsed_body["redhive_role"]).to eq("human")
      end
    end

    context "as regular user" do
      before { sign_in(user) }

      it "is not accessible" do
        get "/redhive/admin/users/#{user.id}/role.json"
        expect(response.status).to eq(404)
      end
    end

    context "when not logged in" do
      it "is not accessible" do
        get "/redhive/admin/users/#{user.id}/role.json"
        expect(response.status).to eq(404)
      end
    end
  end

  describe "PUT /redhive/admin/users/:user_id/role" do
    context "as admin" do
      before { sign_in(admin) }

      it "updates user role to ai" do
        put "/redhive/admin/users/#{user.id}/role.json", params: { role: "ai" }

        expect(response.status).to eq(200)
        body = response.parsed_body
        expect(body["redhive_role"]).to eq("ai")

        user.reload
        expect(user.custom_fields[DiscourseRedhive::ROLE_FIELD]).to eq("ai")
      end

      it "updates user role to bot" do
        put "/redhive/admin/users/#{user.id}/role.json", params: { role: "bot" }

        expect(response.status).to eq(200)
        expect(response.parsed_body["redhive_role"]).to eq("bot")
      end

      it "updates user role to human" do
        user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "ai"
        user.save_custom_fields

        put "/redhive/admin/users/#{user.id}/role.json", params: { role: "human" }

        expect(response.status).to eq(200)
        expect(response.parsed_body["redhive_role"]).to eq("human")
      end

      it "rejects invalid role" do
        put "/redhive/admin/users/#{user.id}/role.json", params: { role: "superadmin" }
        expect(response.status).to eq(422)
      end

      it "logs the action" do
        put "/redhive/admin/users/#{user.id}/role.json", params: { role: "ai" }

        log = UserHistory.last
        expect(log.action).to eq(UserHistory.actions[:custom_staff])
        expect(log.custom_type).to eq("redhive_role_change")
      end
    end

    context "as regular user" do
      before { sign_in(user) }

      it "is not accessible" do
        put "/redhive/admin/users/#{user.id}/role.json", params: { role: "ai" }
        expect(response.status).to eq(404)
      end
    end
  end
end
