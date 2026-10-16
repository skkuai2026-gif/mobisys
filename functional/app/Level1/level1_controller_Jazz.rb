require 'CommonModules/mobisysuihelper_jazz'
require 'fileutils'

class Level1Controller < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper
    # GET /Level1/{1}/click
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
                          
        @level1_clicked = Level1.loadObject(@params['level1id'])   

        if @level0.sortOrder == "3"
            puts "in first if"
            if @level1_clicked.sortOrder == "1"
                redirect '/app/Comparator/comparator?id='+@level0.object
            else
                redirect '/app/Collateral/search?id='+@level0.object
            end
        end
            
        @level2s_first = Level2.loadObject(
                            :all, 
                            :conditions => { 
                              {
                                :name => "level1_levelCd", 
                                :op => "IN" 
                              } => @level1_clicked.levelCd
                            } ,
                            :order => 'sortOrder',
                            :orderdir => 'ASC'
                          )     
                          
        @collaterals =  Collateral.loadObject(
                              :all, 
                              :conditions => { 
                                {
                                  :name => "levelCd", 
                                  :op => "IN" 
                                } => @level1_clicked.levelCd
                              } 
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
        
        if @params['level2id'] == nil
          @level2_clicked = @level2s_first[0] 
        elsif
          @level2_clicked = Level2.loadObject(@params['level2id'])  
        end

        if @level2_clicked != nil
            @level2collaterals =  Collateral.loadObject(
                                  :all, 
                                  :conditions => { 
                                    {
                                      :name => "levelCd", 
                                      :op => "IN" 
                                    } => @level2_clicked.levelCd
                                  } 
                                )
                                
            @level3s = Level3.loadObject(
                              :all, 
                              :conditions => { 
                                {
                                  :name => "level2_levelCd", 
                                  :op => "IN" 
                                } => @level2_clicked.levelCd
                              } ,
                              :order => 'sortOrder',
                              :orderdir => 'ASC'
                            )
        end
        
        if @level0
            if @level0.layout == "1"
                if @level1_clicked.layout == "1"
                    render :action => :level1layout_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
                elsif @level1_clicked.layout == "2"
                    render :action => :level1iconlayout_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
                else
                    render :action => :level1layout_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
                end
            elsif @level0.layout == "2"
                render :action => :level1gridlayout_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
            elsif @level0.layout == "3"
                render :action => :level1listlayout_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
            elsif @level0.layout == "4"
                if @level1_clicked.layout == "1"
                    render :action => :level1bottomlayout_Jazz, :back => url_for(:action => :index)
                elsif @level1_clicked.layout == "2"
                    render :action => :level1toplayout_Jazz, :back => url_for(:action => :index)
                else
                    render :action => :level1toplayout_Jazz, :back => url_for(:action => :index)
                end
            else
                render :action => :level1layout_Jazz, :back => url_for(:action => :index), :layout => :jazzLayout
            end
        else
            redirect :action => :index
        end
    end
end
