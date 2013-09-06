require 'rubygems'
require 'open-uri'
require 'feedzirra'
require 'feedbag'
require 'date'
require 'file_cache'
require 'simple-rss'
require 'feeds_handler'

class FeedsController < ApplicationController
  before_filter :authenticate
  #caches_page :index
  
  $DEBUG = true
  $update_interval = 360
  
  def index
    Rails.logger.debug "################################" if $DEBUG == true
    Rails.logger.debug "#                              #" if $DEBUG == true
    Rails.logger.debug "################################" if $DEBUG == true
    $cache_status_file = "cache/last_update_#{session[:user_id]}"
    @feeds = Feed.get_user_feeds(session[:user_id])
    # view index javascript call to feeds/front_page
  end
  
  def front_page
    params[:id] ||= nil
    
    Rails.logger.debug "Front Page..." if $DEBUG == true
    #if FeedsHandler.cache_needs_update($cache_status_file, $update_interval) then
    
    unless params[:id].nil?  then
        @mem_feeds = FeedsHandler.update_front_page_cache(params[:id].to_i, session[:user_id])
    else
        Rails.logger.debug "Cache up to date, fetting feeds from DB..." if $DEBUG == true
        @mem_feeds = Item.get_user_items(session[:user_id])
    end
    render :partial => 'front_page'
  end
  
  def cache_needs_update
      cache_needs_update = FeedsHandler.cache_needs_update($cache_status_file, $update_interval)
      feeds = ''
      if cache_needs_update then
        Rails.logger.debug "Cache needs update, updating..." if $DEBUG == true
        Item.delete_user_items(session[:user_id])
        result = Feed.get_user_feeds(session[:user_id], false)
        feeds = result.join(",")
      end
      result = "#{cache_needs_update.to_s}|#{feeds}"
      render :text => result
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
        @feed.user_id = session[:user_id]
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