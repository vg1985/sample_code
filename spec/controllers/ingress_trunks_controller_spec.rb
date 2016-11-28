require 'rails_helper'

RSpec.describe IngressTrunksController, type: :controller do
  
  before do
    sign_in
  end
  
  describe "index" do
    
    before do
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      allow(IngressTrunk).to receive(:all).and_return(@ingress_trunks)
    end

    describe "success" do

      it "should assign all ingress trunks" do
        expect(IngressTrunk).to receive(:all).and_return(@ingress_trunks)
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
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      allow(IngressTrunk).to receive(:new).and_return(@ingress_trunk)
    end

    describe "success" do

      it "should assign new parameters" do
        expect(IngressTrunk).to receive(:new).and_return(@ingress_trunks)
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
       @ingress_trunk = FactoryGirl.build(:ingress_trunk)
       @params = {"name" => "abc", "rate_sheet_id" => "1", "routing_id" => "1"}
       allow(IngressTrunk).to receive(:create).and_return(@ingress_trunk)
     end

     describe "success" do

       it "should create new ingress trunk" do
         expect(IngressTrunk).to receive(:create).and_return(@ingress_trunk)
       end

       after do
         post :create, { ingress_trunk: @params, format: :js }
         expect(response).to be_success
         expect(response).to render_template(:save)
       end

     end
    
  end
  
  describe 'edit' do
    
    before do
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      allow(IngressTrunk).to receive(:find_by_id).and_return(@ingress_trunk)
    end
    
    describe "success" do
      
      it "should find ingress trunk with id" do
        expect(IngressTrunk).to receive(:find_by_id).with("1").and_return(@ingress_trunk)
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
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      @params = {"name" => "abc", "rate_sheet_id" => "1", "routing_id" => "1"}
      allow(IngressTrunk).to receive(:find_by_id).and_return(@ingress_trunk)
      allow(@ingress_trunk).to receive(:update_attributes).and_return(true)
    end
    
    describe "success" do
      
      it "should find ingress trunk with id" do
        expect(IngressTrunk).to receive(:find_by_id).with("1").and_return(@ingress_trunk)
      end

      it "should update attributes of ingress trunk" do
        expect(@ingress_trunk).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, { ingress_trunk: @params, id: "1", format: :js }
        expect(response).to be_success
        expect(response).to render_template(:save)
      end

    end
    
  end
  
  describe "activate" do
    
    before do
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      allow(IngressTrunk).to receive(:find_by_id).and_return(@ingress_trunk)
      allow(@ingress_trunk).to receive(:update_attribute).and_return(true)
    end
    
    describe "success" do
      
      it "should find ingress trunk with id" do
        expect(IngressTrunk).to receive(:find_by_id).with("1").and_return(@ingress_trunk)
      end
      
      it "should update attribute of ingress trunk" do
        expect(@ingress_trunk).to receive(:update_attribute).with(:is_active, true).and_return(true)
      end
      
      after do
        xhr :get, :activate, { ingress_trunk: @params, id: "1"}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
    
  end
  
  describe "deactivate" do
    
    before do
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      allow(IngressTrunk).to receive(:find_by_id).and_return(@ingress_trunk)
      allow(@ingress_trunk).to receive(:update_attribute).and_return(true)
    end
    
    describe "success" do
      
      it "should find ingress trunk with id" do
        expect(IngressTrunk).to receive(:find_by_id).with("1").and_return(@ingress_trunk)
      end
      
      it "should update attribute of ingress trunk" do
        expect(@ingress_trunk).to receive(:update_attribute).with(:is_active, false).and_return(true)
      end
      
      after do
        xhr :get, :deactivate, { ingress_trunk: @params, id: "1"}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
    
  end
  
  describe "update_status_for_selected" do
    
    before do
      @ingress_trunk = FactoryGirl.create(:ingress_trunk)
      @ingress_trunks = IngressTrunk.all
      allow(IngressTrunk).to receive(:where).and_return(@ingress_trunks)
      allow(@ingress_trunks).to receive(:update_all).and_return(true)
    end
    
    describe "success" do
      
      it "should find ingress trunks with id" do
        expect(IngressTrunk).to receive(:where).with(id: ["2"]).and_return(@ingress_trunks)
      end
      
      it "should update status for ingress trunks" do
        expect(@ingress_trunks).to receive(:update_all).with(is_active: false).and_return(true)
      end
      
      after do
        xhr :post, :update_status_for_selected, { ingress_trunk_ids: ["2"]}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
     
  end
  
  describe "destroy" do
    
    before do
      @ingress_trunk = FactoryGirl.build(:ingress_trunk)
      allow(IngressTrunk).to receive(:find_by_id).and_return(@ingress_trunk)
      allow(@ingress_trunk).to receive(:destroy).and_return(true)
    end
    
    describe "success" do
      
      it "should find ingress trunk with id" do
        expect(IngressTrunk).to receive(:find_by_id).with("1").and_return(@ingress_trunk)
      end

      it "should update attributes of ingress trunk" do
        expect(@ingress_trunk).to receive(:destroy).and_return(true)
      end

      after do
        delete :destroy, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end
  
end
