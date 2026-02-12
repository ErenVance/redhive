# frozen_string_literal: true

RSpec.describe "DiscourseRedhive::Api::PostsController" do
  before { SiteSetting.redhive_enabled = true }

  fab!(:bot_user) { Fabricate(:user, trust_level: 1) }
  fab!(:topic)

  before do
    bot_user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
    bot_user.save_custom_fields
  end

  def bot_headers
    key = Fabricate(:api_key, user: bot_user, created_by: Discourse.system_user)
    { "Api-Key" => key.key, "Api-Username" => bot_user.username }
  end

  describe "POST /redhive/api/topics/:topic_id/posts" do
    it "creates a reply and returns 201" do
      post "/redhive/api/topics/#{topic.id}/posts.json",
           params: { content: "This is a reply to the topic." },
           headers: bot_headers

      expect(response.status).to eq(201)
      body = response.parsed_body
      expect(body["post_id"]).to be_present
      expect(body["topic_id"]).to eq(topic.id)
      expect(body["content"]).to eq("This is a reply to the topic.")
    end

    it "returns 400 when content is missing" do
      post "/redhive/api/topics/#{topic.id}/posts.json",
           params: {},
           headers: bot_headers

      expect(response.status).to eq(400)
    end

    it "returns 422 for non-existent topic" do
      post "/redhive/api/topics/999999/posts.json",
           params: { content: "Reply content here." },
           headers: bot_headers

      expect(response.status).to eq(422)
    end
  end

  describe "PUT /redhive/api/posts/:id" do
    fab!(:bot_post) { Fabricate(:post, topic: topic, user: bot_user) }

    it "updates own post" do
      put "/redhive/api/posts/#{bot_post.id}.json",
          params: { content: "Updated content for this post." },
          headers: bot_headers

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body["content"]).to eq("Updated content for this post.")
    end

    it "returns 400 when content is missing" do
      put "/redhive/api/posts/#{bot_post.id}.json",
          params: {},
          headers: bot_headers

      expect(response.status).to eq(400)
    end

    context "editing another user's post" do
      fab!(:other_user) { Fabricate(:user) }
      fab!(:other_post) { Fabricate(:post, topic: topic, user: other_user) }

      it "returns 403" do
        put "/redhive/api/posts/#{other_post.id}.json",
            params: { content: "Trying to edit someone else's post." },
            headers: bot_headers

        expect(response.status).to eq(403)
      end
    end
  end
end
