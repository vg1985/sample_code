require 'rails_helper'

RSpec.describe EgressTrunksController, type: :controller do
  
  before do
    sign_in
  end
  
  describe "index" do
    
    before do
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      allow(EgressTrunk).to receive(:all).and_return(@egress_trunks)
    end

    describe "success" do

      it "should assign all egress trunks" do
        expect(EgressTrunk).to receive(:all).and_return(@egress_trunks)
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
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      allow(EgressTrunk).to receive(:new).and_return(@egress_trunk)
    end

    describe "success" do

      it "should assign new parameters" do
        expect(EgressTrunk).to receive(:new).and_return(@egress_trunks)
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
       @egress_trunk = FactoryGirl.build(:egress_trunk)
      @params = {"name" => "abc", "carrier_id" => "1", "depth" => "2"}
      allow(EgressTrunk).to receive(:create).and_return(@egress_trunk)
    end

    describe "success" do

      it "should create new egress trunk" do
        expect(EgressTrunk).to receive(:create).and_return(@egress_trunk)
      end

      after do
        post :create, { egress_trunk: @params, format: :js }
        expect(response).to be_success
        expect(response).to render_template(:save)
      end

    end
    
 end
  
  describe 'edit' do
    
    before do
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      allow(EgressTrunk).to receive(:find_by_id).and_return(@egress_trunk)
    end
    
    describe "success" do
      
      it "should find egress trunk with id" do
        expect(EgressTrunk).to receive(:find_by_id).with("1").and_return(@egress_trunk)
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
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      @params = {"name" => "abc", "carrier_id" => "1", "depth" => "2" }
      allow(EgressTrunk).to receive(:find_by_id).and_return(@egress_trunk)
      allow(@egress_trunk).to receive(:update_attributes).and_return(true)
    end
    
    describe "success" do
      
      it "should find egress trunk with id" do
        expect(EgressTrunk).to receive(:find_by_id).with("1").and_return(@egress_trunk)
      end

      it "should update attributes of egress trunk" do
        expect(@egress_trunk).to receive(:update_attributes).and_return(true)
      end

      after do
        put :update, { egress_trunk: @params, id: "1", format: :js }
        expect(response).to be_success
        expect(response).to render_template(:save)
      end

    end
    
  end
  
  describe "activate" do
    
    before do
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      allow(EgressTrunk).to receive(:find_by_id).and_return(@egress_trunk)
      allow(@egress_trunk).to receive(:update_attribute).and_return(true)
    end
    
    describe "success" do
      
      it "should find egress trunk with id" do
        expect(EgressTrunk).to receive(:find_by_id).with("1").and_return(@egress_trunk)
      end
      
      it "should update attribute of egress trunk" do
        expect(@egress_trunk).to receive(:update_attribute).with(:is_active, true).and_return(true)
      end
      
      after do
        xhr :get, :activate, { egress_trunk: @params, id: "1"}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
    
  end
  
  describe "deactivate" do
    
    before do
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      allow(EgressTrunk).to receive(:find_by_id).and_return(@egress_trunk)
      allow(@egress_trunk).to receive(:update_attribute).and_return(true)
    end
    
    describe "success" do
      
      it "should find egress trunk with id" do
        expect(EgressTrunk).to receive(:find_by_id).with("1").and_return(@egress_trunk)
      end
      
      it "should update attribute of egress trunk" do
        expect(@egress_trunk).to receive(:update_attribute).with(:is_active, false).and_return(true)
      end
      
      after do
        xhr :get, :deactivate, { egress_trunk: @params, id: "1"}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
    
  end
  
  describe "update_status_for_selected" do
    
    before do
      @egress_trunk = FactoryGirl.create(:egress_trunk)
      @egress_trunks = EgressTrunk.all
      allow(EgressTrunk).to receive(:where).and_return(@egress_trunks)
      allow(@egress_trunks).to receive(:update_all).and_return(true)
    end
    
    describe "success" do
      
      it "should find egress trunks with id" do
        expect(EgressTrunk).to receive(:where).with(id: ["2"]).and_return(@egress_trunks)
      end
      
      it "should update status for egress trunks" do
        expect(@egress_trunks).to receive(:update_all).with(is_active: false).and_return(true)
      end
      
      after do
        xhr :post, :update_status_for_selected, { egress_trunk_ids: ["2"]}
        expect(response).to be_success
        expect(response).to render_template(:update_status)
      end
      
    end
     
  end
  
  describe "destroy" do
    
    before do
      @egress_trunk = FactoryGirl.build(:egress_trunk)
      allow(EgressTrunk).to receive(:find_by_id).and_return(@egress_trunk)
      allow(@egress_trunk).to receive(:destroy).and_return(true)
    end
    
    describe "success" do
      
      it "should find egress trunk with id" do
        expect(EgressTrunk).to receive(:find_by_id).with("1").and_return(@egress_trunk)
      end

      it "should update attributes of egress trunk" do
        expect(@egress_trunk).to receive(:destroy).and_return(true)
      end

      after do
        delete :destroy, { id: "1", format: :js }
        expect(response).to be_success
        expect(response.status).to be(200)
      end

    end
    
  end
  
end
