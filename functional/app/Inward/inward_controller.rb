require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Inward/inward_b_o'
require 'date'

class InwardController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper
  
  # GET /Inward
  def index
    @inwards = Inward.find(:all)
    render :back => '/app'
  end

  # GET /Inward/search 
  def search
    @searchValue = "%"+@params['search']+"%" if @params['search']
      
    @inwards = Inward.loadObject(
                                   :all,
                                   :conditions => {
                                          { 
                                            :name => 'receiptRefNum',
                                            :op => 'LIKE'
                                          } => @searchValue
                                        }
                                   )
    render :action => :index, :back => '/app/Menu/receipting'
  end

  # GET /Inward/captureReceipt
  def captureReceipt 
    
    @inward = Inward.new
    @inwardDetails = @inward.InwardDetailList
    render :action => :captureReceipt, :back => '/app/Menu/receipting'
  end
  
  def tabdemo
    renderTabbar()
  end

  def execute
  
    saveValidate(@params)  
    
    redirect :action => :show, :query => {"msg" => @msg, "errors" => @errors}, :id => @inward.object
  end

  def saveValidate(params)

    @inward = MobiSys::BrowserHelper.convertToObject('Inward', params['Inward'])

    if true
          
      ########################################
      # check duplicate receiptRefNum
      ########################################
      receiptRefNum = @inward.receiptRefNum
      guid = @inward.guid    
      userId = $userId
      userId = "" if $userId == nil 
        
      sql = "Select * from inward where receiptRefNum = '"<<receiptRefNum<<"' and userId = '"<<userId<<"';"
      puts "SQL: " << sql
      fetchedInwards = Inward.find_by_sql(sql)
      
      if fetchedInwards != nil and fetchedInwards.size > 0
        fetchedInward = fetchedInwards[0] 
      end
      
      if guid != nil # old guid
        if fetchedInward != nil # old SI 
          if fetchedInward.guid.to_s != guid.to_s # old guid, old SI => (1)
            
            puts "**************old guid, old SI, overwrite*****************"
            #overwrite
            @inward.object = fetchedInward.object
            @inward.guid = fetchedInward.guid
  
            inwardDetails = @inward.InwardDetailList
            # overwrite inwardDetails
            inwardDetails.each do |inwardDetail|
              fetchedInwardDetail = searchInwardDetailByNum(fetchedInward, inwardDetail.refVoucherNo)
              if fetchedInwardDetail != nil
                inwardDetail.object = fetchedInwardDetail.object
                inwardDetail.guid = fetchedInwardDetail.guid
                fetchedInwardDetail.delete
              end
            end 
            
            fetchedInward.delete
            
          else # old guid, old SI => resave
            #new
            puts "**************old guid, old SI, resave*****************"
            #do nothing special
                      
          end
        else # old guid, new SI
          #new
          puts "**************old guid, new SI, create new*****************"
          
          inward = Inward.new
          inwardDetails = @inward.InwardDetailList
          @inward.object = inward.object
          @inward.guid = inward.object
          
          inwardDetails.each do |inwardDetail|
            newInwardDetail = InwardDetail.new
            inwardDetail.object = newInwardDetail.object
            inwardDetail.guid = newInwardDetail.object      
          end 
          
          @inward.setInwardDetailList(inwardDetails)        
        end
        
      else # new guid
        if fetchedInward != nil # old SI
          
          puts "**************new guid, old SI, overwrite*****************"
          #overwrite
          @inward.object = fetchedInward.object
          @inward.guid = fetchedInward.guid

          inwardDetails = @inward.InwardDetailList
          # overwrite inwardDetails
          inwardDetails.each do |inwardDetail|
            fetchedInwardDetail = searchinwardDetailByNum(fetchedInward, inwardDetail.refVoucherNo)
            if fetchedInwardDetail != nil
              inwardDetail.object = fetchedInwardDetail.object
              inwardDetail.guid = fetchedInwardDetail.guid
              fetchedInwardDetail.delete
            end
          end 
          
          fetchedInward.delete
          
        else
          puts "**************new guid, new SI, save*****************"
            
        end
      end # if guid is nil then new record
      
      ########################################
      # end check duplicate quotationRefNum
      ########################################

    end
        
    #actions with inwardDetail
    @inward.InwardDetailList.each do |inwardDetail|
      inwardDetail.instrumentDt = getDBDate(inwardDetail.instrumentDt) if inwardDetail.instrumentDt != nil && inwardDetail.instrumentDt != ""  
    end
    
    @inward.inwardDt = Time.now 
    
    @msg = ""
    @errors = Hash.new
    isValidated = MobiSys::InwardBO.validate(@inward, @msg, @errors)
    
    if !isValidated
      @msg << "ERROR"
      @inward.inwardStatusCd = MobiSys::InwardBO::PENDING
    else
      @msg << "SUCCESS"
      @inward.inwardStatusCd = MobiSys::InwardBO::READYFORSYNC
    end
    
    @inward.persistAll
    
  end
  
  # GET /Inward/{1}
  def show
    id = @params['id'][1..-1].chop
    @errors = @params['errors']
    @msg = @params['msg']
    @inward = Inward.loadObject(  :first,
                                  :conditions => {
                                      :object => id
                                  }
                                )
                                
    @inwardDetails = @inward.InwardDetailList
    
    if @inward
      render :action => :captureReceipt, :back => '/app/Menu/receipting'
    else
      redirect :action => :index
    end
  end

  def addInwardDetail
    inwardObject = @params['inwardObject']
    inwardDetailObjects = @params['inwardDetailObjects']
    
    @inward = Inward.new
    @inward.object = inwardObject
    setObjectCount(@inward, inwardDetailObjects)
    
    @inwardDetail = InwardDetail.new
    render :action => :captureInwardDetail
  end

  # GET /Inward/new
  def new
    @inward = Inward.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Inward/{1}/edit
  def edit
    @inward = Inward.find(@params['id'])
    if @inward
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Inward/create
  def create
    @inward = Inward.create(@params['inward'])
    redirect :action => :index
  end

  # POST /Inward/{1}/update
  def update
    @inward = Inward.find(@params['id'])
    @inward.update_attributes(@params['inward']) if @inward
    redirect :action => :index
  end

  # POST /Inward/{1}/delete
  def delete
    @inward = Inward.find(@params['id'])
    @inward.destroy if @inward
    redirect :action => :index  
  end
  
def searchInwardDetailByNum(fetchedInward, refVoucherNo)
    sql = "Select * from InwardDetail where parentKey = '"<<fetchedInward.guid<<"' and refVoucherNo = '"<<refVoucherNo<<"';"
    puts "SQL: " << sql
    fetchedInwards = InwardDetail.find_by_sql(sql)
    
    if fetchedInwards != nil
      return fetchedInwards[0]
    else
      return nil
    end
  end
end
