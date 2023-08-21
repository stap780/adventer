class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  # protect_from_forgery with: :exception
  protect_from_forgery with: :null_session
  before_action :authenticate_user!
  before_action :allow_cross_domain_ajax
  helper_method :current_admin
  # helper_method :authenticate_admin!
  check_authorization unless: :devise_controller?


  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil?
      session[:next] = request.fullpath
      redirect_to login_url, alert: 'You have to log in to continue.'
    else
      respond_to do |format|
        format.json { render nothing: true, status: :not_found }
        format.html { redirect_to main_app.root_url, alert: exception.message }
        format.js   { render nothing: true, status: :not_found }
      end
    end
  end

  # rescue_from CanCan::AccessDenied do |exception|
  #   respond_to do |format|
  #     format.json { head :forbidden }
  #     format.html { redirect_to orders_path, alert: exception.message }
  #   end
  # end

  def allow_cross_domain_ajax
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = 'GET, POST, OPTIONS'
  end

  private

  def current_admin
      current_user.role.name == 'admin' ? true : false
  end


  def authenticate_admin!
    unless current_admin
      redirect_to root_path, alert: "У вас нет прав админа"
    end
  end


  def active_storage_host
    ActiveStorage::Current.host = request.base_url
  end

protected

# If you have extra params to permit, append them to the sanitizer.
def configure_permitted_parameters
  attributes = [:name, :email, :role_id, :avatar]
  devise_parameter_sanitizer.permit(:sign_up, keys: attributes)
  devise_parameter_sanitizer.permit(:account_update, keys: attributes)
end

def authenticate_user!
  if current_user.present? && current_user.role.name == 'registered'
    sign_out current_user
    # sign_out_and_redirect(current_user)
    # redirect_to root_path
  else
    super
  end
end


end
