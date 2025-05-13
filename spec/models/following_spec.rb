# == Schema Information
#
# Table name: followings
#
#  id                 :integer          not null, primary key
#  submission_id      :integer
#  user_id            :integer
#  read               :boolean
#  created_at         :datetime         not null
#  kind               :integer          default(NULL)
#  submission_user_id :integer
#
require "spec_helper"

describe Following, following: true do

  let!(:user) { FactoryBot.create(:user) }
  let!(:submission) { FactoryBot.create(:submission) }
  let!(:following) { FactoryBot.build(:following, user: user, submission: submission) }

  subject { following }

  it { should be_valid }

  # Uniqueness
  describe "when user and submission are already taken" do
    before { FactoryBot.create(:following, user: user, submission: submission) }
    it { should_not be_valid }
  end
  
  # Kind
  describe "when kind is not present" do
    before { following.kind = nil }
    it { should_not be_valid }
  end

end
