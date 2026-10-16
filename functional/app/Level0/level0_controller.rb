require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/syncmodule'

class Level0Controller < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper

    # GET /Level0/exit
    def exit        
        System.exit
        render :action => '/app/loading.html'
    end
  
    # GET /Level0/demoapp
    def demoapp
        render :action => :demoapp
    end
      
    # GET /Level0/entrypoint
    def entrypoint      
        MobiSys::Sync.checkCollateralVersion
        if $syncCollateral
            redirect :controller => :SyncCategory , :action =>:syncPreferences
        else
            renderToolbar(1)
            level0Array = AgentReg.getCurrentAgentReg().collateralLevelCd ? AgentReg.getCurrentAgentReg().collateralLevelCd.split(",") : []
            @level0s = Level0.find(:all, :conditions => {
                                    {
                                      :name => "levelCd",
                                      :op => "IN"
                                    } => level0Array
                                  },
                                  :order => 'sortOrder',
                                  :orderdir => 'ASC'
                                )
            @level1s = Level1.find(:all, :order => 'sortOrder', :orderdir => 'ASC')
            @level0_item = @level0s[0] if @level0s.size > 0
          
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
            render :action => :entrypoint, :back => url_for(:action => :index) 
        end
    end
   
    # GET /Level0/{1}/click
    def click      
        @level0 =  Level0.find(@params['id'])
        level0Array = AgentReg.getCurrentAgentReg().collateralLevelCd ? AgentReg.getCurrentAgentReg().collateralLevelCd.split(",") : []
            @level0s = Level0.find(
                        :all,
                        :conditions => {
                            {
                            :name => "levelCd",
                            :op => "IN"
                            } => level0Array
                        },
                        :order => 'sortOrder',
                        :orderdir => 'ASC'
                      )
        @level1s = Level1.find(
                  :all,
                  :order => 'sortOrder',
                  :orderdir => 'ASC'
                )
     
        @level1s_level0 = Level1.find(
                          :all, 
                          :conditions => { 
                            {
                              :name => "level0_levelCd", 
                              :op => "IN" 
                            } => @level0.levelCd 
                          } ,                              
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

                        
        if @level0
            if @level0.landingPage == "1"
                render :action => :level0tilelanding, :back => url_for(:action => :index)
            elsif @level0.landingPage == "2"
                redirect '/app/Comparator/comparator?id='+@level0.object
                return
            else
                render :action => :entrypoint, :back => url_for(:action => :index)
            end
        else
            redirect :action => :index
        end
    end
end

begin 
    require 'Level0/level0_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'level0_controller_Jazz not included'
end