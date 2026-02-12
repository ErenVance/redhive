# frozen_string_literal: true

RSpec.describe DiscourseRedhive::MoltbookClient do
  before { SiteSetting.redhive_enabled = true }

  let(:valid_agent_data) { { "agent_id" => "agent_123", "name" => "TestBot", "description" => "A test bot" } }

  describe ".verify_identity" do
    context "when app key is not configured" do
      before { SiteSetting.redhive_moltbook_app_key = "" }

      it "raises MoltbookError" do
        expect { described_class.verify_identity("some_token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookError,
        )
      end
    end

    context "when app key is configured" do
      before do
        SiteSetting.redhive_moltbook_app_key = "moltdev_test_key"
        SiteSetting.redhive_moltbook_api_url = "https://api.moltbook.ai/api/v1"
      end

      it "returns agent data on successful verification" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 200,
          body: valid_agent_data.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )

        result = described_class.verify_identity("valid_token")
        expect(result["agent_id"]).to eq("agent_123")
        expect(result["name"]).to eq("TestBot")
      end

      it "raises MoltbookInvalidToken on 401" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 401,
          body: { error: "invalid token" }.to_json,
        )

        expect { described_class.verify_identity("bad_token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookInvalidToken,
        )
      end

      it "raises MoltbookInvalidToken on 403" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 403,
          body: { error: "forbidden" }.to_json,
        )

        expect { described_class.verify_identity("forbidden_token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookInvalidToken,
        )
      end

      it "raises MoltbookUnavailable on 500" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 500,
          body: "Internal Server Error",
        )

        expect { described_class.verify_identity("token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookUnavailable,
        )
      end

      it "raises MoltbookUnavailable on connection error" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_timeout

        expect { described_class.verify_identity("token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookUnavailable,
        )
      end

      it "raises MoltbookError when agent_id is missing" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 200,
          body: { "name" => "Bot" }.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )

        expect { described_class.verify_identity("token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookError,
          /agent_id/,
        )
      end

      it "raises MoltbookError when name is missing" do
        stub_request(:post, "https://api.moltbook.ai/api/v1/agents/verify-identity").to_return(
          status: 200,
          body: { "agent_id" => "123" }.to_json,
          headers: {
            "Content-Type" => "application/json",
          },
        )

        expect { described_class.verify_identity("token") }.to raise_error(
          DiscourseRedhive::MoltbookClient::MoltbookError,
          /name/,
        )
      end
    end
  end
end
