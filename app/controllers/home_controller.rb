class HomeController < ApplicationController
  
  
  def index
    unless session[:id].nil?
      redirect_to :controller => 'feeds', :action => 'index'
    end
    
    Rails.logger.debug "################################" if $DEBUG == true
    Rails.logger.debug "################################" if $DEBUG == true
    
    user_id = 15 # world
    @user = User.new
    $cache_status_file = "cache/last_update_#{user_id}"
    @feeds = Feed.get_user_feeds(user_id)
    # view index javascript call to feeds/front_page
    # render :template => "feeds/index"
  end

  def about
  end

  def help
  end

  def feeds
  end
end
