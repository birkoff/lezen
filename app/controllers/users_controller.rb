class UsersController < ApplicationController
  def login
    @user = User.new
  end
  
  def process_login
    if user = User.authenticate(params[:email], params[:password])
        session[:id] = user.id
        session[:user_id] = user.id
        session[:user_name] = user.name
        redirect_to session[:return_to] || root_url
    else
        flash[:error] = 'Invalid login.'
        redirect_to :action => 'login'
      end
  end
  
  def logout
    reset_session
    session[:id] = nil
    flash[:notice] = "Logged out!"
    redirect_to :action => 'login'
  end
  
  def new
    @user = User.new
  end
  
  def create
    name = params[:user][:name]
    email = params[:user][:email]
    password = params[:user][:password]
    password2 = params[:password2]
    
    if password != password2 then
      flash[:notice] = "Passwords does not match."
      redirect_to :action => 'new'
    end
    
    @user = User.new
    @user.name = name
    @user.email = email
    @user.password = password
    @user.save

    session[:id] = @user.id
    session[:user_id] = @user.id
    session[:user_name] = @user.name
    redirect_to root_url
  end
  
  def edit
    @user = User.find(session[:user_id])
  end
  
  def update
    @user = User.find(session[:user_id])
    @user.update_attributes(params[:user])
    flash[:notice] = "User Updated."
    redirect_to :action => 'index'
  end
end