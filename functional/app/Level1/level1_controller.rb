require 'rho/rhocontroller'
require 'helpers/browser_helper'

class Level1Controller < Rho::RhoController
    include BrowserHelper

    # GET /Level1/{1}/click
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
                          
        @level1_clicked = Level1.find(@params['level1id'])   

        if @level0.sortOrder == "3"
            puts "in first if"
            if @level1_clicked.sortOrder == "1"
                redirect '/app/Comparator/comparator?id='+@level0.object
            else
                redirect '/app/Collateral/search?id='+@level0.object
            end
        end
            
        @level2s_first = Level2.find(
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
                          
        @collaterals =  Collateral.find(
                              :all, 
                              :conditions => { 
                                {
                                  :name => "levelCd", 
                                  :op => "IN" 
                                } => @level1_clicked.levelCd
                              } 
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
        
        if @params['level2id'] == nil
          @level2_clicked = @level2s_first[0] 
        elsif
          @level2_clicked = Level2.find(@params['level2id'])  
        end

        if @level2_clicked != nil
            @level2collaterals =  Collateral.find(
                                  :all, 
                                  :conditions => { 
                                    {
                                      :name => "levelCd", 
                                      :op => "IN" 
                                    } => @level2_clicked.levelCd
                                  } 
                                )
                                
            @level3s = Level3.find(
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
                    render :action => :level1layout, :back => url_for(:action => :index)
                elsif @level1_clicked.layout == "2"
                    render :action => :level1iconlayout, :back => url_for(:action => :index)
                else
                    render :action => :level1layout, :back => url_for(:action => :index)
                end
            elsif @level0.layout == "2"
                render :action => :level1gridlayout, :back => url_for(:action => :index)
            elsif @level0.layout == "3"
                render :action => :level1listlayout, :back => url_for(:action => :index)
            elsif @level0.layout == "4"
                if @level1_clicked.layout == "1"
                    render :action => :level1bottomlayout, :back => url_for(:action => :index)
                elsif @level1_clicked.layout == "2"
                    render :action => :level1toplayout, :back => url_for(:action => :index)
                else
                    render :action => :level1toplayout, :back => url_for(:action => :index)
                end
            else
                render :action => :level1layout, :back => url_for(:action => :index)
            end
        else
            redirect :action => :index
        end
    end
end

begin 
    require 'Level1/level1_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'level1_controller_Jazz not included'
end
