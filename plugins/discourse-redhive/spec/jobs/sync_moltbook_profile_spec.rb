# frozen_string_literal: true

RSpec.describe Jobs::SyncMoltbookProfile do
  fab!(:user)

  let(:agent_data_with_desc) do
    { "agent_id" => "agent_123", "name" => "TestBot", "description" => "A helpful test bot" }
  end

  let(:agent_data_with_avatar) do
    {
      "agent_id" => "agent_123",
      "name" => "TestBot",
      "avatar_url" => "https://moltbook.ai/avatars/agent_123.png",
    }
  end

  describe "#execute" do
    it "updates user bio from agent description" do
      described_class.new.execute(user_id: user.id, agent_data: agent_data_with_desc)

      user.user_profile.reload
      expect(user.user_profile.bio_raw).to eq("A helpful test bot")
    end

    it "attempts to import avatar when avatar_url is present" do
      UserAvatar.expects(:import_url_for_user).with("https://moltbook.ai/avatars/agent_123.png", user).once

      described_class.new.execute(user_id: user.id, agent_data: agent_data_with_avatar)
    end

    it "handles avatar import failure gracefully" do
      UserAvatar.expects(:import_url_for_user).raises(StandardError.new("download failed"))

      expect {
        described_class.new.execute(user_id: user.id, agent_data: agent_data_with_avatar)
      }.not_to raise_error
    end

    it "does nothing when user_id is blank" do
      expect {
        described_class.new.execute(user_id: nil, agent_data: agent_data_with_desc)
      }.not_to raise_error
    end

    it "does nothing when user does not exist" do
      expect {
        described_class.new.execute(user_id: -999, agent_data: agent_data_with_desc)
      }.not_to raise_error
    end

    it "does nothing when agent_data is blank" do
      expect {
        described_class.new.execute(user_id: user.id, agent_data: nil)
      }.not_to raise_error
    end

    it "handles missing description gracefully" do
      data = { "agent_id" => "123", "name" => "Bot" }
      expect { described_class.new.execute(user_id: user.id, agent_data: data) }.not_to raise_error
    end
  end
end
