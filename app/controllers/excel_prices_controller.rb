class ExcelPricesController < ApplicationController
  before_action :authenticate_user!
  authorize_resource
  before_action :set_excel_price, only: [:show, :edit, :update, :import, :file_export, :destroy]

  # GET /excel_prices
  def index
    #@excel_prices = ExcelPrice.all
    @search = ExcelPrice.ransack(params[:q])
    @search.sorts = 'id asc' if @search.sorts.empty?
    @excel_prices = @search.result.paginate(page: params[:page], per_page: 30)
  end

  # GET /excel_prices/1
  def show
  end

  # GET /excel_prices/new
  def new
    @excel_price = ExcelPrice.new
  end

  # GET /excel_prices/1/edit
  def edit
  end

  # POST /excel_prices
  def create
    @excel_price = ExcelPrice.new(excel_price_params)

    respond_to do |format|
      if @excel_price.save
        format.html { redirect_to excel_prices_url, notice: "Excel price was successfully created." }
        format.json { render :show, status: :created, location: @excel_price }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @excel_price.errors, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT /excel_prices/1
  def update
    respond_to do |format|
      if @excel_price.update(excel_price_params)
        format.html { redirect_to excel_prices_url, notice: "Excel price was successfully updated." }
        format.json { render :show, status: :ok, location: @excel_price }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @excel_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /excel_prices/1
  def destroy
    @excel_price.destroy
    respond_to do |format|
      format.html { redirect_to excel_prices_url, notice: "Excel price was successfully destroyed." }
      format.json { head :no_content }
    end
  end

# POST /excel_prices
  def delete_selected
    @excel_prices = ExcelPrice.find(params[:ids])
    @excel_prices.each do |excel_price|
        excel_price.destroy
    end
    respond_to do |format|
      format.html { redirect_to excel_prices_url, notice: "Excel price was successfully destroyed." }
      format.json { render json: { :status => "ok", :message => "destroyed" } }
    end
  end

  def import
    Rails.env.development? ? Services::Import.excel_price(@excel_price) : ImportExcelPriceJob.perform_later(@excel_price)
    redirect_to excel_prices_url, notice: 'Запущен процесс создания файла эксель. Дождитесь выполнении процесса.'
  end

  def check_file_status
  end

  def file_export
    file_path = "#{Rails.public_path}/#{@excel_price.id.to_s}_file.xlsx"
    send_file(file_path)
  end

  def get_full_catalog
    Rails.env.development? ? Services::Import.load_all_catalog_xml : ImportFullCatalogJob.perform_later(@excel_price)
    redirect_to excel_prices_url, notice: 'Запущен процесс создания файла эксель. Дождитесь выполнении процесса.'
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_excel_price
      @excel_price = ExcelPrice.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def excel_price_params
      params.require(:excel_price).permit(:title, :link, :price_move, :price_shift, :price_points, :comment, :file_status)
    end
end
