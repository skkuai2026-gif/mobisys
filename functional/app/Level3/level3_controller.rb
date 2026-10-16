require 'rho/rhocontroller'
require 'helpers/browser_helper'

class Level3Controller < Rho::RhoController
  include BrowserHelper

  # GET /Level3
  def index
    @level3s = Level3.find(:all)
    render :back => '/app'
  end

  # GET /Level3/{1}
  def show
    @level3 = Level3.find(@params['id'])
    if @level3
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Level3/new
  def new
    @level3 = Level3.new
    @level2s = Level2.find(:all)
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Level3/{1}/edit
  def edit
    @level3 = Level3.find(@params['id'])
    @level2s = Level2.find(:all)
    if @level3
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Level3/create
  def create
    @level3 = Level3.create(@params['level3'])
    redirect :action => :index
  end

  # POST /Level3/{1}/update
  def update
    @level3 = Level3.find(@params['id'])
    @level3.update_attributes(@params['level3']) if @level3
    redirect :action => :index
  end

  # POST /Level3/{1}/delete
  def delete
    @level3 = Level3.find(@params['id'])
    @level3.destroy if @level3
    redirect :action => :index  
  end
end
