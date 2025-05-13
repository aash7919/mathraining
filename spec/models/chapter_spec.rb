# == Schema Information
#
# Table name: chapters
#
#  id                      :integer          not null, primary key
#  name                    :string
#  description             :text
#  level                   :integer
#  online                  :boolean          default(FALSE)
#  section_id              :integer
#  nb_tries                :integer          default(0)
#  nb_completions          :integer          default(0)
#  position                :integer          default(0)
#  author                  :string
#  publication_date        :date
#  submission_prerequisite :boolean          default(FALSE)
#
require "spec_helper"

describe Chapter, chapter: true do
  let!(:sec) { FactoryBot.build(:section) }
  let!(:chap) { FactoryBot.build(:chapter, section: sec) }

  subject { chap }

  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { chap.name = nil }
    it { should_not be_valid }
  end
  
  describe "when name is too long" do
    before { chap.name = "a" * 256 }
    it { should_not be_valid }
  end
  
  describe "when name is already taken" do
    before do
      FactoryBot.create(:chapter, section: sec, name: chap.name)
    end
    it { should_not be_valid }
  end

  # Description
  describe "when description is not present" do
    before { chap.description = nil }
    it { should be_valid }
  end
  
  describe "when description is too long" do
    before { chap.description = "a" * 16001 }
    it { should_not be_valid }
  end

  # Level
  describe "when level is 1" do
    before { chap.level = 1 }
    it { should be_valid }
  end
  
  describe "when level is 3" do
    before { chap.level = 3 }
    it { should be_valid }
  end
  
  describe "when level is not present" do
    before { chap.level = nil }
    it { should_not be_valid }
  end

  describe "when level is zero" do
    before { chap.level = 0 }
    it { should_not be_valid }
  end

  describe "when level is greater than 3" do
    before { chap.level = 4 }
    it { should_not be_valid }
  end

  # Prerequisites
  describe "when there are some prerequisites" do
    let!(:chap1) { FactoryBot.create(:chapter) }
    let!(:chap2) { FactoryBot.create(:chapter) }
    let!(:chap3) { FactoryBot.create(:chapter) }
    let!(:chap4) { FactoryBot.create(:chapter) }
    before do
      chap1.prerequisites << chap3
      chap.save
      chap.prerequisites << chap1
      chap1.prerequisites << chap2
      chap4.prerequisites << chap
      # chap4 < chap < chap1 < (chap2 & chap3)
    end
    describe "recursive_prerequisites should be correct" do
      specify do
        expect(chap.number_prerequisites).to eq(3)
        expect(chap.recursive_prerequisites).to include(chap1.id)
        expect(chap.recursive_prerequisites).to include(chap2.id)
        expect(chap.recursive_prerequisites).to include(chap3.id)
        expect(chap.recursive_prerequisites).not_to include(chap4.id)
      end
    end
  end
end
