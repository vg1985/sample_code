require 'rails_helper'

describe User do

  context "validation" do
    it { should validate_presence_of(:name) }

    it "should validate format of email" do
      @user = FactoryGirl.build(:user, email: "Invalid")
      @user.valid?
      expect(@user.errors[:email]).not_to be_blank
    end

  end

  context "association" do 
    it { should belong_to(:role) }
    it { should have_one(:carrier) }
    it { should have_many(:admins_carriers) }
  end

  context "scope" do
    before do
      @admin = FactoryGirl.create(:user, role_id: Role.admin_id, email: "admin@mailinator.com")
    end

    it "should return admin users" do
     expect(User.admins).to include(@admin)
    end
  end

end
