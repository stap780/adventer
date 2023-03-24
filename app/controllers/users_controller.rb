class UsersController < ApplicationController
  before_action :authenticate_user!
  authorize_resource
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @search = User.ransack(params[:q])
    @search.sorts = 'id asc' if @search.sorts.empty?
    @users = @search.result.paginate(page: params[:page], per_page: 30)
  end

  def edit
    @user = User.find(params[:id])
  end

  def show
    @user = User.find(params[:id])
    # redirect_to root_path, alert: 'Access denied.' unless @user == current_user
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    @user.avatar.attach(params[:user][:avatar]) if params[:user][:avatar]
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to users_url, notice: "User was successfully updated." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end


  def destroy
    @user = User.find(params[:id])
    if (User.count > 1) && !@user.admin?
      @user.destroy!

      respond_to do |format|
        format.html { redirect_to users_url, notice: 'Пользователь удалён' }
        format.json { head :no_content }
      end
    else
      redirect_to users_url, notice: 'Нельзя удалить последнего пользователя или админа'
    end
  end


  def delete_image
    ActiveStorage::Attachment.where(id: params[:image_id])[0].purge
    respond_to do |format|
      #format.html { redirect_to edit_product_path(params[:id]), notice: 'Image was successfully deleted.' }
      format.json { render json: { :status => "ok", :message => "destroyed" } }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
    # Only allow a trusted parameter "white list" through.
    def user_params
      params.require(:user).permit(:name, :email, :role_id, :avatar, :phone)
    end

end
