class CreditCardsController < ApplicationController
  after_action :verify_authorized

  before_filter :get_credit_card, only: [ :enable,
                                          :disable,
                                          :activate,
                                          :deactivate,
                                          :check_authorization,
                                          :destroy,
                                          :download_authorization,
                                          :remove_attached_authorization,
                                          :attach_authorization
                                        ]

  def finalize
    @credit_card = current_user.carrier.credit_cards.unconfirmed
                  .where(id: params[:id], redir_ref: params[:ref].gsub(/\?.*/, '')).first

    if @credit_card.blank?
      redirect_to credit_cards_path, error: 'Credit Card not found.' and return
    end

    skip_authorization

    @credit_card.card_type = params['UMcardType'] if params['UMcardType']
    @credit_card.card_number = params['UMmaskedCardNum'] if params['UMmaskedCardNum']
    @credit_card.storage_id = params['UMcardRef'] if params['UMcardRef']

    if params['UMstatus'] == 'Approved' && @credit_card.save
      @credit_card.set_as_on_cloud
      flash[:notice] = 'Credit Card is successfully added.'
    else
      flash[:error] = "Error adding the card. #{params['UMerror'] if params['UMerror']}"
    end

    redirect_to :credit_cards
  end

  def confirm
    @credit_card = current_user.carrier.credit_cards.unconfirmed.where(id: params[:id]).first

    skip_authorization

    redirect_to credit_cards_path, alert: 'Card not found.' unless @credit_card
    @for_cloud = cc_on_cloud_params
  end

  def index
    authorize CreditCard.new, :index?

    if policy(:credit_card).select_carrier?
      @credit_cards = CreditCard.all
      @carriers = Carrier.all
    else
      @credit_cards = current_user.carrier.credit_cards
    end
  end

  def dt_cc_interplay
    authorize CreditCard.new, :index?

    filter_query = {}

    if policy(:payment).select_carrier?
      filter_query[:carrier_id] = params[:columns]['0']['search']['value'] if params[:columns]['0']['search']['value'].present?
      filter_query[:active] = params[:columns]['6']['search']['value'] if params[:columns]['6']['search']['value'].present?
    else
      # to be implemented
    end

    if policy(:payment).select_carrier?
      # filter_query[:status] ||= ["pending"]
    else
      # filter_query[:status] ||= "All Statuses"
    end

    if filter_query[:active].blank?
      filter_query[:active] = [0, 1]
    end

    select_clause = 'credit_cards.id, nickname, card_number, card_type, expired_on, credit_cards.created_at, enabled, active, on_cloud'

    if policy(:credit_card).select_carrier?
      select_clause += ' ,carriers.company_name'
      order_by = "#{CreditCard::DT_ADMIN_COLS[params[:order]['0'][:column].to_i]} #{params[:order]['0'][:dir]}"
      @credit_cards = CreditCard.where(filter_query).joins(:carrier)
                      .select(select_clause).order(order_by)
                      .page(params[:page]).per(params[:length])

      @data = @credit_cards.collect do |cc|
        actions = [cc.id.to_s]
        actions << [true, cc.documents.count]
        actions << (cc.on_cloud? && policy(cc).activate? && !cc.active?) ? true : false
        actions << (policy(cc).deactivate? && cc.active?) ? true : false
        actions << policy(cc).destroy? ? true : false

        [
          cc.company_name, cc.nickname, 
          cc.card_number || '-NA-', cc.card_type || '-NA-',
          cc.expired_on.strftime("%m/%y"), 
          cc.created_at.in_time_zone(current_user.timezone).to_s(:carrier), 
          cc.verified?, cc.enabled?, actions
        ]
      end
    else
      # to be implemented
    end

    respond_to do |format|
      format.json
    end
  end

  def new
    @credit_card = CreditCard.new

    authorize @credit_card

    params[:cc_cloud] ||= {}
  end

  def create
    @credit_card = CreditCard.new cc_db_params
    @credit_card.carrier = current_user.carrier

    authorize @credit_card

    if params[:uploaded_docs].present?
      @credit_card.document_ids = params[:uploaded_docs].split(',')
    end

    if @credit_card.save
      redirect_to confirm_credit_card_path @credit_card, cc_cloud: cc_on_cloud_params and return
    else
      flash[:error] = 'Card creation failed. Make sure the credit card parameters and documents attached are valid.'
      render action: 'new'
    end
  end

  def destroy
    authorize @credit_card

    if @credit_card.destroy
      redirect_to credit_cards_path, notice: 'Card successfully deleted.'
    else
      redirect_to credit_cards_path, error: "Card deletion failed. #{@credit_card.errors.full_messages.join('. ')}"
    end
  end

  def enable
    authorize @credit_card

    if @credit_card.active? and @credit_card.enable
      redirect_to credit_cards_path, notice: 'Card successfully enabled.'
    else
      redirect_to credit_cards_path, error: 'Card update failed.'
    end
  end

  def disable
    authorize @credit_card

    if @credit_card.disable
      redirect_to credit_cards_path, notice: 'Card successfully disabled.'
    else
      redirect_to credit_cards_path, error: 'Card update failed.'
    end
  end

  def activate
    authorize @credit_card

    if @credit_card.on_cloud? and @credit_card.activate
      redirect_to credit_cards_path, notice: 'Card successfully activated.'
    else
      redirect_to credit_cards_path, error: 'Card update failed.'
    end
  end

  def deactivate
    authorize @credit_card

    if @credit_card.deactivate
      redirect_to credit_cards_path, notice: 'Card successfully deactivated.'
    else
      redirect_to credit_cards_path, error: 'Card update failed.'
    end
  end

  def upload_authorization
    skip_authorization

    if params[:file].present? &&
        params[:file].is_a?(ActionDispatch::Http::UploadedFile)
      @document = Document.new(content: params[:file], user: current_user)
    end

    respond_to do |format|
      if @document.save
        format.json { render json: { status: :success, id: @document.id }.to_json }
      else
        format.json { render text: @document.errors.get(:content).to_s, status: 500 }
      end
    end
  end

  def download_authorization
    authorize @credit_card

    @document = @credit_card.documents.find(params[:document_id])
    send_file @document.content.path,
              type: @document.content_content_type,
              disposition: 'attachment'
  end

  # remove document only when it is not linked to credit card
  def remove_authorization
    # no authorization required as document is still not linked to credit card
    skip_authorization

    if params[:id].present?
      @document = current_user.documents.find_by(id: params[:id])

      if @document.present? && @document.documentable.blank?
        @document.destroy
      end
    end

    render nothing: true
  end

  def remove_attached_authorization
    authorize @credit_card

    if params[:id].present?
      @document = @credit_card.documents.find(params[:document_id])

      if @document.present? && @document.documentable.blank?
        # @document.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to :credit_cards }
      format.js
    end
  end

  def attach_authorization
    authorize @credit_card

    if params[:uploaded_docs].present?
      uploaded_doc_ids = params[:uploaded_docs].split(',')

      if (@credit_card.documents.size + uploaded_doc_ids.size <= 3)
        @credit_card.document_ids += uploaded_doc_ids
      end
    end

    if params[:credit_card].present? &&
        params[:credit_card][:documents_attributes].present?

      @credit_card.documents_attributes =
        params[:credit_card][:documents_attributes]
    end

    if @credit_card.save
      flash[:notice] = 'File(s) attached successfully with the card.'
    else
      flash[:error] = 'Files could be attached with the credit card.
                        Make sure the documents are valid.'
    end

    respond_to do |format|
      format.html { redirect_to :credit_cards }
    end
  end

  def check_authorization
    @credit_card = CreditCard.where(id: params[:id]).first

    authorize @credit_card
    @documents = @credit_card.documents

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def check_nickname
    redirect_to credit_cards_url and return unless request.xhr?

    authorize CreditCard.new

    if params[:credit_card].blank? || params[:credit_card][:nickname].blank?
      format.js { render 'shared/not_found' }
    end

    respond_to do |format|
      format.json do
        render json: !current_user.carrier.credit_cards
          .where(nickname: params[:credit_card][:nickname]).present?
      end
    end
  end

  private

  def get_credit_card
    @credit_card = CreditCard.where(id: params[:id]).first
    redirect_to credit_cards_path, error: 'Card not found.' unless @credit_card
  end

  def cc_db_params
    # params[:credit_card][:card_number] ||= params[:credit_card][:number]
    if cc_on_cloud_params[:year] && cc_on_cloud_params[:month]
      params[:credit_card][:expired_on] ||= Date.new(
        cc_on_cloud_params[:year].to_i,
        cc_on_cloud_params[:month].to_i)
    end

    params.require(:credit_card)
      .permit(:nickname, :expired_on, :address, :city_state,
              :zip_code, :other_city_state,
              documents_attributes: [[:content]])
  end

  def cc_on_cloud_params
    params.require(:cc_cloud)
      .permit(:number, :verification_value, :month,
              :year, :first_name, :last_name, :brand)
  end
end
