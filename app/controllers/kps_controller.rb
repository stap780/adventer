class KpsController < ApplicationController
  before_action :authenticate_user!
  authorize_resource
  before_action :get_order
  before_action :set_kp, only: %i[show edit update destroy print1 print2 print3 print4 print1c]
  # autocomplete :product, :title, :extra_data => [:id, :title, :sku, :price, :desc], :display_value => :autocomplete_title, 'data-noMatchesLabel' => 'нет товара'

  # GET /kps
  def index
    @search = @order.kps.ransack(params[:q])
    @search.sorts = 'id asc' if @search.sorts.empty?
    @kps = @search.result.paginate(page: params[:page], per_page: 30)
  end

  def index_all
    @search = Kp.ransack(params[:q])
    @search.sorts = 'order_number desc' if @search.sorts.empty?
    @kps = @search.result.includes(:order, :kp_products).paginate(page: params[:page], per_page: 100)
  end

  def autocomplete_product_title
    term = params[:term]
    products = Product.search_by_title_sku(term).all
    render :json => products.map { |product| {id: product.id, title: product.title, label: product.autocomplete_title, value: product.autocomplete_title, sku: product.sku, price: product.price, desc: product.desc } }
  end

  # GET /kps/1
  def show; end

  # GET /kps/new
  def new
    @kp = @order.kps.build
  end

  # GET /kps/1/edit
  def edit; end

  # POST /kps
  def create
    @kp = @order.kps.build(kp_params)

    respond_to do |format|
      if @kp.save
        format.html { redirect_to edit_order_path(@order), notice: 'КП создано' }
        format.json { render :show, status: :created, location: @kp }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @kp.errors, status: :unprocessable_entity }
      end
    end
  end


  # PATCH/PUT /kps/1
  def update
    params[:kp][:kp_products_attributes].each do |k,v|
      if !v["product_id"].present?
        # puts 'not present'
        # puts v["product_sku_title"]
        # product = Product.find_or_create_by(title: v["product_sku_title"], quantity: v["quantity"], price: v["price"], sku: v["product_sku_title"].gsub(' ','_'))
        sku = v["sku"].present? ? v["sku"] : ''
        product = Product.find_or_create_by(title: v["product_title"], quantity: v["quantity"], price: v["price"], sku: sku )
        # puts product.id.to_s
        v["product_id"] = product.id
      end
    end

    respond_to do |format|
      if @kp.update(kp_params)
        format.html { redirect_to edit_order_path(@order), notice: 'Обновили КП' }
        format.json { render :show, status: :ok, location: @kp }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @kp.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /kps/1
  def destroy
    @kp.destroy
    respond_to do |format|
      format.html { redirect_to edit_order_path(@order), notice: 'КП удалено' }
      format.json { head :no_content }
    end
  end

  # POST /kps
  def delete_selected
    @kps = @order.kps.find(params[:ids])
    @kps.each do |kp|
      kp.destroy
    end
    respond_to do |format|
      format.html { redirect_to order_kps_path(@order), notice: 'КП удалено' }
      format.json { render json: { status: 'ok', message: 'destroyed' } }
    end
  end

  def print1
    # @kp = Kp.find(params[:id])
    # puts @kp.present?
    @our_company = @kp.order.companykp1
    if @our_company.present?
    @company = @kp.order.company
    respond_to do |format|
      format.html
      format.pdf do
          render pdf: "КП1 #{@kp.id}",
                 template: "kps/print1.html.erb",
                 show_as_html: params.key?('debug'),
                 page_size: "A4",
     						 margin: {top: 5, left: 5, right: 5, bottom: 45 },
     						 header:  {
     						 		#html: { template:'kps/print1_header.html.erb'},
     						 		#spacing: 5,
                    # right: 'Стр [page] из [topage]'
                    locals: {}
     						 		},
     						 footer: {
     							 html: { template:'kps/print1_footer.html.erb'},
     							 	#spacing: 2,
     								locals: {}
     								#right: '_______________________(подпись)                  _______________________(подпись)            [page] из [topage]'
     								}
        end
    end
    else
      flash[:notice] = 'Выберите компанию 1'
      redirect_to edit_order_path(@order)
    end
  end

  def print2
    # @kp = Kp.find(params[:id])
    @client = @kp.order.client
    @company = @kp.order.company
    @our_company = @kp.order.companykp2
    if @our_company.present?
      @kp_products_data = []
      @kp.kp_products.each do |kp|
        data = {
                sku: kp.product.sku,
                # image_url: rails_representation_url(kp.product.images.first.variant(combine_options: {auto_orient: true, thumbnail: '40x40', gravity: 'center', extent: '40x40' }).processed, only_path: true),
                image_url: kp.product.images.first,
                title: kp.product.title,
                price: kp.price,
                quantity: kp.quantity,
                sum: (kp.sum.truncate(2).to_s("F") + "00")[ /.*\..{2}/ ]
              }
        @kp_products_data << data
      end
      @stamp = params[:type] == "stamp" ? true : false
      @kp_products = params[:type] == "random" ? @kp_products_data.sort_by{ |hsh| hsh[:price] } : @kp_products_data

      # puts @kp_products_data
      respond_to do |format|
        format.html
        format.pdf do
            render pdf: "КП2 #{@kp.id}",
                   template: "kps/print2.html.erb",
                   page_size: 'A4',
                   orientation: "Portrait",
                   show_as_html: params.key?('debug'),
                   margin: {top: 15, left: 5, right: 5, bottom: 20},
                   # footer: {
                   #   spacing: 5,
                   #   right: 'Стр [page] из [topage]'
                   # }
                   # header:  {
                   # 		html: { template:'kps/print1_header.html.erb'},
                   # 		spacing: 3
                   # 		# locals: {},
                   #    # right: 'Стр [page] из [topage]'
                   # 		},
                   footer: {
                     html: { template:'kps/print2_footer.html.erb'},
                      :spacing => 3,
                      locals: {}
                      #right: '_______________________(подпись)                  _______________________(подпись)            [page] из [topage]'
                      }
          end
      end
    else
      flash[:notice] = 'Выберите компанию 2'
      redirect_to edit_order_path(@order)
    end
  end

  def print3
    # @kp = Kp.find(params[:id])
    @company = @kp.order.company
    @our_company = @kp.order.companykp3
    puts @our_company.present?
    if @our_company.present?
      @kp_products_data = []
      @kp.kp_products.each do |kp|
        data = {
                sku: kp.product.sku,
                # image_url: rails_representation_url(kp.product.images.first.variant(combine_options: {auto_orient: true, thumbnail: '40x40', gravity: 'center', extent: '40x40' }).processed, only_path: true),
                image_url: kp.product.images.first,
                title: kp.product.title,
                price: kp.price,
                quantity: kp.quantity,
                sum: (kp.sum.truncate(2).to_s("F") + "00")[ /.*\..{2}/ ]
              }
        @kp_products_data << data
      end
      @stamp = params[:type] == "stamp" ? true : false
      @kp_products = params[:type] == "random" ? @kp_products_data.sort_by{ |hsh| hsh[:sku] } : @kp_products_data

      respond_to do |format|
        format.html
        format.pdf do
                render pdf: "КП3 #{@kp.id}",
                       page_size: 'A4',
                       template: "kps/print3.html.erb",
                       orientation: "Portrait",
                       lowquality: true,
                       zoom: 1,
                       dpi: 75,
                       show_as_html: params.key?('debug'),
                       #header: { right: 'Стр [page] из [topage]' }
                       :margin => {top: 15, left: 0, right: 0, bottom: 20 },
                       # header:  {
           						 # 		html: { template:'kps/print1_header.html.erb'},
           						 # 		spacing: 3
           						 # 		# locals: {},
                       #    # right: 'Стр [page] из [topage]'
           						 # 		},
           						 footer: {
           							 html: { template:'kps/print3_footer.html.erb'},
           							 	:spacing => 3,
           								locals: {}
           								#right: '_______________________(подпись)                  _______________________(подпись)            [page] из [topage]'
           								}
          end
      end

    else
      flash[:notice] = 'Выберите компанию 3'
      redirect_to edit_order_path(@order)
    end
  end

  def print4
    @client = @kp.order.client
    @company = @kp.order.company
      @kp_products_data = []
      @kp.kp_products.each do |kp|
        data = {
                sku: kp.product.sku,
                # image_url: rails_representation_url(kp.product.images.first.variant(combine_options: {auto_orient: true, thumbnail: '40x40', gravity: 'center', extent: '40x40' }).processed, only_path: true),
                image_url: kp.product.images.first,
                title: kp.product.title,
                price: kp.price,
                quantity: kp.quantity,
                sum: (kp.sum.truncate(2).to_s("F") + "00")[ /.*\..{2}/ ]
              }
        @kp_products_data << data
      end
      @kp_products = params[:type] == "random" ? @kp_products_data.sort_by{ |hsh| hsh[:price] } : @kp_products_data
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename="print4.xlsx"'
        }
      end
  
  end

  def print1c
      @kp_products_data = []
      @kp.kp_products.each do |kp|
        sku = kp.product.sku.present? ? kp.product.sku : nil
        title = kp.product.title
        if !sku.nil? && sku.include?('ФД')
          cat = "Продукция"
          group = "Артикульная продукция"
          type = "Производство мебели"
          ss = "FIFO"
          sposob = "Производство"
        end
        if !sku.nil? && sku.include?('АДВ')
          cat = "Продукция"
          group = "Артикульная продукция"
          type = "Прочее производство"
          ss = "FIFO"
          sposob = "Производство"
        end
        if !sku.include?('ФД') && !sku.include?('АДВ') && !sku.nil?
          cat = "Товар"
          group = "Товар"
          type = "Основное направление"
          ss = "FIFO"
          sposob = "Закупка"
        end
        if sku.nil? && title.include?('доставка') && title.include?('монтаж') && title.include?('сборка')
          cat = "Услуги"
          group = "Услуги"
          type = "Услуги"
          ss = "FIFO"
          sposob = "Закупка"
        end
        if sku.nil? && !title.include?('доставка') && !title.include?('монтаж') && !title.include?('сборка')
          cat = "Продукция"
          group = "Продукция"
          type = "Прочее производство или Производство мебели"
          ss = ""
          sposob = "Производство"
        end

  
        data = {
                sku: sku,
                # image_url: rails_representation_url(kp.product.images.first.variant(combine_options: {auto_orient: true, thumbnail: '40x40', gravity: 'center', extent: '40x40' }).processed, only_path: true),
                image_url: kp.product.images.first,
                title: title,
                price: kp.price,
                desc: kp.desc,
                quantity: kp.quantity,
                sum: (kp.sum.truncate(2).to_s("F") + "00")[ /.*\..{2}/ ],
                cat: cat,
                group: group,
                type: type,
                ss: ss,
                sposob: sposob
              }
        @kp_products_data << data
      end
      @kp_products = params[:type] == "random" ? @kp_products_data.sort_by{ |hsh| hsh[:price] } : @kp_products_data
      #puts @kp_products.count
      respond_to do |format|
        format.html
        format.xlsx {
          response.headers['Content-Disposition'] = 'attachment; filename="print1c.xlsx"'
        }
      end
  
  end

  # это для модалки для загрузки файла
  def file_import
    respond_to do |format|
      format.js
    end
  end

  def file_export
    @kp = @order.kps.find(params[:id])
    filename = "file_export.csv"
    respond_to do |format|
      format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
      format.csv { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  def import
    @kp = Kp.find(params[:id])
    Kp.import(params[:file], params[:order_id], params[:id])
    flash[:notice] = 'Products was successfully import'
    redirect_to edit_order_kp_path(@order, @kp)
	end

  def copy
    # puts 'here copy'
    @kp = @order.kps.find(params[:id])
    @new_kp = @order.kps.create(vid: @kp.vid, status: @kp.status, title: @kp.title)
    kp_products = @kp.kp_products.select(:product_id,:quantity,:price,:sum, :desc, :sku).map(&:attributes)

    kp_products.each do |kp_p_data|
      @new_kp.kp_products.create(kp_p_data)
    end

    flash[:notice] = 'КП скопировали'
    redirect_to edit_order_kp_path(@order, @new_kp)
  end

  private

  def get_order
    @order = Order.find(params[:order_id]) if params[:order_id].present?
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_kp
    @kp = @order.kps.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def kp_params
    params.require(:kp).permit(:vid, :status, :title, :order_id, :extra, :comment, kp_products_attributes:[:id,:quantity,:price,:sum,:product_id, :desc, :sku,:_destroy])
  end
end
