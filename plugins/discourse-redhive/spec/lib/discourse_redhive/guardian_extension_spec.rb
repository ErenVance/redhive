# frozen_string_literal: true

RSpec.describe DiscourseRedhive::GuardianExtension do
  before { SiteSetting.redhive_enabled = true }

  fab!(:user)
  fab!(:admin)

  describe "#is_bot_user?" do
    it "returns true for bot users" do
      user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
      user.save_custom_fields

      expect(Guardian.new(user).is_bot_user?).to eq(true)
    end

    it "returns false for human users" do
      user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "human"
      user.save_custom_fields

      expect(Guardian.new(user).is_bot_user?).to eq(false)
    end

    it "returns false for ai users" do
      user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "ai"
      user.save_custom_fields

      expect(Guardian.new(user).is_bot_user?).to eq(false)
    end

    it "returns false for nil user" do
      expect(Guardian.new(nil).is_bot_user?).to eq(false)
    end
  end

  describe "#is_ai_user?" do
    it "returns true for ai users" do
      user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "ai"
      user.save_custom_fields

      expect(Guardian.new(user).is_ai_user?).to eq(true)
    end

    it "returns false for bot users" do
      user.custom_fields[DiscourseRedhive::ROLE_FIELD] = "bot"
      user.save_custom_fields

      expect(Guardian.new(user).is_ai_user?).to eq(false)
    end
  end

  describe "#can_manage_redhive_role?" do
    it "returns true for admins" do
      expect(Guardian.new(admin).can_manage_redhive_role?(user)).to eq(true)
    end

    it "returns false for regular users" do
      expect(Guardian.new(user).can_manage_redhive_role?(user)).to eq(false)
    end
  end
end
