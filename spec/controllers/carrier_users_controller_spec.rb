require 'rails_helper'

RSpec.describe CarrierUsersController, type: :controller do

  before do
    sign_in
  end

  describe "new" do
    
    before do
      @user = FactoryGirl.build(:user)
      allow(User).to receive(:new).and_return(@user)
    end
    
    describe "success" do
      
      it "should assign new user" do
        expect(User).to receive(:new).and_return(@user)
      end
      
      after do
        get :new
        expect(response).to be_success
        expect(response.status).to be(200)
      end
      
    end
    
  end
  
  describe "create" do
    
    before do
     @user = FactoryGirl.build(:user)
     @params = { "name" => "abc", "email" => "abc@gmail.com" }
     allow(User).to receive(:create).and_return(@user) 
    end
    
    describe "success" do
      
      it "should create user with params" do
        expect(User).to receive(:create).and_return(@user)
      end
      
      after do
        post :create, { user: @params, format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end
      
    end
    
  end
  
  describe "update" do
    
    before do
      @user = FactoryGirl.build(:user)
      @params = { "name" => "abc", "email" => "abc@gmail.com" }
      allow(User).to receive(:find_by_id).with("2").and_return(@user)
      allow(@user).to receive(:update_attributes).and_return(true)  
    end
    
    describe "success" do
      
      it "should find user with id" do
        expect(User).to receive(:find_by_id).with("2").and_return(@user) 
      end
      
      it "should update attributes of user" do
        expect(@user).to receive(:update_attributes).and_return(true)   
      end
      
      after do
        put :update, { user: @params, id: "2", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end
      
    end
    
  end

end
