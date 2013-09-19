#require 'rubygems'
#require 'open-uri'
#require 'file_cache'
#require 'simple-rss'
require 'feedzirra'
require 'feedbag'
require 'date'
require 'feeds_handler'

class FeedsController < ApplicationController
  before_filter :request_access, :except => [:front_page,:cache_needs_update,:show]
  
  #caches_page :index
  
  $DEBUG = true
  $update_interval = 360
  
  def index
    Rails.logger.debug "################################" if $DEBUG == true
    Rails.logger.debug "#                              #" if $DEBUG == true
    Rails.logger.debug "################################" if $DEBUG == true
    user_id = session[:user_id] or user_id = 15 # world
    $cache_status_file = "cache/last_update_#{user_id}"
    @feeds = Feed.get_user_feeds(user_id)
    # view index javascript call to feeds/front_page
  end
  
  def front_page
    params[:id] ||= nil
    user_id = session[:user_id] or user_id = 15 # world
    
    Rails.logger.debug "Front Page..." if $DEBUG == true
    #if FeedsHandler.cache_needs_update($cache_status_file, $update_interval) then
    
    unless params[:id].nil?  then
        @mem_feeds = FeedsHandler.update_front_page_cache(params[:id].to_i, user_id)
    else
        Rails.logger.debug "Cache up to date, fetting feeds from DB..." if $DEBUG == true
        @mem_feeds = Item.get_user_items(user_id)
    end
    render :partial => 'front_page'
  end
  
  def cache_needs_update
      user_id = session[:user_id] or user_id = 15 # world
      cache_needs_update = FeedsHandler.cache_needs_update($cache_status_file, $update_interval)
      feeds = ''
      if cache_needs_update then
        Rails.logger.debug "Cache needs update, updating..." if $DEBUG == true
        Item.delete_user_items(user_id)
        result = Feed.get_user_feeds(user_id, false)
        feeds = result.join(",")
      end
      result = "#{cache_needs_update.to_s}|#{feeds}"
      render :text => result
  end
  
  def show
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = FeedsHandler.fetch_feed(@feedobj, false)
    
    unless session[:id].nil? 
      items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
      @read_later_items = Array.new
      items.each do |i|
        @read_later_items << i.title
      end
    end
    
    render :partial => 'feed'
  end
  
  def show_feed_ajax
    self.show()
  end
  
  def new
    @feed = Feed.new
    @recommended_feeds = RecommendedFeed.all
  end
  
  def edit
    @feed = Feed.find(params[:id])
  end
  
  def modify
    @feeds = Feed.get_user_feeds(session[:user_id])
  end
  
  def update
    @feed = Feed.find(params[:id])
    @feed.update_attributes(params[:feed])
    flash[:notice] = "Feed Updated."
    redirect_to :action => 'modify'
  end
  
  def create
    name = params[:feed][:name]
    url = params[:feed][:url]
    
    if name.blank? then
      flash[:error] = "You must provide a name."
      redirect_to :action => 'new'
      return
    end
    
    if url.blank? then
      flash[:error] = "You must provide a url. It can be either the RSS link or the URI of the page"
      redirect_to :action => 'new'
      return
    end
        
    url = Feedbag.find(url).first
    if url.nil? then
      flash[:error] = "Feed cannot be aggregated."
      redirect_to :action => 'new'
      return
    end
    
    begin   
      @feed = Feed.new(params[:feed])
      @feed.user_id = session[:user_id]
      @feed.save
      flash[:notice] = "Feed Aggregated."
      redirect_to :action => 'index'
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :action => 'new'
    end
  end
  
  def destroy
    Feed.find(params[:id]).destroy
    flash[:notice] = "Feed Deleted."
    redirect_to :action => 'modify'
  end
  
end