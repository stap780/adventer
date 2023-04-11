<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :authenticate_user!
  authorize_resource
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]

  # GET <%= route_url %>
  def index
    #@<%= plural_table_name %> = <%= orm_class.all(class_name) %>
    @search = <%= singular_table_name.titleize %>.ransack(params[:q])
    @search.sorts = 'id asc' if @search.sorts.empty?
    @<%= plural_table_name %> = @search.result.paginate(page: params[:page], per_page: 30)
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    respond_to do |format|
      if @<%= orm_instance.save %>
        format.html { redirect_to @<%= singular_table_name %>, notice: <%= %("#{human_name} was successfully created.") %> }
        format.json { render :show, status: :created, location: <%= "@#{singular_table_name}" %> }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: <%= "@#{orm_instance.errors}" %>, status: :unprocessable_entity }
      end
    end

  end

  # PATCH/PUT <%= route_url %>/1
  def update
  respond_to do |format|
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      format.html { redirect_to @<%= singular_table_name %>, notice: <%= %("#{human_name} was successfully updated.") %> }
      format.json { render :show, status: :ok, location: <%= "@#{singular_table_name}" %> }
    else
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: <%= "@#{orm_instance.errors}" %>, status: :unprocessable_entity }
    end
  end
  end

  # DELETE <%= route_url %>/1
  def destroy
  @<%= orm_instance.destroy %>
  respond_to do |format|
    format.html { redirect_to <%= index_helper %>_url, notice: <%= %("#{human_name} was successfully destroyed.") %> }
    format.json { head :no_content }
  end
  end

# POST <%= route_url %>
  def delete_selected
    @<%= plural_table_name %> = <%= singular_table_name.titleize %>.find(params[:ids])
    @<%= plural_table_name %>.each do |<%= singular_table_name %>|
        <%= singular_table_name %>.destroy
    end
    respond_to do |format|
      format.html { redirect_to <%= index_helper %>_url, notice: <%= %("#{human_name} was successfully destroyed.") %> }
      format.json { render json: { :status => "ok", :message => "destroyed" } }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    end

    # Only allow a trusted parameter "white list" through.
    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params.fetch(:<%= singular_table_name %>, {})
      <%- else -%>
      params.require(:<%= singular_table_name %>).permit(<%= attributes_names.map { |name| ":#{name}" }.join(', ') %>)
      <%- end -%>
    end
end
<% end -%>
