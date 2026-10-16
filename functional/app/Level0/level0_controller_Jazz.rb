require 'CommonModules/mobisysuihelper_jazz'
require 'fileutils'

class Level0Controller < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper
   
    # GET /Level0/entrypoint
    def entrypoint      
        MobiSys::Sync.checkCollateralVersion
        if $syncCollateral
            redirect :controller => :SyncCategory , :action =>:syncPreferences
        else
            level0Array = AgentReg.getCurrentAgentReg().collateralLevelCd ? AgentReg.getCurrentAgentReg().collateralLevelCd.split(",") : []
            @level0s = Level0.loadObject(:all, :conditions => {
                                    {
                                      :name => "levelCd",
                                      :op => "IN"
                                    } => level0Array
                                  },
                                  :order => 'sortOrder',
                                  :orderdir => 'ASC'
                                )
            @level1s = Level1.loadObject(:all, :order => 'sortOrder', :orderdir => 'ASC')
            @level0_item = @level0s[0] if @level0s.size > 0
          
            @frameworkCollaterals =  Collateral.loadObject(
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
            render :action => :entrypoint_Jazz, :layout => :jazzLayout
        end
    end

    def click      
        @level0 =  Level0.loadObject(@params['id'])
        level0Array = AgentReg.getCurrentAgentReg().collateralLevelCd ? AgentReg.getCurrentAgentReg().collateralLevelCd.split(",") : []
            @level0s = Level0.loadObject(
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
        @level1s = Level1.loadObject(
                  :all,
                  :order => 'sortOrder',
                  :orderdir => 'ASC'
                )
     
        @level1s_level0 = Level1.loadObject(
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
        @frameworkCollaterals =  Collateral.loadObject(
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
                render :action => :level0tilelanding_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
            elsif @level0.landingPage == "2"
                redirect '/app/Comparator/comparator?id='+@level0.object
                return
            else
                render :action => :entrypoint_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
            end
        else
            redirect :action => :index
        end
    end
end
