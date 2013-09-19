class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  #include SessionsHelper
  
  before_filter :set_user
  before_filter :set_cache_buster
  

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  protected
  def set_user
    #@user ||= User.find(session[:id]) if @user.nil? && session[:id]
    @user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
    if @user
        session[:id] = @user.id
        session[:user_id] = @user.id
        session[:user_name] = @user.name
    end
  end
  
  def request_access
    if authenticate() then
      return true
    else
      access_denied
      return false
    end
  end
  
  def authenticate
    if @user
      return true
    end
      return false
  end

  def access_denied
    session[:return_to] = request.url
    flash[:error] = 'Oops. You need to login.' 
    redirect_to :controller => 'users', :action => 'login'
  end
end
