require 'CommonModules/mobisysuihelper_jazz'
require 'fileutils'

class Level2Controller < Rho::RhoController
    include BrowserHelper
  
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
        @level1s = Level1.find( :all, :order => 'sortOrder', :orderdir => 'ASC' )
        @level2_clicked = Level2.find(@params['level2id'])        
        @level1_clicked = Level1.find(@params['level1id'])
        @level2s_level1 = Level2.find(
            :all, 
            :conditions => { 
                {
                    :name => "level1_levelCd", 
                    :op => "IN" 
                } => @params['level1id'] 
            },
            :order => 'sortOrder',
            :orderdir => 'ASC'
        ) 

        @level3s_level2 = Level3.find(
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
        @frameworkCollaterals.each_with_index do |collateral,index|
            @collateralHM[collateral.collateralCd] = collateral
        end

        if @params['level3id'] == nil
            @level3_clicked = @level3s_level2[0] 
        elsif
            @level3_clicked = Level3.find(@params['level3id'])  
        end

        @level4s = Level4.find(
            :all,
            :conditions => { 
                {
                    :name => "level3_levelCd", 
                    :op => "IN" 
                } => @level3_clicked.levelCd 
            } ,
            :order => 'sortOrder',
            :orderdir => 'DESC'
        )

        @level4 = nil
        if @params['level4id'] == nil
            @level4 = @level4s[@level4s.length-1] if @level4s.size >0; 
        elsif
            @level4 = Level4.find(@params['level4id'])  
        end

        if @level4 == nil
            @text_h = @level3_clicked.text_h
            @text_f = @level3_clicked.text_f
        else
            @text_h = @level4.text_h
            @text_f = @level4.text_f
        end

        if @level0
            if @level4 == nil
                render :action => :level2layout, :back => :index
            else              
                if @level4.layout == "1"
                    render :action => :level2layout, :back => :index
                elsif @level4.layout == "2"
                    render :action => :level2hlvlayout, :back => :index
                elsif @level4.layout == "3"
                    render :action => :level2deathlayout, :back => :index
                elsif @level4.layout == "4"
                    redirect '/app/Menu/salesIllustration'
                else
                    render :action => :level2layout, :back => :index
                end
            end            
        else
            redirect :action => :index
        end
    end
end

begin 
    require 'Level2/level2_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'level2_controller_Jazz not included'
end
