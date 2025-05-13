# == Schema Information
#
# Table name: savedreplies
#
#  id         :bigint           not null, primary key
#  problem_id :bigint
#  content    :text
#  nb_uses    :integer          default(0)
#  section_id :bigint
#  approved   :boolean
#  user_id    :bigint
#
require "spec_helper"

describe Savedreply, savedreply: true do

  let!(:savedreply) { FactoryBot.build(:savedreply) }

  subject { savedreply }

  it { should be_valid }
  
  # Section
  describe "when section_id is not present" do
    before { savedreply.section_id = nil }
    it { should_not be_valid }
  end
  
  # Problem
  describe "when problem_id is not present" do
    before { savedreply.problem_id = nil }
    it { should_not be_valid }
  end

  # Content
  describe "when content is not present" do
    before { savedreply.content = nil }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { savedreply.content = "A" * 16001 }
    it { should_not be_valid }
  end
  
  # Number of uses
  describe "when nb_uses is not present" do
    before { savedreply.nb_uses = nil }
    it { should_not be_valid }
  end
  describe "when nb_uses is negative" do
    before { savedreply.nb_uses = -1 }
    it { should_not be_valid }
  end
end
