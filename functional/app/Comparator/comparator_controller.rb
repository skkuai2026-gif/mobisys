require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ComparatorController < Rho::RhoController
  include BrowserHelper
  
  def click
    
    @fileName = @params['fileName'];
      
    collateral = Collateral.find(
                                      :all, 
                                      :conditions => { 
                                        {
                                          :name => "collateralCd", 
                                          :op => "IN" 
                                        } => @fileName
                                      } 
                                    )
    if collateral.size > 0
      if collateral[0].colStatus == 'PRESEEDED'
        @mediaName = File.join(Rho::RhoApplication.get_base_app_path(),collateral[0].fileName)
      else
        @mediaName = collateral[0].fileName
      end
    end
       
    @constructedURL = @mediaName
    puts @constructedURL
    
    System.open_url @constructedURL
    
  end

  def comparator
      @level0 =  Level0.find(@params['id'])
      @level0s = Level0.find(
                  :all,
                  :order => 'sortOrder',
                  :orderdir => 'ASC'
                )
      @level1s = Level1.find(
                  :all,
                  :order => 'sortOrder',
                  :orderdir => 'ASC'
                )
                
      @frameworkCollaterals =  Collateral.find(
                                  :all, 
                                  :conditions => { 
                                    {
                                      :name => "levelCd", 
                                      :op => "IS" 
                                    } => nil
                                  } 
                                )
                                                       
      @collateralHM = {}
        
      @frameworkCollaterals.each_with_index{|collateral,index|
        @collateralHM[collateral.collateralCd] = collateral
      }
  
      @comparators = Comparator.find(:all)
      render :action => :comparator
  end

  
  # GET /Comparator
  def index
    @comparators = Comparator.find(:all)
    render :back => '/app'
  end

  # GET /Comparator/{1}
  def show
    @comparator = Comparator.find(@params['id'])
    if @comparator
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Comparator/new
  def new
    @comparator = Comparator.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Comparator/{1}/edit
  def edit
    @comparator = Comparator.find(@params['id'])
    if @comparator
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Comparator/create
  def create
    @comparator = Comparator.create(@params['comparator'])
    redirect :action => :index
  end

  # POST /Comparator/{1}/update
  def update
    @comparator = Comparator.find(@params['id'])
    @comparator.update_attributes(@params['comparator']) if @comparator
    redirect :action => :index
  end

  # POST /Comparator/{1}/delete
  def delete
    @comparator = Comparator.find(@params['id'])
    @comparator.destroy if @comparator
    redirect :action => :index  
  end
end
