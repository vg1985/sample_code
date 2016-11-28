class UsersController < ApplicationController
  after_action :verify_authorized
  before_action :load_internal_user, only: [:edit_internal, :update_internal, :destroy]
  #before_action :load_user, only: [:reset_password]
   
  def index
    authorize User.new
  end
  
  def dt_users_interplay
    authorize User.new, :index?
    
    filter_query = {}
    
    select_clause = 'users.id, users.name, users.username, users.email, users.address1, 
                     users.city, users.state, users.country, users.is_active'

    search_filter = ['users.name LIKE ? OR users.email LIKE ? OR users.username', 
                      "%#{params["search"]["value"]}%", "%#{params["search"]["value"]}%"]

    order_by = "#{User::DT_ADMIN_COLS[params[:order]["0"][:column].to_i - 1]} #{params[:order]["0"][:dir]}"
    
    @users = User.internal.where(filter_query).select(select_clause).order(order_by)

    if params['search']['value'].present?
      @users = @users.where(search_filter)
    end

    @users = @users.page(params[:page]).per(params[:length])
      
    @data = @users.collect do |u|
      [u.id, u.name, u.username, u.email, u.address1, u.country, u.is_active, u.state]
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    @user = User.new(internal: true)

    authorize @user
    
    respond_to do |format|
      format.html {  }
    end
  end

  def create
    @user = User.new(user_params)
    authorize @user

    @user.internal = true
    @user.skip_confirmation!

    if @user.save
      flash[:notice] = 'User created successfully.'
    else
      flash[:error] = 'Error: User cannot be created at this moment.'
    end

    respond_to do |format|
      format.html { redirect_to users_path and return  }
    end
  end
  
  def edit
    respond_to do |format|
      format.html {  render 'edit_internal' }
    end
  end

  def edit_internal
    authorize @user
  end

  def update_internal
    authorize @user

    if @user.update_attributes(current_user.is_admin? ? user_params : internal_user_params)
      if current_user.id != @user.id
        flash[:notice] = 'User profile has been successfully updated. Please note that if you 
                            have requested the email change then the confirmation request is sent to user\'s new email ID.'
      else
        flash[:notice] = 'Your profile has been successfully updated. Please note that if you 
                            have requested the email change then the confirmation request is sent to your new email ID.'
      end
    else
      flash[:error] = 'Error: User cannot be updated at this moment.'
    end

    respond_to do |format|
      format.html { redirect_to :back and return }
    end
  end

  def update
    @user.attributes = user_params
    if @user.current_password.present?
      if @user.valid_password?(@user.current_password)
        flash[:notice] = "Record updated" if @user.save
      else
        @user.errors.add(:current_password, "Invalid Password")
      end
    else
      flash[:notice] = 'Record updated' if @user.save
    end
  end
  
  def update_bulk_status
    authorize User.new, :index?

    @users = User.where(id: params[:user_ids])
    @users.update_all(is_active: params[:enable].present? ? true : false)
    @success_msg = 'Users status have been updated successfully.'

    render :update_status
  end
  
  def destroy
   authorize @user
   @user.destroy
  end

  def search
    skip_authorization

    allowed = policy(:carrier).masquerade_menu? || policy(:user_action).masquerade?
    
    unless allowed
      respond_to do |format|
        format.html { redirect_to root_url and return }
        format.js { render json: 'Not Authorized' and return }
      end
    end

    if params[:q].blank?
      respond_to do |format|
        format.js { render json: [] } and return
      end
    end

    users = User.where( ['(users.name LIKE :q OR users.email LIKE :q
                          OR users.username LIKE :q OR carriers.company_name)
                          AND users.id <> :current',
                          { q: "%#{params[:q]}%", current: current_user.id }] )
            .joins('LEFT JOIN carriers ON users.id = carriers.user_id')

    if policy(:user_action).masquerade?
      users = users
              .select('users.id, carriers.company_name,
                      users.username, users.name')
              .all

      respond_to do |format|
        format.js { render json: users.as_json and return }
      end
    end

    if policy(:carrier).masquerade_menu? && current_user.allowed_carriers.present?
      if current_user.allowed_carriers.include?('-10')
        users = users.carriers_only
      else
        user_ids = Carrier.find(current_user.allowed_carriers).collect(&:user_id)
        users = users.carriers_only.where(['users.id IN (?)', user_ids])
      end

      users = users
              .select('users.id, carriers.company_name,
                      users.username, users.name')
              .all

      respond_to do |format|
        format.js { render json: users.as_json and return}
      end
    end

    respond_to do |format|
      format.js { render json: [].as_json and return}
    end
  end
  
  def check_email
    skip_authorization
    @user = User.where(email: params[:user][:email]).limit(1)
    
    if params[:user_id].to_i > 0
      @user = @user.where(['id != ?', params[:user_id]])
    end

    respond_to do |format|
      format.json { render json: @user.blank? }
    end
  end
  
   def check_username
    skip_authorization

    @user = User.where(username: params[:user][:username]).limit(1)
    
    if params[:user_id].to_i > 0
      @user = @user.where(['id != ?', params[:user_id]])
    end

    respond_to do |format|
      format.json { render json: @user.blank? }
    end
  end
  
 
  private
  def load_user
    @user = User.find(params[:id])
  end

  def load_internal_user
    @user = User.internal.find_by(id: params[:id])

    if @user.blank?
      respond_to do |format|
        format.html {
          flash[:error] = 'User could not be found'
          redirect_to root_url and return
        }
      end
    end
  end

  def user_params
    params[:user].permit(:id, :name, :username, :email, :password, :password_confirmation,
      :department, :address1, :address2, :city, :state, :country, :zip, :phone1,
      :phone2, :mobile, :timezone, role_ids: [])
  end

  def internal_user_params
    params[:user].permit(:id, :password, :password_confirmation, :timezone)
  end

end
