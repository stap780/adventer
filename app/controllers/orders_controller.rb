class OrdersController < ApplicationController

  before_action :authenticate_user!, except: [:webhook]
  authorize_resource except: :webhook
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  autocomplete :company, :title, :extra_data => [:id, :fulltitle, :inn], :display_value => :title, 'data-noMatchesLabel' => 'нет компании'
  autocomplete :client, :name, full: true,  :extra_data => [:id, :surname], :case_sensitive => true


  # GET /orders
  def index
    @search = current_user.can_show_all_order? ? Order.ransack(params[:q]) : Order.where(user_id: current_user.id).ransack(params[:q])
    @search.sorts = 'number desc' if @search.sorts.empty?
    @orders = @search.result.paginate(page: params[:page], per_page: 100)
  end

  # GET /orders/1
  def show
    redirect_to edit_order_url(@order)
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  def create
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to edit_order_url(@order), notice: "Заказ создан" }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT /orders/1
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to edit_order_url(@order), notice: "Заказ обновлён" }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: "Заказ удалён" }
      format.json { head :no_content }
    end
  end

# POST /orders
  def delete_selected
    @orders = Order.find(params[:ids])
    @orders.each do |order|
        order.destroy
    end
    respond_to do |format|
      format.html { redirect_to orders_url, notice: "Заказы удалёны" }
      format.json { render json: { :status => "ok", :message => "destroyed" } }
    end
  end

  def download
    if !params[:insid].present?
      Order.download_last_five
      flash[:notice] = 'Заказы загружены'
      redirect_to orders_path
    else
      Order.download_one_order(params[:insid])
      flash[:notice] = 'Заказ загружен'
      redirect_to orders_path
    end
  end

  def webhook
    current_user = User.joins(:role).where(name: "admin").first if current_user.nil?
    Order.one_order(params)
    flash[:notice] = 'Заказ загружен'
    redirect_to orders_path
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def order_params
      params.require(:order).permit(:status, :number, :insid, :client_id, :company_id, :companykp1_id, :companykp2_id, :companykp3_id, :user_id, :number_adventer)
    end
end
