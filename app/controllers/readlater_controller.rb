class ReadlaterController < ApplicationController
  def index
    @items = Readlateritem.all
  end
  
  def create
    @item = Readlateritem.new(params[:readlater])
    @item.save
    flash[:notice] = "Item added to read later list."
    redirect_to "/lire/feeds/#{params[:readlater][:feed_id]}\##{params[:feed_item_id]}"
  end
  
  def destroy
    Readlateritem.find(params[:id]).destroy
    flash[:notice] = "item deleted from read later list."
    redirect_to :action => 'index'
  end
end
