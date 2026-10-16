require 'rho/rhocontroller'
require 'helpers/browser_helper'

class Level4Controller < Rho::RhoController
  include BrowserHelper

  # GET /Level4
  def index
    @level4s = Level4.find(:all)
    render :back => '/app'
  end

  # GET /Level4/{1}
  def show
    @level4 = Level4.find(@params['id'])
    if @level4
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Level4/new
  def new
    @level4 = Level4.new
    @level3s = Level3.find(:all)
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Level4/{1}/edit
  def edit
    @level4 = Level4.find(@params['id'])
    @level3s = Level3.find(:all)
    if @level4
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Level4/create
  def create
    @level4 = Level4.create(@params['level4'])
    redirect :action => :index
  end

  # POST /Level4/{1}/update
  def update
    @level4 = Level4.find(@params['id'])
    @level4.update_attributes(@params['level4']) if @level4
    redirect :action => :index
  end

  # POST /Level4/{1}/delete
  def delete
    @level4 = Level4.find(@params['id'])
    @level4.destroy if @level4
    redirect :action => :index  
  end
end
