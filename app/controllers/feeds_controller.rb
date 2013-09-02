require 'rubygems'
require 'open-uri'
require 'feedzirra'
require 'feedbag'
require 'date'
require 'file_cache'
require 'simple-rss'
require 'feeds_handler'

class FeedsController < ApplicationController
  #caches_page :index
  
  $DEBUG = true
  
  $cache_status_file = "cache/last_update_1"
  $update_interval = 360
  #$cache_status_file = "cache/last_update_#{session[:user_id]}"
  
  #Currentfeed = Struct.new(:feed_url, :feed_title, :title, :url, :published, :summary)

  def index
    session[:user_id] = 1 #todo: implement login 
    @feeds = Feed.get_user_feeds()
    # view index javascript call to feeds/front_page
  end
  
  def front_page
    Rails.logger.debug "Front Page..." if $DEBUG == true
    if FeedsHandler.cache_needs_update($cache_status_file, $update_interval) then
        FeedsHandler.update_front_page_cache()
    end
    
    Rails.logger.debug "Cache up to date, fetting feeds from DB..." if $DEBUG == true
    @mem_feeds = Item.get_user_items()
    render :partial => 'front_page'
  end
  
  def show
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = FeedsHandler.fetch_feed(@feedobj, false)
    items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
    @read_later_items = Array.new
    items.each do |i|
      @read_later_items << i.title
    end
    render :partial => 'feed'
  end
  
  def show_feed_ajax
    self.show()
  end
  
  def new
    @feed = Feed.new
  end
  
  def edit
    @feed = Feed.find(params[:id])
  end
  
  def update
    @feed = Feed.find(params[:id])
    @feed.update_attributes(params[:feed])
    flash[:notice] = "Feed Updated."
    redirect_to :action => 'index'
  end
  
  def create
    params[:feed][:url] = Feedbag.find(params[:feed][:url]).first
    unless params[:feed][:url].nil? or params[:feed][:name].blank? then
        @feed = Feed.new(params[:feed])
        @feed.save
        flash[:notice] = "Feed Created."
        redirect_to :action => 'index'
    else
        flash[:notice] = "Feed URL or Name not valid."
        redirect_to :action => 'new'
    end
  end
  
  def destroy
    Feed.find(params[:id]).destroy
    flash[:notice] = "Feed Deleted."
    redirect_to :action => 'index'
  end
  
end