# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::Api::TopicsController" do
  before { SiteSetting.redhive_enabled = true }

  fab!(:bot_user) { Fabricate(:user, trust_level: 1) }
  fab!(:category)

  before do
    bot_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
    bot_user.save_custom_fields
  end

  def bot_headers
    key = Fabricate(:api_key, user: bot_user, created_by: Discourse.system_user)
    { "Api-Key" => key.key, "Api-Username" => bot_user.username }
  end

  describe "POST /redhive/api/topics" do
    it "creates a topic and returns 201" do
      post "/redhive/api/topics.json",
           params: { title: "This is a test topic title", content: "Some content for the test topic." },
           headers: bot_headers

      expect(response.status).to eq(201)
      body = response.parsed_body
      expect(body["topic_id"]).to be_present
      expect(body["post_id"]).to be_present
      expect(body["title"]).to eq("This is a test topic title")
      expect(body["url"]).to be_present
    end

    it "creates a topic in a specific category" do
      post "/redhive/api/topics.json",
           params: { title: "Topic in a category here", content: "Content body text.", category: category.id },
           headers: bot_headers

      expect(response.status).to eq(201)
      topic = Topic.find(response.parsed_body["topic_id"])
      expect(topic.category_id).to eq(category.id)
    end

    it "returns 400 when title is missing" do
      post "/redhive/api/topics.json",
           params: { content: "Some content" },
           headers: bot_headers

      expect(response.status).to eq(400)
    end

    it "returns 400 when content is missing" do
      post "/redhive/api/topics.json",
           params: { title: "This is a valid title" },
           headers: bot_headers

      expect(response.status).to eq(400)
    end
  end

  describe "GET /redhive/api/topics" do
    fab!(:topic) { Fabricate(:topic, user: bot_user, category: category) }
    fab!(:post_record) { Fabricate(:post, topic: topic, user: bot_user) }

    it "returns list of topics" do
      get "/redhive/api/topics.json", headers: bot_headers

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body["topics"]).to be_an(Array)
      expect(body["meta"]["page"]).to eq(1)
    end

    it "supports pagination" do
      get "/redhive/api/topics.json", params: { page: 1, per_page: 5 }, headers: bot_headers

      expect(response.status).to eq(200)
      expect(response.parsed_body["meta"]["per_page"]).to eq(5)
    end
  end

  describe "GET /redhive/api/topics/:id" do
    fab!(:topic) { Fabricate(:topic, user: bot_user) }
    fab!(:post_record) { Fabricate(:post, topic: topic, user: bot_user) }

    it "returns topic with posts" do
      get "/redhive/api/topics/#{topic.id}.json", headers: bot_headers

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body["id"]).to eq(topic.id)
      expect(body["title"]).to eq(topic.title)
      expect(body["posts"]).to be_an(Array)
      expect(body["posts"].first["author"]).to eq(bot_user.username)
    end

    it "returns 404 for non-existent topic" do
      get "/redhive/api/topics/999999.json", headers: bot_headers
      expect(response.status).to eq(404)
    end
  end
end
