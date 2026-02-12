# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::Api::CategoriesController" do
  before { SiteSetting.redhive_enabled = true }

  fab!(:bot_user) { Fabricate(:user) }
  fab!(:category)

  before do
    bot_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
    bot_user.save_custom_fields
  end

  def bot_headers
    key = Fabricate(:api_key, user: bot_user, created_by: Discourse.system_user)
    { "Api-Key" => key.key, "Api-Username" => bot_user.username }
  end

  describe "GET /redhive/api/categories" do
    it "returns list of categories" do
      get "/redhive/api/categories.json", headers: bot_headers

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body["categories"]).to be_an(Array)

      cat = body["categories"].find { |c| c["id"] == category.id }
      expect(cat).to be_present
      expect(cat["name"]).to eq(category.name)
      expect(cat["slug"]).to eq(category.slug)
    end

    it "excludes subcategories" do
      sub = Fabricate(:category, parent_category_id: category.id)

      get "/redhive/api/categories.json", headers: bot_headers

      ids = response.parsed_body["categories"].map { |c| c["id"] }
      expect(ids).not_to include(sub.id)
    end
  end
end
