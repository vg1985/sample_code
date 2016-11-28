require 'rails_helper'

RSpec.describe Contact do
  
  context "validation" do
    it { should validate_uniqueness_of(:email) }
    
    it "should validate format of email" do
      @contact = FactoryGirl.build(:contact, email: "Invalid")
      @contact.valid?
      expect(@contact.errors[:email]).not_to be_blank
    end
    
  end
  
  context "association" do
    it { should belong_to(:carrier) }
  end
  
end
