require 'rubygems'
require 'open-uri'
require 'feedzirra'
require 'feedbag'
require 'date'
require 'file_cache'
require 'simple-rss'

class FeedsController < ApplicationController
  #caches_page :index
  
  $DEBUG = true
  
  MAX_FEED_ITEMS = 30
  
  Currentfeed = Struct.new(:feed_url, :feed_title, :title, :url, :published, :summary)

  def index
    @feeds = Feed.order("id ASC")
  end
  
  def front_page
    @feeds = Feed.order("id ASC")
    @mem_feeds = Array.new()
    i = 0
    @feeds.each do |feed|
        logger.debug "################################" if $DEBUG == true
        logger.debug "#                              #" if $DEBUG == true
        logger.debug "################################" if $DEBUG == true
        
        f = fetch_feed(feed, true)
        if f.nil? : next end

        feed_url = get_url(f)
        feed_title = f.title
     
        logger.debug "feed_url: #{feed_url}" if $DEBUG == true
        logger.debug "feed_title: #{feed_title}" if $DEBUG == true
        
        f.entries.each do |item|
            title = item.title + " - " + feed_title
            url = get_url(item)
            published = get_date(item)
            summary   = item.summary
            p = published.split(" ")
            published = "#{p[-1]}-#{p[1]}-#{p[2]}"
            
            a=Date.parse(published)
            b=Date.today
            
            logger.debug "title: #{title}" if $DEBUG == true
            logger.debug "item published  #{published}" if $DEBUG == true
            logger.debug "Break if: #{a} < #{b}" if $DEBUG == true
            #logger.debug "url: #{url}" if DEBUG == true
            #logger.debug "published: #{published}" if DEBUG == true
            #logger.debug "item.dc_date.to_s: #{item.dc_date.to_s}" if DEBUG == true
            #logger.debug "item.pubDate.to_s #{item.pubDate.to_s}" if DEBUG == true
            
            break if a < b #Break if: 2013-08-30 < 2013-08-30
            @mem_feeds[i] = Currentfeed.new(feed_url, feed_title, title, url, published, summary)

            break
        end
        i+=1 unless @mem_feeds[i].nil?
        break if i>=MAX_FEED_ITEMS
     end
     render :partial => 'front_page'
  end
  
  def show
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = fetch_feed(@feedobj, false)
    logger.debug "entries #{@feed.inspect}"
    items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
    @read_later_items = Array.new
    items.each do |i|
      @read_later_items << i.title
    end
    render :partial => 'feed'
  end
  
  def show_feed_ajax
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = fetch_feed(@feedobj, false)
    logger.debug "entries #{@feed.inspect}"
    items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
    @read_later_items = Array.new
    items.each do |i|
      @read_later_items << i.title
    end
    render :partial => 'feed'
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
    flash[:notice] = "Ambulancia Eliminada."
    redirect_to :action => 'index'
  end
  
  private
  def fetch_feed(feed, cache)
      feed_url = feed.url
          
      if cache == true then
          cache_file = feed_url.gsub(/[^a-zA-Z0-9 ]/, '_') 
          cache_file = "cache/#{cache_file}.xml"
          
          logger.debug "Getting feed cache" if $DEBUG == true
          logger.debug "cache file: #{cache_file}" if $DEBUG == true
          
          begin
            file_cache = FileCache.new(feed.url, cache_file, 10)
            content = file_cache.get_api_cache
                    
            start_time = Time.now
          
            f = SimpleRSS.parse(content)
          rescue Exception => e
            return nil
          end
      else
          start_time = Time.now
          logger.debug "Getting feed without cache" if $DEBUG == true
          begin
            f = Feedzirra::Feed.fetch_and_parse(feed.url)
          rescue Exception => e
            return nil
          end
      end
      
      
      end_time = Time.now
      transaction_time = (end_time - start_time)
      logger.debug "Transaction Time (Feedzirra::Feed.parse) #{transaction_time} - #{feed.name}" if $DEBUG == true
      
      return f
  end
  
  def get_url(feed)
    if defined? feed.url
      url = feed.url
    elsif defined? feed.link
      url = feed.link
    else 
      url = ''
    end
    return url
  end
  
  def get_date(feed)
    if feed.dc_date
      published = feed.dc_date.to_s
    elsif  feed.pubDate
      published = feed.pubDate.to_s
    elsif feed.published
      published = feed.published.to_s
    else 
      published = ''
    end
    return published
  end
end
