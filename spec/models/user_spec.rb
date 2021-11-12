# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  first_name                :string
#  last_name                 :string
#  email                     :string
#  password_digest           :string
#  remember_token            :string
#  admin                     :boolean          default(FALSE)
#  root                      :boolean          default(FALSE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  key                       :string
#  email_confirm             :boolean          default(TRUE)
#  skin                      :integer          default(0)
#  active                    :boolean          default(TRUE)
#  seename                   :integer          default(1)
#  sex                       :integer          default(0)
#  wepion                    :boolean          default(FALSE)
#  year                      :integer          default(0)
#  rating                    :integer          default(0)
#  forumseen                 :datetime         default(Thu, 01 Jan 2009 01:00:00 CET +01:00)
#  last_connexion            :date             default(Thu, 01 Jan 2009)
#  follow_message            :boolean          default(FALSE)
#  corrector                 :boolean          default(FALSE)
#  group                     :string           default("")
#  valid_name                :boolean          default(FALSE)
#  consent_date              :datetime
#  country_id                :integer
#  recup_password_date_limit :datetime
#  last_policy_read          :boolean          default(FALSE)
#  accept_analytics          :boolean          default(TRUE)
#
require "spec_helper"

describe User do

  before { @user = FactoryGirl.build(:user) }

  subject { @user }

  it { should respond_to(:first_name) }
  it { should respond_to(:last_name) }
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:admin) }
  it { should respond_to(:authenticate) }

  it { should be_valid }
  it { should_not be_admin }

  describe "when admin attribute is set to true" do
    before do
      @user.save!
      @user.toggle!(:admin)
    end

    it { should be_admin }
  end

  describe "when first_name is not present" do
    before { @user.first_name = " " }
    it { should_not be_valid }
  end
  describe "when last_name is not present" do
    before { @user.last_name = " " }
    it { should_not be_valid }
  end
  describe "when email is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end
  describe "when first_name is too long" do
    before { @user.first_name = "a" * 33 }
    it { should_not be_valid }
  end
  describe "when last_name is too long" do
    before { @user.last_name = "a" * 33 }
    it { should_not be_valid }
  end

  describe "when email format is invalid" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.foo@bar_baz.com foo@bar+baz.com]
      addresses.each do |invalid_address|
      	@user.email = invalid_address
      	@user.email_confirmation = invalid_address
      	expect(@user).not_to be_valid
      end
    end
  end

  describe "when email format is valid" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        @user.email_confirmation = valid_address
        expect(@user).to be_valid
      end
    end
  end
  describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = user_with_same_email.email.upcase
      user_with_same_email.email_confirmation = user_with_same_email.email
      user_with_same_email.save
    end

    it { should_not be_valid }
  end
  describe "when password is not present" do
    before { @user.password = @user.password_confirmation = " " }
    it { should_not be_valid }
  end
  describe "when password does not match confirmation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end
  describe "when password confirmation is nil" do
    before { @user.password_confirmation = nil }
    it { should_not be_valid }
  end
  describe "return value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by_email(@user.email) }

    describe "with valid password" do
      it { should == found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }
      it { should_not == user_for_invalid_password }
    end
  end
  describe "with a password that is too short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }
    it { should be_invalid }
  end
  describe "email address with mixed case" do
    let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

    it "should be saved as all lower-case" do
      @user.email = mixed_case_email
      @user.email_confirmation = mixed_case_email
      @user.save
      expect(@user.email).to eq(mixed_case_email.downcase)
    end
  end
end
