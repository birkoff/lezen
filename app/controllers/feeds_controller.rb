#require 'rss'
#require 'rss/2.0'
#require 'rss/content'
#require 'open-uri'
require 'feedzirra'


class FeedsController < ApplicationController
  def index
    @feeds = Feed.all
  end
  
  def show
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = Feedzirra::Feed.fetch_and_parse(@feedobj.url)
    items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
    @read_later_items = Array.new
    items.each do |i|
      @read_later_items << i.title
    end
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
    @feed = Feed.new(params[:feed])
    @feed.save
    flash[:notice] = "Feed Created."
    redirect_to :action => 'index'
  end
  
  def destroy
    Feed.find(params[:id]).destroy
    flash[:notice] = "Ambulancia Eliminada."
    redirect_to :action => 'index'
  end
end
