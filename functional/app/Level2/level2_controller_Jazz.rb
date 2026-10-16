require 'rho/rhocontroller'
require 'helpers/browser_helper'

class Level2Controller < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper

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
        @level1s = Level1.loadObject( :all, :order => 'sortOrder', :orderdir => 'ASC' )
        @level2_clicked = Level2.loadObject(@params['level2id'])        
        @level1_clicked = Level1.loadObject(@params['level1id'])
        @level2s_level1 = Level2.loadObject(
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

        @level3s_level2 = Level3.loadObject(
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
        @frameworkCollaterals.each_with_index do |collateral,index|
            @collateralHM[collateral.collateralCd] = collateral
        end

        if @params['level3id'] == nil
            @level3_clicked = @level3s_level2[0] 
        elsif
            @level3_clicked = Level3.loadObject(@params['level3id'])  
        end

        @level4s = Level4.loadObject(
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
            @level4 = Level4.loadObject(@params['level4id'])  
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
                render :action => :level2layout_Jazz, :back => :index, :layout => :jaazLayout
            else              
                if @level4.layout == "1"
                    render :action => :level2layout_Jazz, :back => :index
                elsif @level4.layout == "2"
                    render :action => :level2hlvlayout_Jazz, :back => :index
                elsif @level4.layout == "3"
                    render :action => :level2deathlayout_Jazz, :back => :index
                elsif @level4.layout == "4"
                    redirect '/app/Menu/salesIllustration'
                else
                    render :action => :level2layout_Jazz, :back => :index
                end
            end            
        else
            redirect :action => :index
        end
    end
end
