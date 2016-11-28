class RoutingsController < ApplicationController
  after_action :verify_authorized

  before_filter :load_routing, except: [:index, :new, :create, :check_name, :search]
  
  def index
    authorize Routing.new

    if params[:q].present?
      @routings = Routing.where(["routings.name LIKE :search_term OR 
                                routings.description LIKE :search_term 
                                OR egress_trunks.name LIKE :search_term
                                OR carriers.company_name LIKE :search_term",
                                search_term: "%#{params[:q]}%"])
                      .joins(egress_trunks: [:carrier]).page(params[:page])
                      .select('routings.id, routings.name, routings.routing_type, routings.description')
                      .group('routings.id')
    else
      @routings = Routing.page(params[:page])
    end

    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def new
    session['test'] = 1
    @routing = Routing.new
    authorize @routing
  end
  
  def create
    @routing = Routing.new(routing_params)
    authorize @routing
    @routing.egress_trunk_ids = params[:routing][:egress_trunk_ids].reject(&:blank?)
    respond_to do |format|
      format.html { 
        if @routing.save
          flash[:notice] = 'Routing plan has been successfully created'
        else
          flash[:error] = 'Routing plan could not be created due to error while saving.'
          logger.info 'errors........' + @routing.errors.full_messages.inspect
        end

        redirect_to routings_path
      }
    end
  end
  
  def edit
    authorize @routing
  end
  
  def update
    @routing.update_attributes(routing_params)
    
    authorize @routing

    if @routing.errors.any?
      flash[:error] = 'Routing plan could not be created due to error while updating.'
    else
      flash[:notice] = 'Routing plan has been successfully updated'
    end

    redirect_to routings_path
  end
  
  def destroy
    authorize @routing

    if Routing.plans_in_use.include?(@routing.id)
      @error = 'The routing plan cannot be deleted. It is already in use.'
    else
      @routing.destroy
      @message = 'The routing plan has been successfully deleted.'
    end
    
    @routings = Routing.page(nil)

    respond_to do |format|
      format.js {render action: 'index'}
    end
  end

  def activate_trunk
    authorize @routing

    if params[:tid].present?
      @routing.egress_trunks.find(params[:tid]).update_attribute(:is_active, true)
      @message = 'The trunk has been successfully activated.'
    end

    @routings = Routing.page(params[:page])

    respond_to do |format|
      format.js {render :index}
    end
  end
  
  def deactivate_trunk
    authorize @routing

    if params[:tid].present?
      @routing.egress_trunks.find(params[:tid]).update_attribute(:is_active, false)
      @message = 'The trunk has been successfully deactivated.'
    end

    @routings = Routing.page(params[:page])
    
    respond_to do |format|
      format.js {render :index}
    end
  end

  def remove_trunk
    authorize @routing

    if params[:tid].present? && @routing.egress_trunks.size > 1
      @routing.egress_trunks.find(params[:tid]).destroy
      @message = 'The trunk has been successfully removed from the routing plan.'
    end

    respond_to do |format|
      format.js {render action: 'refresh_routing_table'}
    end
  end

  def trunk_move_up
    authorize @routing

    if params[:tid].present? && @routing.egress_trunks.size > 1
      @routing.routing_trunks.find_by(egress_trunk_id: params[:tid]).move_higher
      @message = 'The trunk has been successfully moved up in the routing plan.'
    end

    respond_to do |format|
      format.js {render action: 'refresh_routing_table'}
    end
  end

  def trunk_move_down
    authorize @routing

    if params[:tid].present? && @routing.egress_trunks.size > 1
      @routing.routing_trunks.find_by(egress_trunk_id: params[:tid]).move_lower
      @message = 'The trunk has been successfully moved down in the routing plan.'
    end

    respond_to do |format|
      format.js {render action: 'refresh_routing_table'}
    end
  end

  def search
    authorize Routing.new, :index?
    

    respond_to do |format|
      format.js {render 'index'}
    end

  end

  def check_name
    skip_authorization

    @routing = Routing

    if params[:id].to_i > 0
      @routing = @routing.where(["id != ?", params[:id]])    
    end

    @routing = @routing.where(name: params[:routing][:name]).limit(1)
    
    respond_to do |format|
      format.json { render :json => @routing.blank? }
    end
  end
  
  private
  def routing_params
    params[:routing].permit(:name, :routing_type, :description, egress_trunk_ids: [])
  end
  
  def load_routing
    @routing = Routing.find_by_id(params[:id])
    unless @routing
      flash[:error] = "Routing not found"
      respond_to do |format|
        format.html { redirect_to root_path }
        format.js { render "shared/not_found" }
      end
    end
  end
  
end
