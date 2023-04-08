class KpProductsController < ApplicationController
  before_action :authenticate_user!
  authorize_resource
  skip_authorization_check :only => [:update_by_bip, :update_modal, :update_by_js ]
  before_action :set_kp_product, only: [:show, :edit, :update, :destroy, :update_by_bip, :update_modal]

  # GET /kp_products
  def index
    @search = KpProduct.ransack(params[:q])
    @search.sorts = 'id asc' if @search.sorts.empty?
    @kp_products = @search.result.paginate(page: params[:page], per_page: 30)
  end

  # GET /kp_products/1
  def show
  end

  # GET /kp_products/new
  def new
    @kp_product = KpProduct.new
  end

  # GET /kp_products/1/edit
  def edit
  end

  # POST /kp_products
  def create
    @kp_product = KpProduct.new(kp_product_params)

    respond_to do |format|
      if @kp_product.save
        # format.html { redirect_to @kp_product, notice: "Kp product was successfully created." }
        format.json { render json: @kp_product, status: :created }
      else
        # format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @kp_product.errors, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT /kp_products/1
  def update
    respond_to do |format|
      if @kp_product.update(kp_product_params)
        # format.html { redirect_to @kp_product, notice: "Kp product was successfully updated." }
        format.json { render json: @kp_product, status: :ok, location: @kp_product }
      else
        # format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @kp_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kp_products/1
  def destroy
    @kp_product.destroy
    respond_to do |format|
      # format.html { redirect_to kp_products_url, notice: "Kp product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /kp_products
  def delete_selected
    @kp_products = KpProduct.find(params[:ids])
    @kp_products.each do |kp_product|
        kp_product.destroy
    end
    respond_to do |format|
      format.html { redirect_to kp_products_url, notice: "Kp product was successfully destroyed." }
      format.json { render json: { :status => "ok", :message => "destroyed" } }
    end
  end

  def update_by_bip
	  respond_to do |format|
	    if @kp_product.update_attributes(kp_product_params)
	      format.json { respond_with_bip(@kp_product) }
	    else
	      format.json { respond_with_bip(@kp_product) }
	    end
	  end
  end

  def update_modal
    respond_to do |format|
      format.js
    end
  end
  
  def update_by_js
    @kp_product = KpProduct.find(params[:id])
    #puts "@kp_product => "+@kp_product.to_s

    respond_to do |format|
      if @kp_product.update(kp_product_params)
        format.js
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_kp_product
      @kp_product = KpProduct.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def kp_product_params
      params.require(:kp_product).permit(:desc, :quantity, :price, :sum, :kp_id, :product_id, :sku, :use_desc)
    end
end
