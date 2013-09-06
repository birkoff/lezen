class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_user
  before_filter :set_cache_buster

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  protected
  def set_user
    @user = User.find(session[:id]) if @user.nil? && session[:id]
  end

  def authenticate
    return true if @user
    access_denied
    return false
  end

  def access_denied
    session[:return_to] = request.url
    flash[:error] = 'Oops. You need to login.' 
    redirect_to :controller => 'users', :action => 'login'
  end
end
