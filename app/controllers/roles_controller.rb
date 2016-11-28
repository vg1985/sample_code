class RolesController < ApplicationController
  before_action :set_role, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /roles
  # GET /roles.json
  def index
    authorize Role.new
    @roles = Role.all
  end

  # GET /roles/1
  # GET /roles/1.json
  def show
  end

  # GET /roles/new
  def new
    @role = Role.new(internal: false, visible: true)
    authorize @role
  end

  # GET /roles/1/edit
  def edit
    authorize @role
  end

  # POST /roles
  # POST /roles.json
  def create
    @role = Role.new(role_params)
    authorize @role

    respond_to do |format|
      if @role.save
        format.html { redirect_to @role, notice: 'Role was successfully created.' }
        format.js                                     
        format.json { render :show, status: :created, location: @role }
      else
        format.html { render :new }
        format.js
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /roles/1
  # PATCH/PUT /roles/1.json
  def update
    authorize @role

    respond_to do |format|
      if @role.update(role_params)
        BustRolesCacheJob.perform_now(@role.id)
        
        format.html { redirect_to @role, notice: 'Role was successfully updated.' }
        format.js
        format.json { render :show, status: :ok, location: @role }
      else
        format.html { render :edit }
        format.js
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.json
  def destroy
    authorize @role
    @role.destroy

    respond_to do |format|
      format.html { redirect_to roles_url, notice: 'Role was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def check_name
    skip_authorization

    @role = Role

    if params[:id].to_i > 0
      @role = @role.where(['id != ?', params[:id]])
    end

    @role = @role.where(name: params[:role][:name]).limit(1)
    
    respond_to do |format|
      format.json { render json: @role.blank? }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role
      @role = Role.find(params[:id])

      if @role.id == Role::ADMIN
        respond_to do |format|
          format.html do
            flash[:error] = 'Action not allowed for this role.'
            return redirect_to roles_path
          end
          
          format.js { return render 'shared/not_found' }
        end
      end

    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def role_params
      if @role.present? && @role.internal?
        params.require(:role).permit().tap do |whitelisted|
          whitelisted[:perms] = params[:role][:perms]
        end
      else
        params.require(:role).permit(:name, carrier_ids: []).tap do |whitelisted|
          whitelisted[:perms] = params[:role][:perms]
        end
      end
    end
end
