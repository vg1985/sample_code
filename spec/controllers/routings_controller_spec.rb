require 'rails_helper'

RSpec.describe RoutingsController, type: :controller do
  
  before do
    sign_in
  end
  
  describe "index" do
    
    before do
      @routing = FactoryGirl.build(:routing)
      allow(Routing).to receive(:all).and_return(@routing)
    end

    describe "success" do

      it "should assign all routings" do
        expect(Routing).to receive(:all).and_return(@routing)
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
      @routing = FactoryGirl.build(:routing)
      allow(Routing).to receive(:new).and_return(@routing)
    end

    describe "success" do

      it "should assign new parameters" do
        expect(Routing).to receive(:new).and_return(@routing)
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
        @routing = FactoryGirl.build(:routing)
       @params = {"name" => "test route"}
       allow(Routing).to receive(:create).and_return(@routing)
     end

     describe "success" do

       it "should create new routing" do
         expect(Routing).to receive(:create).and_return(@routing)
       end

       after do
         post :create, { routing: @params, format: :js }
         expect(response).to be_success
         expect(response.status).to be(200)
       end

     end
    
  end
  
  describe 'edit' do
    
    before do
      @routing = FactoryGirl.build(:routing)
      allow(Routing).to receive(:find_by_id).and_return(@routing)
    end
    
    describe "success" do
      
      it "should find egress trunk with id" do
        expect(Routing).to receive(:find_by_id).with("1").and_return(@routing)
      end
      
      after do
        get :edit, id: "1"
        expect(response).to be_success
        expect(response.status).to be(200)
      end
      
    end
    
  end
  
  describe "update" do
    
    before do
      @routing = FactoryGirl.build(:routing)
      @params = {"name" => "test route"}
      allow(Routing).to receive(:find_by_id).and_return(@routing)
      allow(@routing).to receive(:update_attributes).and_return(true)
    end
    
    describe "success" do
      
      it "should find routing with id" do
        expect(Routing).to receive(:find_by_id).with("1").and_return(@routing)
      end

      it "should update attributes of routing" do
        expect(@routing).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, { routing: @params, id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end
  
  describe "destroy" do
    
    before do
      @routing = FactoryGirl.build(:routing)
      allow(Routing).to receive(:find_by_id).and_return(@routing)
      allow(@routing).to receive(:destroy).and_return(true)
    end
    
    describe "success" do
      
      it "should find routing with id" do
        expect(Routing).to receive(:find_by_id).with("1").and_return(@routing)
      end

      it "should update attributes of routing" do
        expect(@routing).to receive(:destroy).and_return(true)
      end

      after do
        delete :destroy, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end

end
