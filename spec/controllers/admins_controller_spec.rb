require 'rails_helper'

RSpec.describe AdminsController, type: :controller do
  
  before do
   sign_in
   FactoryGirl.create(:role, name: 'Admin')
   @admins = User.admins
   allow(User).to receive(:admins).and_return(@admins)
  end

  describe "index" do
    
    before do
      @user = FactoryGirl.build(:user)
    end
    
    describe "success" do
      
      it "should return all admin users" do
        expect(User).to receive(:admins).and_return(@admins)
        expect(@admins).to receive(:all).and_return(@user)
      end

      after do
        get :index
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end 
    
  end
  
  describe "new" do
    
    before do
      @user = FactoryGirl.build(:user)
    end
    
    describe "success" do
      
      it "should initialize user object" do
        expect(User).to receive(:admins).and_return(@admins)
        expect(@admins).to receive(:new).and_return(@user)
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
      @params = {"name" => "abc", "email" => "abc@gmail.com", "password" => "abc123"}
    end
    
    describe "success" do
      
      it "should initialize user object" do
        expect(User).to receive(:admins).and_return(@admins)
        expect(@admins).to receive(:create).and_return(@user)
      end

      after do
        post :create, { user: @params, format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end
  
  describe "edit" do
    
    before do
      @user = FactoryGirl.create(:user, role_id: Role.admin_id)
    end
    
    describe "success" do
      
      it "should find user with id" do
        expect(User).to receive(:admins).and_return(@admins)
        expect(@admins).to receive(:find_by_id).with(@user.id.to_s).and_return(@user)
      end

      after do
        get :edit, id: "#{@user.id}"
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end
  
  describe "update" do
    
    before do
      @user = FactoryGirl.create(:user, role_id: Role.admin_id)
      @params = {"name" => "abc", "email" => "abc@gmail.com", "password" => "abc123"}
    end
    
    describe "success" do
      
      it "should find user with id and update attributes" do
        expect(User).to receive(:admins).and_return(@admins)
        expect(@admins).to receive(:find_by_id).with(@user.id.to_s).and_return(@user)
        expect(@user).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, user: @params, id: @user.id.to_s, format: :js
        expect(response).to be_success
        expect(response).to render_template(:save)
      end

    end

  end
  
  describe "destroy" do
    
    before do
      @user = FactoryGirl.create(:user, role_id: Role.admin_id)
      @params = {"name" => "abc", "email" => "abc@gmail.com", "password" => "abc123"}
    end
    
    describe "success" do
      
      it "should find user with id and delete the user" do
        expect(User).to receive(:admins).and_return(@admins)
        expect(@admins).to receive(:find_by_id).with(@user.id.to_s).and_return(@user)
        expect(@user).to receive(:destroy).and_return(true)
      end

      after do
        delete :destroy, { id: @user.id.to_s, format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end

  end

end
