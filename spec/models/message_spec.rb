# == Schema Information
#
# Table name: messages
#
#  id         :integer          not null, primary key
#  content    :text
#  subject_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#  erased     :boolean          default(FALSE)
#
require "spec_helper"

describe Message, message: true do
  let!(:user) { FactoryBot.create(:user) }
  let!(:message) { FactoryBot.build(:message, user: user) }

  subject { message }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { message.content = nil }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { message.content = "a" * 16001 }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { message.user_id = nil }
    it { should_not be_valid }
  end
  
  describe "when user is zero (automatic message)" do
    before { message.user_id = 0 }
    it { should be_valid }
  end
  
  # can_be_udpated_by
  describe "can_be_updated_by should work" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user) }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:root) { FactoryBot.create(:root) }
    let!(:message_user) { FactoryBot.create(:message, user: user) }
    let!(:message_user_erased) { FactoryBot.create(:message, user: user, erased: true) }
    let!(:message_admin) { FactoryBot.create(:message, user: admin) }
    let!(:message_root) { FactoryBot.create(:message, user: root) }
    let!(:message_auto) { FactoryBot.create(:message, user_id: 0) }
    
    specify do
      expect(message_user.can_be_updated_by(user)).to eq(true)
      expect(message_user.can_be_updated_by(user2)).to eq(false)
      expect(message_user.can_be_updated_by(admin)).to eq(true)
      expect(message_user.can_be_updated_by(root)).to eq(true)
      
      expect(message_user_erased.can_be_updated_by(user)).to eq(false)
      expect(message_user_erased.can_be_updated_by(user2)).to eq(false)
      expect(message_user_erased.can_be_updated_by(admin)).to eq(true)
      expect(message_user_erased.can_be_updated_by(root)).to eq(true)
      
      expect(message_admin.can_be_updated_by(user)).to eq(false)
      expect(message_admin.can_be_updated_by(admin)).to eq(true)
      expect(message_admin.can_be_updated_by(root)).to eq(true)
      
      expect(message_root.can_be_updated_by(user)).to eq(false)
      expect(message_root.can_be_updated_by(admin)).to eq(false)
      expect(message_root.can_be_updated_by(root)).to eq(true)
      
      expect(message_auto.can_be_updated_by(user)).to eq(false)
      expect(message_auto.can_be_updated_by(admin)).to eq(false)
      expect(message_auto.can_be_updated_by(root)).to eq(true)
    end
  end

end
