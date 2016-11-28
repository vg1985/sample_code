class InboundDidsGroupsController < ApplicationController

  after_action :verify_authorized

	def index
    authorize :inbound_dids_groups, :index?

	  @did_groups = carrier.did_groups.order('id')
	  @grouped_dids = carrier.grouped_dids
	end

	def create
    authorize :inbound_dids_groups, :create?

    @did_group = carrier.did_groups.create(did_group_params)

    respond_to do |format|
    	format.js
    end
  end

  def edit
    authorize :inbound_dids_groups, :edit?

  	did_group = carrier.did_groups.find_by(id: params[:id])

  	respond_to do |format|
  		format.html {
  			if did_group.present? && did_group.name != DidGroup::UNGROUPED_NAME
  				render :partial => 'form', :locals => {:group => did_group}
  			else
  				render :text => "Invalid request"
  			end
  		}
  	end
  end

  def update
    authorize :inbound_dids_groups, :update?

  	@did_group = carrier.did_groups.find_by(id: params[:id])

  	if @did_group.present? && @did_group.name != DidGroup::UNGROUPED_NAME
  		@done = @did_group.update_attributes(did_group_params)
  	end

  	respond_to do |format|
  		format.js
  	end
  end

  def destroy
    authorize :inbound_dids_groups, :destroy?

  	did_group = carrier.did_groups.find_by(id: params[:id])
  	@group_id = nil

  	if did_group.present? && did_group.name != DidGroup::UNGROUPED_NAME && did_group.dids.empty?
  		@group_id = did_group.id
  		did_group.destroy
  	end

  	respond_to do |format|
  		format.js
  	end
  end

  def update_did_desc
    unless request.xhr?
      redirect_to manage_inbound_dids_url and return  
    end

    authorize :inbound_dids_groups, :update_did_desc?

    if current_user.is_admin?
      did = Did.active.find_by(id: params[:pk].to_i)
    elsif current_user.is_carrier?
      did = carrier.dids.active.find_by(id: params[:pk].to_i)
    end

    if params[:pk].blank? || did.blank?
      format.js { render "shared/not_found" }          
    end

    did.update_attribute(:description, params[:value]) if params[:value].present?

    render nothing: true
  end

  def update_didgrp_desc
    unless request.xhr?
      redirect_to manage_inbound_dids_url and return  
    end

    authorize :inbound_dids_groups, :update_didgrp_desc?

    didgrp = carrier.did_groups.find_by(id: params[:pk].to_i)

    if params[:pk].blank? || didgrp.blank?
      format.js { render "shared/not_found" }          
    end

    didgrp.update_attribute(:description, params[:value]) if params[:value].present?

    render nothing: true
  end

  def move_to
    authorize :inbound_dids_groups, :move_to?

  	if params[:move_to].blank? || params[:move_to].to_i < 0 || !carrier.did_groups.exists?(id: params[:move_to].to_i) || 
  		params[:dids].blank? || !params[:dids].is_a?(Array) ||  (params[:dids].reject!(&:empty?) && carrier.dids.active.where(id: params[:dids]).count != params[:dids].size)

  		flash[:error] = 'Your request cannot be processed due to invalid request parameters.'
  		redirect_to :inbound_dids_groups and return
  	end

  	carrier.dids.where(id: params[:dids]).update_all(did_group_id: params[:move_to])

  	respond_to do |format|
  		format.html {  
  			flash[:notice] = 'DIDs have been moved successfully.'
  			redirect_to request.referrer || inbound_dids_groups_url
			}
  	end
  end


  def release
    authorize :inbound_dids_groups, :release?

    if params[:dids].blank? || params[:release_reason].blank?
      respond_to do |format|
        format.html {  
          flash[:error] = "Your request cannot be processed due to invalid request parameters."
          redirect_to (request.referrer || root_path) and return
        }
      end
    end

    #remove empty elements
    params[:dids].reject!(&:empty?)

    if current_user.is_admin?
      local_dids = Did.active.where(["transaction_type = 'local' AND dids.id IN (?)", params[:dids]]).select('did')
      tf_dids = Did.active.where(["transaction_type = 'toll_free' AND dids.id IN (?)", params[:dids]]).select('did')
    elsif current_user.is_carrier?
      local_dids = carrier.dids.active.where(["transaction_type = 'local' AND dids.id IN (?)", params[:dids]]).select('did')
      tf_dids = carrier.dids.active.where(["transaction_type = 'toll_free' AND dids.id IN (?)", params[:dids]]).select('did')
    end
    
    if local_dids.present?
      #Order.release(current_user, 'local', local_dids.collect(&:did), params[:release_reason])
    end
    
    if tf_dids.present?
      #Order.release(current_user, 'toll_free', tf_dids.collect(&:did), params[:release_reason])
    end

    respond_to do |format|
      format.html { 
        flash[:notice] = "Your request to release DID(s) is in process. You can check the status after sometime."
          redirect_to (request.referrer || root_path) and return
      }
    end
  end

  def remove_dids
    authorize :inbound_dids_groups, :remove_dids?

    if params[:dids].blank?
      respond_to do |format|
        format.html {  
          flash[:error] = 'Your request cannot be processed due to invalid request parameters.'
          redirect_to (request.referrer || root_path) and return
        }
      end
    end

    #remove empty elements
    params[:dids].reject!(&:empty?)

    #Did.where(id: params[:dids]).destroy_all

    respond_to do |format|
      format.html { 
        flash[:notice] = 'The selected DIDs has been removed from the system.'
          redirect_to (request.referrer || root_path) and return
      }
    end
  end
  
  def check_group_name
    unless request.xhr?
      redirect_to manage_inbound_dids_url and return  
    end

    authorize :inbound_dids_groups, :check_group_name?

    if params[:did_group].blank? || params[:did_group][:name].blank?
      format.js { render 'shared/not_found' }
    end
    if params[:ignore].present? 
      if params[:ignore].downcase != params[:did_group][:name].downcase
        render json: !carrier.did_groups.exists?(name: params[:did_group][:name])
      else
        render json: true
      end
    else
      render json: !carrier.did_groups.exists?(name: params[:did_group][:name])
    end
  end

  private 
  def did_group_params
    params.require(:did_group).permit(:name, :description)
  end

end
