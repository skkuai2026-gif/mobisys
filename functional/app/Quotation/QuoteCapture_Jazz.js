/*---------------Document ready function start---------------*/
var currentSlickIndex = 0;
$(document).ready(function () {
    if($('#sym_current_Tab').val()=="tab_basic") {
        tab_basic_pageTabLoaded();
    }
    
    $("a[href= '/app/Quotation/viewIllustration']").on("click",function(){
        if($('#sym_current_Tab').val()=="tab_selProduct"){
            if (!submitValidate()){
                event.preventDefault();
                event.stopPropagation();
                return false;
            }
        }
        viewIllustration();
        return false; // to prevent href redirect
    });
    
    initialFormSerialized = '';
    if($("#quotation_quotationRefNum").val()!=''){
        initialFormSerialized = $('#sales_illustration_form').serialize();
    }

    if($("#additionalOptionsFl").val()=="false"){
        $(".quicklink,.quicklink-details").hide();
    }
    else{
        $(".quicklink-details").hide();
    }
    hideShowQuickLinkIcon();
    if (typeof window["attachMaskAll"] === "function") {
        attachMaskAll();
    }

});

function showSummaryPopup(){
    if($('#sym_current_Tab').val()=="tab_selProduct"){
            if (!submitValidate()){
                event.preventDefault();
                event.stopPropagation();
                return false;
            }
        }
        $('input[id*="_riderDetails_selected"][type!="hidden"]').checkboxradio().checkboxradio('enable');
        $('select').selectmenu().selectmenu('enable');
        $('input').removeAttr("disabled");  
        $('input').removeAttr("readonly");  
        $('input[type= "radio"]').attr("disabled", false);
        $.ajax({
            url: "/app/Quotation/summarypopup",
            data: { 'form': $('#sales_illustration_form').serializeHash() },
            async: false,
            headers: {'Transition-Enabled': false},
            success: function(data){
                if (data!=""){
                    $("div[data-role='page']").css('overflow', 'hidden');
                    window.scrollTo(0, 0);
                    $(this).simpledialog2({
                        mode : 'blank',
                        themeDialog: 'a',
                        blankContent : data
                    });
                    // $('.ui-simpledialog-container').css('max-height',"70vh");
                    $(".quicklink-details").hide();
                }
                else{
                    submitTabForm($('#sym_current_Tab').val());
                }
            }
        });
}

function showLinkFNAPopup(){
    if ($("#linkToFNAPopup").length != 0) {
            $("#linkToFNAPopup").show();
            $('.product-selection-wrapper').css('z-index', 100);
            $(this).simpledialog2({
                mode : 'blank',
                themeDialog: 'a',
                blankContent : $("#linkToFNAPopup")
            });
        } else {
            showDialog('', getLabelValue('NO_RECORDS'), 'error', 0, '');
        }
}

    
function summaryPopupClose() {
    if($('#quotation_quoteStatusCd').val()=='ACCEPTED' || $('#quotation_quoteStatusCd').val()=='SYNCDONE'){
        disableAllFormFields();
    }
    else{
        submitTabForm($('#sym_current_Tab').val());
    }
}

function hideShowPremiumSummaryLink(){
    if($("#quotation_quotationRefNum").val()!=''){
        if  ($('#quotation_quoteStatusCd').val() =='COMPLETED' ||  $('#quotation_quoteStatusCd').val() =='ACCEPTED' ||  $('#quotation_quoteStatusCd').val() =='SYNCDONE'){
            $(".quicklink-details, .quicklink").show();
            $("#quicklink_premiumSummary, #quicklink_VIEWILLUSTRATION").show();
        }
        else{
            $("#quicklink_premiumSummary, #quicklink_VIEWILLUSTRATION").hide();
        }
        hideShowQuickLinkIcon();
        
    }
    else{
        $("#quicklink_premiumSummary, #quicklink_VIEWILLUSTRATION").hide();
    }  
}

//Method to disable / readonly all elements if quotation is ACCEPTED or SYNCDONE
function disableAllIfAccepted(){
    if($('#quotation_quoteStatusCd').val()=='ACCEPTED' || $('#quotation_quoteStatusCd').val()=='SYNCDONE'){
        disableAllFormFields();
    }
}

function submitForm(currentTab) {
    if($("#quotation_quotationRefNum").val() ==''){ 
        initialFormSerialized = '';
    }
    if ($(".slider-nav .is-active").length > 0){
        currentSlickIndex = parseInt($(".slider-nav .is-active").attr('data-slick-index'));
    }
    return true;
}

function tab_selProduct_pageTabLoaded(){
    hideShowPremiumSummaryLink();
    disableAllIfAccepted();
}

function tab_basic_pageTabLoaded(){
    primaryQuotationParty_relationCd_func();
    proposerQuotationParty_relationCd_func();
    jointLifeQuotationParty_relationCd_func();

    primaryQuotationParty_title_func();
    proposerQuotationParty_title_func();
    jointLifeQuotationParty_title_func();

    quotation_jointLife_func(document.getElementById("quotation_jointLife-0"));
    quotation_proposerLASame_load();
    proposerQuotationParty_partyTypeCd_load();
    
    var primary_natureOfDuty = document.querySelector('select#primaryQuotationParty_natureOfDuty');
    primaryQuotationParty_natureOfDuty_onFocus(primary_natureOfDuty);

    var proposer_natureOfDuty = document.querySelector('select#proposerQuotationParty_natureOfDuty');
    proposerQuotationParty_natureOfDuty_onFocus(proposer_natureOfDuty);
    hideShowPremiumSummaryLink();
    disableAllIfAccepted();
    toggleOnFocus();
    $(".basictop-navarea").fixHeader();
    disableDragging();
}

function tab_supplementary_pageTabLoaded(){
    quotation_jointLife_func(document.getElementById("quotation_jointLife-0"));
    var natureOfDuty = document.querySelectorAll('select[id*="_supplementaryQuotationParty_natureOfDuty"]');
    for(var l = 0; l < natureOfDuty.length; l++)
    {
        supplementaryQuotationParty_natureOfDuty_onFocus(natureOfDuty[l]);
    }
    
    var productPlanOptionCd = document.querySelectorAll('select[id*="supplementaryQuotationParty_productPlanOptionCd"]');
    for(var l = 0; l < productPlanOptionCd.length; l++)
    {
        supplementaryQuotationParty_productPlanOptionCd_onFocus(productPlanOptionCd[l]);
    }

    var title = document.querySelectorAll('select[id*="_supplementaryQuotationParty_title"]');
    for(var j = 0; j < title.length; j++)
    { 
        supplementaryQuotationParty_title_func(title[j]);
    }
    var relationCd = document.querySelectorAll('select[id*="_supplementaryQuotationParty_relationCd"]');
    for(var j = 0; j < relationCd.length; j++){ 
            supplementaryQuotationParty_relationCd_func(relationCd[j]);
        }   
        
    hideShowPremiumSummaryLink();
    disableAllIfAccepted();
    toggleOnFocus();
    $(".basictop-navarea").fixHeader();
}

function tab_plan_pageTabLoaded(){
    quotation_jointLife_func(document.getElementById("quotation_jointLife-0"));
    var premiumSAFl = $('#basePlan_premiumSAFl').val();
    basePlan_productId_onFocus(document.getElementById("basePlan_productId"));
    basePlan_productFamilyCd_onFocus(document.getElementById("basePlan_productFamilyCd"));
    basePlan_productPlanOptionCd_onFocus(document.getElementById("basePlan_productPlanOptionCd"));
    enableDisableFormFields("basePlan_",premiumSAFl, false);
    quotation_withdrawalFl_func();
    quotation_solverTypeCd_func();
    basePlan_currencyCd_func(document.getElementById("basePlan_portfolioModelCd"));
    var topUpAllocSameAsPremAllocFl = document.getElementById("basePlan_topUpAllocSameAsPremAllocFl-0");
    if(topUpAllocSameAsPremAllocFl!= null){
        if(topUpAllocSameAsPremAllocFl.checked){
            $("input[id*='quotationFunds_topupAllocationPerc']").each(function(){
                $(this).attr("readonly","readonly");
            });
        }
        else{
            $("input[id*='quotationFunds_topupAllocationPerc']").each(function(){
                $(this).removeAttr("readonly");
            });
        }
    }
    
    $("input[id*='quotationFunds_removeButton']").each(function(){
        var removeButtonObj = document.getElementById($(this).attr('id'));
        quotationFunds_removeButton_func(removeButtonObj);
    });
    $("#quotationFunds_allocationPerc_lbl").append("<span></span>");
    $("#quotationFunds_topupAllocationPerc_lbl").append("<span></span>");
    updateFundTotal();
    quotation_initialTopupFl_func(document.getElementById("quotation_initialTopupFl-0"));
    quotation_regularTopupFl_func(document.getElementById("quotation_regularTopupFl-0"));
    basePlan_targetFundFl_func(document.getElementById("basePlan_targetFundFl-0"));
    quotation_topupOptionCd_func(document.getElementById("quotation_topupOptionCd"));
    var premiumPayingTerm = $('#premiumPayingTermFacet').val();
    var renderPremiumholidayyear = $('#renderPremiumholidayyear').val();
    var renderRetirementpercent = $('#renderRetirementpercent').val();
    
    var basePlan_allowedCurrency = $('#basePlan_allowedCurrency').val().split(',');
    $('select#basePlan_currencyCd option').each(function(index,currentOption){
        if (index > 0){
            if ($.inArray($(this).val(), basePlan_allowedCurrency) == -1){
                $(this).remove();
            }
        }
    })

    var basePlan_allowedPaymentTypeCd = $('#basePlan_allowedPaymentTypeCd').val().split(',');
    $('select#basePlan_paymentTypeCd option').each(function(index,currentOption){
        if (index > 0){
            if ($.inArray($(this).val(), basePlan_allowedPaymentTypeCd) == -1){
                $(this).remove();
            }
        }
    })

    var basePlan_allowedPaymentFrequencyCd = $('#basePlan_allowedPaymentFrequencyCd').val().split(',');
    $('select#basePlan_paymentFrequencyCd option').each(function(index,currentOption){
        if (index > 0){
            if ($.inArray($(this).val(), basePlan_allowedPaymentFrequencyCd) == -1){
                $(this).remove();
            }
        }
    })

   
    if($('#basePlan_paymentTypeCd').val() == 'SINGLE') {
        $('#basePlan_paymentFrequencyCd').attr('disabled', true).trigger("create");
        $('#basePlan_premiumPayingTerm').attr('disabled', true).trigger("create");
    }

    if (premiumPayingTerm == 'true' ) {
        setReadOnly($('#basePlan_premiumPayingTerm'), true);
    }

    if (renderPremiumholidayyear == 'true'){
        setReadOnly($("#basePlan_premiumHolidayYear"), true);
    }

    if (renderRetirementpercent == 'true'){
        setReadOnly($("#basePlan_retirementPercent"), true);
    }

    var fundCd = document.querySelectorAll('select[id*="_quotationFunds_fundCd"]');
    for(var i = 0; i < fundCd.length; i++){
        quotationFunds_fundCd_onFocus(fundCd[i]);  
    }

    setReadOnlyProductExtraFields(true,"PLAN",'dummy')
    hideShowPremiumSummaryLink();
    disableAllIfAccepted();
    toggleOnFocus();
    $(".basictop-navarea").fixHeader();

}

function tab_rider_pageTabLoaded(){
    if (application_view_mode == "mobile"){
        refreshSlickUiMobile(currentSlickIndex);
        $('.slider-nav .slick-slide.is-active').click();
    }
    quotation_jointLife_func(document.getElementById("quotation_jointLife-0"));
    var ridersProductSeq = document.querySelectorAll('select[id*="_riderDetails_productSeq"]');
    for(var i = 0; i < ridersProductSeq.length; i++){
		riderDetails_productSeq_onFocus(ridersProductSeq[i]);	
    }
    
    var allRidersPartyRoleCds = document.querySelectorAll('select[id*="_riderDetails_insuredPartyRefGuid"]');
    for(var j = 0; j < allRidersPartyRoleCds.length; j++){
        riderDetails_insuredPartyRefGuid_onFocus(allRidersPartyRoleCds[j]);
    }
    
    var ridersPartyRoleCds = document.querySelectorAll('select[id*="_riderDetails_partyRoleCd"]');
    for(var k = 0; k < ridersPartyRoleCds.length; k++){
        riderDetails_partyRoleCd_func(ridersPartyRoleCds[k]);
    }
    
    var ridersPlanOptions = document.querySelectorAll('select[id*="_riderDetails_productPlanOptionCd"]');
    for(var l = 0; l < ridersPlanOptions.length; l++){
        riderDetails_productPlanOptionCd_onFocus(ridersPlanOptions[l]);
    }
    var riders = document.querySelectorAll('[id*="_riderDetails_productSeq"]');
    if($('#riderAutoPopulationReqFlag').val() == "YES" ){
        for(var i = 0; i < riders.length; i++){
            var riderId = riders[i].getAttribute('id');
            var riderPrefix = riderId.replace('_productSeq','');
            var riderPremiumSAFlField = riderId.replace('productSeq','premiumSAFl');
            riderPremiumSAFl = $('#' + riderPremiumSAFlField).val(); 

            if ($('#'+riderPrefix+'_selected-0').is(':checked')){
                $('#'+riderId).parents('tr').find('select').selectmenu().selectmenu('enable');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').removeClass('readonly');
                $('#'+riderId).parents('tr').find('a').removeClass('readonly');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').removeAttr('readonly');
                enableDisableFormFields(riderPrefix + '_',riderPremiumSAFl, true); 
            }
            else{
                $('#'+riderId).parents('tr').find('select').selectmenu().selectmenu('disable');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').addClass('readonly');
                $('#'+riderId).parents('tr').find('a').addClass('readonly');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').attr('readonly','true');
            }
        }
    }
    else{
        for(var i = 0; i < riders.length; i++){
            var riderId = riders[i].getAttribute('id');
            var riderPrefix = riderId.replace('_productSeq','');
            var riderPremiumSAFlField = riderId.replace('productSeq','premiumSAFl');
            riderPremiumSAFl = $('#' + riderPremiumSAFlField).val(); 
            enableDisableFormFields(riderPrefix + '_',riderPremiumSAFl, true);  
        }
    }


    var riderDisableField = document.querySelectorAll('input[id*="_riderDetails_riderDisableField"]');
    for(var i = 0; i < riderDisableField.length; i++){
        selectedId = riderDisableField[i].id.replace('riderDisableField','selected-0') 
        if (riderDisableField[i].value == 'YES'){
            $('#'+selectedId).checkboxradio().checkboxradio('disable');
        }
        else{
            $('#'+selectedId).checkboxradio().checkboxradio('enable');
        }
    }

    setReadOnlyProductExtraFields(true,"RIDER",'dummy');
    hideShowPremiumSummaryLink();
    disableAllIfAccepted();
    loading('hide');
    // on tab load forcefully clicking and opening first accordion
    $('.collapse-panel:first .ui-collapsible-heading-collapsed').click();
    toggleOnFocus();
    $(".basictop-navarea").fixHeader();
}

function getAge(birthDt, fieldId1, fieldId2, fieldId3) {
    var objectField = fieldId1.replace('age','object');
    var partyObject = $('#'+objectField).val();
    age = 0;
    $.ajax({
        url: "/app/Quotation/getAge",
        data: $('#sales_illustration_form').serialize() + '&partyObject='+partyObject,
        async:   false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            var ageData = $.parseJSON(data);
            ageParts = ageData.split("|");
            $('#'+ fieldId1).val(ageParts[0]).change(toggleOnFocus());
            age = ageParts[0];
            try {
                $('#'+ fieldId2).val(ageParts[1]);
                $('#'+ fieldId3).val(ageParts[2]);
            } catch(e){}
        }
    });
    return age;
}

function getDOB(age, fieldId){
    quotationDt = $('#quotation_quotationDt').val();
    $.ajax({
        url: "/app/Quotation/getBirthDt",
        data: $('#sales_illustration_form').serialize() + '&age='+age+ '&quotationDt='+quotationDt,
        async: false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            $('#'+ fieldId).val(data).change(toggleOnFocus());
        }
    });
}


/********* Primary Life related functions *********/
function primaryQuotationParty_dob_func(object){
    roleCd = object.id.replace("dob","roleCd")
    age = object.id.replace("dob","age")
    $('#quotation_currentPartyRole').val($('#'+roleCd).val());
    getAge(object.value, age, '', '');
}

function primaryQuotationParty_age_func(object){
    dob = object.id.replace("age","dob")
    getDOB(object.value, dob);
}

function primaryQuotationParty_industryCd_func() {
    $('select#primaryQuotationParty_natureOfDuty').val('').change();
    $('select#primaryQuotationParty_occupationCd').val('').change();
}

function primaryQuotationParty_natureOfDuty_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#primaryQuotationParty_industryCd').val();
        filterCondition = {'industryCd' : industryCd};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function primaryQuotationParty_occupationCd_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#primaryQuotationParty_industryCd').val();
        natureOfDuty = $('select#primaryQuotationParty_natureOfDuty').val();
        filterCondition = {'industryCd' : industryCd, 'natureOfDuty' : natureOfDuty};
        loadLookupData(lookupkey, filterCondition, id);
    }
}
function primaryQuotationParty_relationCd_func(obj){
    var relation = $('#primaryQuotationParty_relationCd').val();
    if (relation == "OTHER")
    {
        $("#primaryQuotationParty_otherRelation").parents(".project-data").show();
        $("#primaryQuotationParty_otherRelation_lbl").show();
        $("#primaryQuotationParty_otherRelation").show();
    }
    else
    {
        $("#primaryQuotationParty_otherRelation").parents(".project-data").hide();
        $("#primaryQuotationParty_otherRelation").val("");
    }
}

function primaryQuotationParty_title_func(obj){
    var title = $("#primaryQuotationParty_title").val();
    if (title == "OTHER")
    {
        $("#primaryQuotationParty_otherTitle").parents(".project-data").show();
    }
    else
    {
        $("#primaryQuotationParty_otherTitle").parents(".project-data").hide();
        $("#primaryQuotationParty_otherTitle").val("");
    }
}

/********* Proposer Life related functions *********/
function proposerQuotationParty_dob_func(object){
    roleCd = object.id.replace("dob","roleCd")
    age = object.id.replace("dob","age")
    $('#quotation_currentPartyRole').val($('#'+roleCd).val());
    getAge(object.value, age, '', '');
}

function proposerQuotationParty_age_func(object){
    dob = object.id.replace("age","dob")
    getDOB(object.value, dob);
}

function proposerQuotationParty_industryCd_func() {
    $('select#proposerQuotationParty_natureOfDuty').val('').change();
    $('select#proposerQuotationParty_occupationCd').val('').change();
}

function proposerQuotationParty_natureOfDuty_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#proposerQuotationParty_industryCd').val();
        filterCondition = {'industryCd' : industryCd};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function proposerQuotationParty_occupationCd_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#proposerQuotationParty_industryCd').val();
        natureOfDuty = $('select#proposerQuotationParty_natureOfDuty').val();
        filterCondition = {'industryCd' : industryCd, 'natureOfDuty' : natureOfDuty};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function proposerQuotationParty_partyTypeCd_func(object){
    if (object != null){
        inputType = object.type
        var checked = false;
        if (inputType == "radio" &&  $("input:radio[id^='proposerQuotationParty_partyTypeCd']:checked").val() == "ORGANIZATION"){ 
            checked = true;             
        }
        else if (inputType =="select-one" && $("select[id^='proposerQuotationParty_partyTypeCd'] option:selected").val() == "ORGANIZATION"){
            checked = true;
        }
        if (checked){
            $('#ProposerBasic input[type!="radio"][type!="hidden"]:not(input:radio[id^="proposerQuotationParty_partyTypeCd"])').val('');
            $('#ProposerBasic select').val('').change();
            $('#proposerQuotationParty_title').val('MR').change();
            $('#displayProposer input[type=radio]:not(input:radio[id^="proposerQuotationParty_partyTypeCd"])').attr("checked", false).checkboxradio().checkboxradio("refresh");
            $('#ProposerBasic').hide();
            $('#corporate').show(); 
              
            $('#displayPrimary').show();
            $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_genderCd"]').attr('name',$('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_genderCd"]').attr('name').replace('_hid',''));
            $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_genderCd"]').val('');
            $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_smoker"]').attr('name',$('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_smoker"]').attr('name').replace('_hid',''));
            $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_smoker"]').val('');
            $('#displayPrimary input[type!="radio"][type!="hidden"]').val(''); 
            $('#displayPrimary select').val('').change();
            $("#quotation_proposerLASame-0").parents(".project-data").hide();
            if ($("input:checkbox[id^='quotation_proposerLASame']:not([id$='hid'])").is(":checked")){
                $("#quotation_proposerLASame-0").click();
            }
            $('#displayPrimary input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");
        }
        else
        {
            $('#ProposerBasic').show();
            $('#corporate').hide();
            $('#proposerQuotationParty_corporateName').val('');
            $("#quotation_proposerLASame-0").parents(".project-data").show();
            $('#proposerQuotationParty_relationCd').selectmenu('enable');
        }
    }
}
function proposerQuotationParty_partyTypeCd_load(){
    if($("#partyTypeCd").val() == 'ORGANIZATION'){
        $('#ProposerBasic').hide();
        $('#corporate').show();
        $('#displayPrimary').show();
        $("#quotation_proposerLASame-0").parents(".project-data").hide();
        if ($("input:checkbox[id^='quotation_proposerLASame']:not([id$='hid'])").is(":checked")){
            $("#quotation_proposerLASame-0").click();
        }  
    }
    else{
        $('#ProposerBasic').show();
        $('#corporate').hide();
        $("#quotation_proposerLASame-0").parents(".project-data").show();
    }
}

function quotation_proposerLASame_func(object){
    if (object != null){
        inputType = object.type
        var checked = false;
        if ( inputType == "checkbox" && $("input:checkbox[id^='quotation_proposerLASame']:not([id$='hid'])").is(":checked")){
            checked = true;
        }
        else if (inputType == "radio" &&  $("input:radio[id^='quotation_proposerLASame']:not([id$='hid']):checked").val() == "YES"){
            checked = true;
        }
        else if (inputType == "select-one" && $("select[id^='quotation_proposerLASame']:not([id$='hid']) option:selected").val() == "YES"){
            checked = true;
        }
        if (checked){
            $('#displayPrimary').hide();
            $('#proposerQuotationParty_relationCd').val("SELF").change().selectmenu('disable');
        }
        else {
            $('#displayPrimary').show();
            if ($("#proposerQuotationParty_relationCd").val() == "SELF"){
                $('#proposerQuotationParty_relationCd').val('').change().selectmenu('enable');
            }
        }
        $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_genderCd"]').attr('name',$('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_genderCd"]').attr('name').replace('_hid',''));
        $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_genderCd"]').val('');
        $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_smoker"]').attr('name',$('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_smoker"]').attr('name').replace('_hid',''));
        $('#displayPrimary input[type="hidden"][id^="primaryQuotationParty_smoker"]').val('');
        $('#displayPrimary input[type!="radio"][type!="hidden"]').val(''); 
        $('#displayPrimary select').val('').change();
        $('#displayPrimary input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");    
    }    
}

function quotation_proposerLASame_load(){
    if ($("#proposerLASame").val() == "YES"){
        $('#displayPrimary').hide();
        if ($("#proposerQuotationParty_relationCd").val() == "SELF"){
            $('#proposerQuotationParty_relationCd').selectmenu('disable');
        }
    }
    else {
        $('#displayPrimary').show();
    }
}

function proposerQuotationParty_relationCd_func(obj){
    var relation = $('#proposerQuotationParty_relationCd').val();
    if (relation == "OTHER")
    {
         $("#proposerQuotationParty_otherRelation").parents(".project-data").show();
         $("#proposerQuotationParty_otherRelation_lbl").show();
         $("#proposerQuotationParty_otherRelation").show();
    }
    else
    {
        $("#proposerQuotationParty_otherRelation").parents(".project-data").hide();
        $("#proposerQuotationParty_otherRelation").val("");
    }
}

function proposerQuotationParty_title_func(obj){
    var title = $("#proposerQuotationParty_title").val();
    if (title == "OTHER")
    {
        $("#proposerQuotationParty_otherTitle").parents(".project-data").show();
    }
    else
    {
        $("#proposerQuotationParty_otherTitle").parents(".project-data").hide();
        $("#proposerQuotationParty_otherTitle").val("");
    }    

}
/********* Joint Life related functions *********/
function jointLifeQuotationParty_dob_func(object){
    roleCd = object.id.replace("dob","roleCd")
    age = object.id.replace("dob","age")
    $('#quotation_currentPartyRole').val($('#'+roleCd).val());
    getAge(object.value, age, '', '');
}

function jointLifeQuotationParty_age_func(object){
    dob = object.id.replace("age","dob")
    getDOB(object.value, dob);
}

function jointLifeQuotationParty_industryCd_func(object) {
    $('select#jointLifeQuotationParty_natureOfDuty').val('').change();
    $('select#jointLifeQuotationParty_occupationCd').val('').change();
}

function jointLifeQuotationParty_natureOfDuty_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#jointLifeQuotationParty_industryCd').val();
        filterCondition = {'industryCd' : industryCd};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function jointLifeQuotationParty_occupationCd_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#jointLifeQuotationParty_industryCd').val();
        natureOfDuty = $('select#jointLifeQuotationParty_natureOfDuty').val();
        filterCondition = {'industryCd' : industryCd, 'natureOfDuty' : natureOfDuty};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function quotation_jointLife_func(object){
    if(object!= null){
        if(object.checked){
            $("#displayJointLife").show();
            $("#jointLifeQuotationParty_removed").val("");
        }
        else {
            $("#displayJointLife").hide();
            $("#jointLifeQuotationParty_removed").val("YES");
            $('#displayJointLife input[type!="radio"][type!="hidden"][id!="jointLifeQuotationParty_roleCd"]').val(''); 
            $('#displayJointLife select[id!="jointLifeQuotationParty_partyTypeCd"]').val('').change();
            $('#displayJointLife input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh"); 
        }      
    }
    else{
        $("#displayJointLife").hide();
        $("#jointLifeQuotationParty_removed").val("YES");
    }
}

function jointLifeQuotationParty_relationCd_func(obj){
    var relation = $('#jointLifeQuotationParty_relationCd').val();
    if (relation == "OTHER")
    {
       $("#jointLifeQuotationParty_otherRelation").parents(".project-data").show();
       $("#jointLifeQuotationParty_otherRelation_lbl").show();
       $("#jointLifeQuotationParty_otherRelation").show();
    }
    else
    {
        $("#jointLifeQuotationParty_otherRelation").parents(".project-data").hide();
        $("#jointLifeQuotationParty_otherRelation").val("");
    }
}

function jointLifeQuotationParty_title_func(obj){
    var title = $("#jointLifeQuotationParty_title").val();
    if (title == "OTHER")
    {
        $("#jointLifeQuotationParty_otherTitle").parents(".project-data").show();
    }
    else
    {
        $("#jointLifeQuotationParty_otherTitle").parents(".project-data").hide();
        $("#jointLifeQuotationParty_otherTitle").val("");
    }
}

/******** Supplementary Life related functions ********/
function supplementaryQuotationParty_industryCd_func(object) {
    if(object != null){
        natureOfDutyID = object.id.replace("industryCd","natureOfDuty");
        occupationCdID = object.id.replace("industryCd","occupationCd");
        $('select#' + natureOfDutyID).val('').change();
        $('select#' + occupationCdID).val('').change();
    }
}

function supplementaryQuotationParty_natureOfDuty_onFocus(object){
    if (object != null){
        id = object.id;
        industryCdID = id.replace("natureOfDuty","industryCd");
        occupationCdID = id.replace("natureOfDuty","occupationCd");
        lookupkey = object.getAttribute("data-lookupkey");
        var industryCd = $('select#' + industryCdID).val();
        filterCondition = {'industryCd' : industryCd};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function supplementaryQuotationParty_occupationCd_onFocus(object){
    if (object != null){
        id = object.id;
        industryCdID = id.replace("occupationCd","industryCd");
        natureOfDutyID = id.replace("occupationCd","natureOfDuty");
        lookupkey = object.getAttribute("data-lookupkey");
        var industryCd = $('select#' + industryCdID).val();
        var natureOfDuty = $('select#' + natureOfDutyID).val();
        filterCondition = {'industryCd' : industryCd, 'natureOfDuty':natureOfDuty};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function supplementaryQuotationParty_addButton_func(object){
    var supplementLifeCount = parseInt($('#supplementLifeCount').val());
    var supQuotationProductCount = parseInt($('#supQuotationProductCount').val());
    var displayCount = $('#supplementaryQuotationParty_addButton .button-add-section .notification').text();
    $.ajax({
        url: "/app/Quotation/addSupplementLife",
        data: {
            'quotationObject': $('#quotation_object').val(), 
            'supplementLifeCount': supplementLifeCount,
            'supQuotationProductCount':supQuotationProductCount,
            'displayCount':displayCount
        },
        success: function(data) {
            supplementLifeCount = supplementLifeCount + 1;
            $("#supplementLifeCount").val(supplementLifeCount);

            supQuotationProductCount = supQuotationProductCount + 1;
            $("#supQuotationProductCount").val(supQuotationProductCount);
            
            displayCount =  parseInt(displayCount) + 1; 
            $('#supplementaryQuotationParty_addButton .button-add-section .notification').text(displayCount);
            sectionExist = $(".supplementaryQuotationParty-main-class >.collapse-panel>.ui-collapsible");
            if (sectionExist.length > 0){
                $(".supplementaryQuotationParty-main-class > .collapse-panel>.ui-collapsible:last").next('.clearfix').after(data);
            }
            else{
                $(".supplementaryQuotationParty-main-class >.collapse-panel").prepend(data);
            }
            $(".supplementaryQuotationParty-main-class").trigger('create');
            
            supplementaryQuotationParty_title_func(document.getElementById('grid_'+  supplementLifeCount.toString() + "_supplementaryQuotationParty_title"));
            $(".datepicker:not(.inputreadonly)").datepicker({
                showOn: 'focus',
                showButtonPanel: true,
                closeText: 'Clear', 
                changeMonth: true,
                changeYear: true,
                dateFormat: "dd/mm/yy",
                yearRange: "1900:2200",
                onClose: function () {
                var event = arguments.callee.caller.caller.arguments[0];
                    if ($(event.delegateTarget).hasClass('ui-datepicker-close')) {
                        $(this).val('');
                        id = $(this).closest("div").context.id;
                        dob = id.substring(id.lastIndexOf("_"));
                        age = id.replace(dob,"_age");
                        $("#"+age).val("");
                    }
                }
            });
            toggleOnFocus();
            disableDragging();
        }
        
    });
    
}

function supplementaryQuotationParty_removed_func(object){
    deletePopup(object, "DELETE_CONFIRMATION",'supplementary');
}

function deletesupplementary_Callback_func(object){
    var fieldObject = $('#'+object.id).parent().find('input[name*="[guid]"]');
    var objectFieldName = fieldObject.attr('name');
    if(parseInt(objectFieldName.indexOf("[guid]")) > 0)
    {
        var supplementaryObjectName = objectFieldName.substring(0, (objectFieldName.length-6));
        $('input[name="'+supplementaryObjectName+'[removed]"]').val('YES'); 
        $('input[name="'+supplementaryObjectName+'[object]"]').parents('.ui-collapsible').hide();
        
        var displayCount = $('#supplementaryQuotationParty_addButton .button-add-section .notification').text();
        displayCount = parseInt(displayCount) - 1;
        $('#supplementaryQuotationParty_addButton .button-add-section .notification').text(displayCount);
    }
}

function supplementaryQuotationParty_dob_func(object){
    roleCd = object.id.replace("dob","roleCd")
    age = object.id.replace("dob","age")
    $('#quotation_currentPartyRole').val($('#'+roleCd).val());
    getAge(object.value, age, '', '');
}

function supplementaryQuotationParty_age_func(object){
    dob = object.id.replace("age","dob")
    getDOB(object.value, dob);
}

function supplementaryQuotationParty_productPlanOptionCd_onFocus(obj){
    id = obj.id;
    fieldId = id.replace('productPlanOptionCd','productSeq');
    var baseProductSeq = $('#basePlan_productSeq').val();
    lookupkey = obj.getAttribute("data-lookupkey");
    filterCondition = {'productSeq': baseProductSeq};
    loadLookupData(lookupkey, filterCondition, id);
}


function supplementaryQuotationParty_title_func(object){
    if (object != null){
        if (object.value == "OTHER") {
            $("#"+object.id.replace('title','otherTitle')).parents(".project-data").show();
        }
        else{
            $("#"+object.id.replace('title','otherTitle')).val("");
            $("#"+object.id.replace('title','otherTitle')).parents(".project-data").hide(); 
        }
    }
}


function supplementaryQuotationParty_relationCd_func(obj){
    if (obj != null){
        var relation = $('#'+obj.id).val();
        if (relation == "OTHER")
        {
            $('input[id*="_supplementaryQuotationParty_otherRelation"]').parents(".project-data").show();
            $('p[id*="_supplementaryQuotationParty_otherRelation_lbl"]').show();
            $('input[id*="_supplementaryQuotationParty_otherRelation"]').show();
        } 
        else
        {
            $('input[id*="_nomineeParty_otherRelation"]').parents(".project-data").hide();
            $('input[id*="_nomineeParty_otherRelation"]').val("");
        }
    }
}
/********* Plan related functions *********/
function calculateBasePlanValue(object){
    $('#basePlan_productFamilyCd').selectmenu().selectmenu('enable');
    $('#basePlan_productPlanOptionCd').selectmenu().selectmenu('enable');
    $('#basePlan_productId').selectmenu().selectmenu('enable');
    $('#basePlan_paymentFrequencyCd').selectmenu().selectmenu('enable');
    $('#basePlan_premiumPayingTerm').selectmenu().selectmenu('enable');
    $('#basePlan_baseSumAssured').trigger('blur');
    $.ajax({                                    
        url: "/app/Quotation/ajaxCalculateBasePremium",
        data: { 'form': $('#sales_illustration_form').serializeHash()},
        success: function(data) {
            var quotationProduct = JSON.parse(data);
            $.each(quotationProduct, function(key, val) {
                var selectObject = $("select[id='basePlan_"+key+"']");
                if (selectObject.find('option[value="'+val +'"]').length <= 0) {
                    selectObject.append("<option value="+val+">"+val+"</option>");
                }
                selectObject.val(val);
                selectObject.selectmenu('refresh');

                $("input[id='basePlan_"+key+"']").val(val);
                $("input[id='basePlan_"+key+"']").trigger('blur');
                $("input[id='basePlan_"+key+"'][type='radio']").checkboxradio().checkboxradio('refresh');
            });
            var premiumSAFl = $('#basePlan_premiumSAFl').val();
            enableDisableFormFields("basePlan_",premiumSAFl, false);
            $('#basePlan_productFamilyCd').selectmenu().selectmenu('disable');
            $('#basePlan_productPlanOptionCd').selectmenu().selectmenu('disable');
            $('#basePlan_productId').selectmenu().selectmenu('disable');
         }
    });
}

function enableDisableFormFields (idPrefix, premiumSAFl, isRiderFl) {
    if(!isRiderFl)
    {
        $("select#"+idPrefix+'productFamilyCd').selectmenu().selectmenu('disable');
        $("select#"+idPrefix+'productPlanOptionCd').selectmenu().selectmenu('disable');
        $("select#"+idPrefix+'productId').selectmenu().selectmenu('disable');
        if(typeof enablePremiumHolidayFields == 'function'){ enablePremiumHolidayFields(); }
        if(typeof filterOffsetOption == 'function'){ filterOffsetOption(); }
        if(typeof hideOffsetYear == 'function'){ hideOffsetYear(); }
        if(typeof enableAnnuityFields == 'function'){ enableAnnuityFields(); }
        if(typeof enablePrePaymentSection == 'function'){ enablePrePaymentSection(); }
        if(typeof enablePrePaymentFields == 'function'){ enablePrePaymentFields(); }
        if(typeof enableRetirementFields == 'function'){ enableRetirementFields(); }
    }
    setReadOnly($("#"+idPrefix+"maxTargetPremium"), true);
    setReadOnly($("#"+idPrefix+"minTargetPremium"), true);
    setReadOnly($("#"+idPrefix+"recommendedPremium"), true);
    setReadOnly($("#"+idPrefix+"unapliedPremium"), true);
    setReadOnly($("#"+idPrefix+"extraPremium"), true);

    if (premiumSAFl == 'PREMIUM'){
        setReadOnly($("#"+idPrefix+"baseSumAssured"), true);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), true);
        setReadOnly($("#"+idPrefix+"modalPremium"), false);
    }
    else if (premiumSAFl == 'SA'){
        setReadOnly($("#"+idPrefix+"baseSumAssured"), false);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), true);
        setReadOnly($("#"+idPrefix+"modalPremium"), true); 
    }
    else if (premiumSAFl == 'DUAL'){
        setReadOnly($("#"+idPrefix+"baseSumAssured"), false);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), false);
        setReadOnly($("#"+idPrefix+"modalPremium"), true); 
    }
    else if(premiumSAFl == 'ANNUALPREMIUM'){
        setReadOnly($("#"+idPrefix+"baseSumAssured"), true);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), false);
        setReadOnly($("#"+idPrefix+"modalPremium"), true); 
    }
    else if(premiumSAFl == 'COMPUTEDSA'){
        setReadOnly($("#"+idPrefix+"baseSumAssured"), false);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), false);
        setReadOnly($("#"+idPrefix+"modalPremium"), false); 
    }
    else if((premiumSAFl == 'MONTHLYINCOME') || (premiumSAFl == 'ANNUALINCOME')){
        setReadOnly($("#"+idPrefix+"baseSumAssured"), true);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), true);
        setReadOnly($("#"+idPrefix+"modalPremium"), true); 
    }
    else{
        setReadOnly($("#"+idPrefix+"baseSumAssured"), false);
        setReadOnly($("#"+idPrefix+"baseAnnualPremium"), false);
        setReadOnly($("#"+idPrefix+"modalPremium"), false);
    }

    $.each($("#"+idPrefix+"readOnlyFields").val().split(","), function(index, value){
        setReadOnly($("#"+idPrefix+value), true);
        $("select#"+idPrefix+value).selectmenu().selectmenu('disable');
    });
}

function enablePremiumHolidayFields(){
    premiumHolidayFl = $('#basePlan_premiumHolidayFl');
    if (premiumHolidayFl.fieldexists())
    {
        if (premiumHolidayFl.filter(':checked').val() == "YES")
        {
            readonly = false
        }
        else
        {
            readonly = true
            $('#basePlan_premiumHolidayYear').val('');
        }
        setReadOnly($('basePlan_premiumHolidayYear'), readonly)
    }
}

function enableRetirementFields(){
    retirementOptionFl = $('#basePlan_retirementOptionFl');
    if (retirementOptionFl.fieldexists())
    {
        if (retirementOptionFl.filter(':checked').val() == "YES")
        {
            readonly = false;
        }
        else
        {
            readonly = true;
            $('#basePlan_retirementPercent').val('');
        }
        setReadOnly($('#basePlan_retirementPercent'), readonly);
    }
}

function filterOffsetOption(){
    premiumOffsetFl = $('#basePlan_premiumOffsetFl-0');
    if (premiumOffsetFl.fieldexists()) { 
        premiumOffsetOptionCd = '#basePlan_premiumOffsetOptionCd';
        premiumOffsetValues = '#basePlan_premiumOffsetValues';
        if (premiumOffsetFl.filter(':checked').val() == 'YES'){
            option = 1;
            readonly = false;
            menu = 'enable';
        }
        else{
            option = 0;
            readonly = true;
            menu = 'disable';
            value = '';
        }
        if($(premiumOffsetOptionCd).fieldexists()) {
            $(premiumOffsetOptionCd).selectit(option);
        }
        if($(premiumOffsetValues).fieldexists()) {
            $(premiumOffsetValues).selectit(option);
        }

        setReadOnly($('#basePlan_premiumOffsetYear'), readonly);
        $('#basePlan_premiumOffsetYear').val(value);
        $('#basePlan_premiumOffsetValues').selectmenu().selectmenu(menu);
        $('#basePlan_premiumOffsetOptionCd').selectmenu().selectmenu(menu);
    }
}

function hideOffsetYear(){
    premiumOffsetOptionCd = $('#basePlan_premiumOffsetOptionCd');
    if (premiumOffsetOptionCd.fieldexists()){
        if (premiumOffsetOptionCd.val() == 'EARLYOFFSET')
        {
            $('#basePlan_premiumOffsetYear').val(''); 
            $('#basePlan_premiumOffsetYear').closest(".project-data").hide();
        }
        else
        {
            $('#basePlan_premiumOffsetYear').closest(".project-data").show();
        }
    }
}

function enablePrePaymentFields(){
    premiumPayingTerm = $('#basePlan_premiumPayingTerm').val(); 
    solverTypeCd = $('#basePlan_solverTypeCd');
    if (solverTypeCd.fieldexists()){
        if (solverTypeCd.val() == 'NO')
        {
            $('#basePlan_pdfAmount').val('');
            $('#basePlan_pdfFrequencyVal').val('');
            $('#basePlan_pdfPeriod').val(''); 

            setReadOnly($('#basePlan_pdfAmount'), true);
            setReadOnly($('#basePlan_pdfFrequencyVal'), true);
            setReadOnly($('#basePlan_pdfPeriod'), true);
        }
        else if ( solverTypeCd.val() == 'FASOLVER')
        {
            $('#basePlan_pdfFrequencyVal').val('');
            $('#basePlan_pdfPeriod').val(''); 

            setReadOnly($('#basePlan_pdfAmount'), false);
            setReadOnly($('#basePlan_pdfFrequencyVal'), true);
            setReadOnly($('#basePlan_pdfPeriod'), true);

            $('#basePlan_pdfFrequencyVal').val('1'); 
            $('#basePlan_pdfPeriod').val(premiumPayingTerm); 
        }
        else if (solverTypeCd.val() == 'AMOUNTSOLVER')
        {
            $('#basePlan_pdfAmount').val('');
            $('#basePlan_pdfFrequencyVal').val('');

            setReadOnly($('#basePlan_pdfAmount'), true);
            setReadOnly($('#basePlan_pdfFrequencyVal'), false);
            setReadOnly($('#basePlan_pdfPeriod'), false);
            $('#basePlan_pdfFrequencyVal').val('1'); 
            if($('#basePlan_pdfPeriod').val() == ""){
                $('#basePlan_pdfPeriod').val(premiumPayingTerm);  
            }
        }
    }
}

function enableAnnuityFields(){
    annuityOptionCd = $('#basePlan_annuityOptionCd');
    if (annuityOptionCd.fieldexists()){
        if (annuityOptionCd.filter(':checked').val() == "YES")
        {
            annuityPerc = 100;
            readonly = false
        }
        else
        {
            annuityPerc = '';
            $('#basePlan_annuityAge').val(''); 
            readonly = true 
        }
        $('#basePlan_annuityPerc').val(annuityPerc);
        setReadOnly($('#basePlan_annuityAge'), readonly);
        setReadOnly($('#basePlan_annuityPerc'), readonly);
    }
}

function enablePrePaymentSection(){
    pdfRequiredFl = $('[id*="pdfRequiredFl"]');
    premiumPayingTerm = $('#basePlan_premiumPayingTerm').val(); 
    if (pdfRequiredFl.fieldexists()){
        if (pdfRequiredFl.filter(':checked').val() == "YES")
        {
            readonly = false
            pdfReadOnly = true
            $('#basePlan_pdfFrequencyVal').val('1'); 
            if($('#basePlan_pdfPeriod').val() == ""){
                $('#basePlan_pdfPeriod').val(premiumPayingTerm);  
            }
        }
        else
        {
            readonly = true
            pdfReadOnly = true
            $('#basePlan_pdfFrequencyVal').val('');
            $('#basePlan_pdfAmount').val('');
            $('#basePlan_pdfPeriod').val('');
        }
        setReadOnly($('#pdfAmountDiv input'), pdfReadOnly);
        setReadOnly($('#pdfDiv input'), readonly);

        setReadOnly($('#basePlan_pdfAmount'), pdfReadOnly);
        setReadOnly($('#basePlan_pdfFrequencyVal'), readonly);
        setReadOnly($('#basePlan_pdfPeriod'), readonly);
    }
}

function defaultPPTerm(){
    var premiumPayingTerm = $('#premiumPayingTermFacet').val();
    var paymentTypeCd = $('select#basePlan_paymentTypeCd').val();
    var baseProductTerm = $('select#basePlan_productTerm').val();
    if(paymentTypeCd == 'SINGLE') {
        if($('select#basePlan_premiumPayingTerm option[value="1"]').length == 0) {
            $('select#basePlan_premiumPayingTerm').append('<option val="1">1</option>');
        }
        $('#basePlan_paymentFrequencyCd').append('<option value = "SINGLE">'+getLabelValue('SINGLE')+'</option>');
        $('select#basePlan_premiumPayingTerm').val("1").selectmenu("refresh");
        $('select#basePlan_paymentFrequencyCd').val("SINGLE").selectmenu("refresh");

        $('select#basePlan_paymentFrequencyCd').selectmenu('disable');

        $('select#basePlan_premiumPayingTerm').selectmenu('disable');
    }
    else if((paymentTypeCd == 'REGULAR') && (premiumPayingTerm == 'true')) {
        $('select#basePlan_premiumPayingTerm').val(baseProductTerm).selectmenu("refresh");
        $('select#basePlan_premiumPayingTerm').selectmenu('disable');  
        $("#basePlan_paymentFrequencyCd option[value='SINGLE']").remove();     
    }
    else if (paymentTypeCd == 'REGULAR') {
        $('select#basePlan_paymentFrequencyCd').selectmenu('enable');
        $('select#basePlan_premiumPayingTerm').selectmenu('enable');
        $('select#basePlan_paymentFrequencyCd').val("").selectmenu('refresh');
        $('select#basePlan_premiumPayingTerm').val("").selectmenu('refresh');
        $("#basePlan_paymentFrequencyCd option[value='SINGLE']").remove();               
    }
}  

function basePlan_capturedPremiumAmt_func(object){
    calculateBasePlanValue(object);
}

function basePlan_baseSumAssured_func(object){
    calculateBasePlanValue(object);
}

function basePlan_productTerm_func(object){
    defaultPPTerm();
}

function basePlan_paymentTypeCd_func(object){
    defaultPPTerm();
}

function basePlan_premiumHolidayFl_func(object){
    defaultPPTerm();
}

function basePlan_premiumOffsetFl_func(object){
    premiumOffsetValues_lookupKey = $("#premiumOffsetValues_lookupKey").val()
    if(premiumOffsetValues_lookupKey != ""){
        $("#basePlan_premiumOffsetValues").attr("data-lookupkey",premiumOffsetValues_lookupKey);
    }
    filterOffsetOption();
}

function basePlan_premiumOffsetOptionCd_func(object){
    hideOffsetYear();
}

function basePlan_annuityOptionCd_func(object){
    enableAnnuityFields();
}

function basePlan_pdfRequiredFl_func(object){
    enablePrePaymentSection();
}

function basePlan_solverTypeCd_func(object){
    enablePrePaymentFields();
}

function basePlan_retirementOptionFl_func(object){
    enableRetirementFields();
}

function basePlan_productTerm_onFocus(object){
    selected = $("#basePlan_productTerm").val();
    $.ajax({
        url: "/app/Quotation/getProductTerm",
        data: $('#sales_illustration_form').serializeHash(),
        async: false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            if ($("#basePlan_productTerm option[value='"+selected+"']").length > 0){
                $('#basePlan_productTerm').html(data).selectmenu("refresh");
                $('#basePlan_productTerm').val(selected).selectmenu().selectmenu('refresh');
            }
            else{
                $('#basePlan_productTerm').html(data).selectmenu("refresh"); 
            }
        }
    }); 
}

function basePlan_premiumPayingTerm_onFocus(object){
    selected = $("#basePlan_premiumPayingTerm").val();
    $.ajax({
        url: "/app/Quotation/getPremiumPayingTerm",
        data: $('#sales_illustration_form').serializeHash(),
        async: false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            if ($("#basePlan_premiumPayingTerm option[value= "+selected+"]").length > 0){
                $('#basePlan_premiumPayingTerm').html(data).selectmenu("refresh");
                $('#basePlan_premiumPayingTerm').val(selected).selectmenu().selectmenu('refresh');
            }
            else{
                $('#basePlan_premiumPayingTerm').html(data).selectmenu("refresh"); 
            }
        }
    }); 
}

function basePlan_productId_onFocus(object){
    if(object!=null){
        loadLookupData(object.getAttribute("data-lookupkey"), {}, object.id);    
    }
}

function basePlan_productFamilyCd_onFocus(object){
    if(object!=null){
        loadLookupData(object.getAttribute("data-lookupkey"), {}, object.id);
    }
}

function basePlan_productPlanOptionCd_onFocus(object){
    if(object!=null){
        productSeq = $('#basePlan_productSeq').val();
        filterCondition = {'productSeq': productSeq};
        loadLookupData(object.getAttribute("data-lookupkey"), filterCondition, object.id);
    }
}

/********* Fund related functions *********/
function basePlan_currencyCd_func(object){
    $.ajax({
        url: "/app/Quotation/getPortfolioModelCd",
        data: $('#sales_illustration_form').serializeHash(),
        async: false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            $('#basePlan_portfolioModelCd').html(data).selectmenu("refresh");
            if ($('#basePlan_portfolioModelCd').val() != ""){
                basePlan_portfolioModelCd_func(object);                
            }
        }
    }); 
}

function basePlan_portfolioModelCd_func(object){
    $.ajax({
        url: "/app/Quotation/prePopulateFunds",
        data: {
            'form': $('#sales_illustration_form').serializeHash(),
            'gridID': "quotationFunds",
            'columns': 'fundCd,allocationPerc,topupAllocationPerc,fundTypeCd,expiryDt,maturityDt',
        },
        async: false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            $('.quotationFunds-main-class .table-section > table > tbody').html(data)
            $(".quotationFunds-main-class .table-section > table > tbody").trigger('create');
            var fundCd = document.querySelectorAll('select[id*="_quotationFunds_fundCd"]');
            for(var i = 0; i < fundCd.length; i++){
                quotationFunds_fundCd_onFocus(fundCd[i]);  
            }
            if (application_view_mode == "mobile"){
            	$(".quotationFunds-main-class .table-section > table").table('refresh');  
            }
        }
    }); 
}

function basePlan_topUpAllocSameAsPremAllocFl_func(object) {
    if (object!=null){
        if(object.checked){
            $("input[id*='quotationFunds_allocationPerc']").each(function(){
                id = $(this).attr("id").replace("allocationPerc","topupAllocationPerc");
                $("#"+id).val($(this).val());
                $("#"+id).attr("readonly","readonly");
            });
        }
        else{
            $("input[id*='quotationFunds_topupAllocationPerc']").each(function(){
                $(this).val("0");
                $(this).removeAttr("readonly");
            });
        }
    }
}

function quotationFunds_removeButton_func(object) {
    var checkboxMode = object.getAttribute("data-checkbox-mode");
    var id = object.id.replace("removeButton","removed");
    var allocationPercId = object.id.replace("removeButton","allocationPerc");
    var topupAllocationPercId = object.id.replace("removeButton","topupAllocationPerc");

    if(checkboxMode == "add"){
        if(object.checked){
            $("#"+id).val("");
            $("#"+allocationPercId).removeAttr("readonly");
            $("#"+topupAllocationPercId).removeAttr("readonly");
        }
        else{
            $("#"+id).val("YES");
            $("#"+allocationPercId).val('');
            $("#"+allocationPercId).attr("readonly","readonly");
            $("#"+topupAllocationPercId).val('');
            $("#"+topupAllocationPercId).attr("readonly","readonly");
        }
    }
    updateFundTotal();
}

function quotationFunds_fundCd_onFocus(object) {
    loadLookupData(object.getAttribute("data-lookupkey"), {}, object.id);
}

//Method to update total allocation percentage
function updateFundTotal() {
    var allocationPerc = 0;
    var topupAllocationPerc = 0;

    $('input[id*="quotationFunds_allocationPerc"]').each(function() {
        if ($("[id='"+$(this).attr('id').replace("allocationPerc", "removed")+"']").val() != "YES"){

            allocationPerc += parseInt($(this).val());
        }
    });
    
    $('input[id*="quotationFunds_topupAllocationPerc"]').each(function() {
        if ($("[id='"+$(this).attr('id').replace("topupAllocationPerc", "removed")+"']").val() != "YES"){
            topupAllocationPerc += parseInt($(this).val());
        }
    });
    
    if(!isNaN(allocationPerc)){$("#quotationFunds_allocationPerc_lbl span").html(' : (' + allocationPerc+'%)');}
    if(!isNaN(topupAllocationPerc)){$("#quotationFunds_topupAllocationPerc_lbl span").html(' : (' + topupAllocationPerc+'%)');}

}

function quotationFunds_allocationPerc_func(object){
    if(!isNaN(object.value)){
        var removed = object.id.replace("allocationPerc", "removed");
        var topupAlloc = object.id.replace("allocationPerc","topupAllocationPerc");
        if($("#basePlan_topUpAllocSameAsPremAllocFl-0").prop("checked")==true){
            $("#"+topupAlloc).val(object.value);
            $("#"+topupAlloc).attr("readonly","readonly");
        }
        var topupVal = $("#"+topupAlloc).val();

        if(parseInt(object.value) >= 0 || parseInt(topupVal) >= 0){
            $("#"+removed).val('');
        }
        else{
            $("#"+removed).val('YES');
        }
        updateFundTotal();
    }
}

function quotationFunds_topupAllocationPerc_func(object){
    if(!isNaN(object.value)){
        var removed = object.id.replace("topupAllocationPerc", "removed");
        var allocPerc = object.id.replace("topupAllocationPerc","allocationPerc");
        var allocVal = $("#"+allocPerc).val();

        if(parseInt(object.value) >= 0 || parseInt(allocVal) >= 0){
            $("#"+removed).val('');
        }
        else{
            $("#"+removed).val('YES');
        }
        updateFundTotal();
    }
}




/**************TopUp related function**************/
function quotation_topupOptionCd_func(object){
    if (object != null) {
        topupOptionCd = object.value;
        if (topupOptionCd=='EXCESSWITHOUTPH' || topupOptionCd=='EXCESSWITHPH'){
            $('#initialTopup').show();
            $('#regularTopup').show();
            $('#targetFund').hide();

            $("#basePlan_targetFundFl-0").prop('checked', false).trigger("refresh");
            $('label[for="basePlan_targetFundFl-0]"]').addClass("ui-checkbox-off").removeClass("ui-checkbox-on");
            inputFieldCheckClicked(document.getElementById("basePlan_targetFundFl-0"));
        }
        else if (topupOptionCd=='TFCALCULATIONWITHOUTPH' || topupOptionCd=='TFCALCULATIONWITHPH'){
            $('#initialTopup').hide();
            $('#regularTopup').hide();
            $('#targetFund').show();

            $("#quotation_regularTopupFl-0").prop('checked', false).trigger("refresh");
            $('label[for= "quotation_regularTopupFl-0"]').addClass("ui-checkbox-off").removeClass("ui-checkbox-on");
            inputFieldCheckClicked(document.getElementById("quotation_regularTopupFl-0"));

            $("#quotation_initialTopupFl-0").prop('checked', false).trigger("refresh");
             $('label[for= "quotation_initialTopupFl-0"]').addClass("ui-checkbox-off").removeClass("ui-checkbox-on");
            inputFieldCheckClicked(document.getElementById("quotation_initialTopupFl-0"));
        }
        else if (topupOptionCd=='EXCESSANDTFCALCULATIONWITHPH'){
            $('#initialTopup').show();
            $('#regularTopup').show();
            $('#targetFund').show();
        }
        else{
            $('#initialTopup').hide();
            $('#regularTopup').hide();
            $('#targetFund').hide();

            $("#quotation_regularTopupFl-0").prop('checked', false).trigger("refresh");
            $('label[for= "quotation_regularTopupFl-0"]').addClass("ui-checkbox-off").removeClass("ui-checkbox-on");
            inputFieldCheckClicked(document.getElementById("quotation_regularTopupFl-0"));

           
            $("#quotation_initialTopupFl-0").prop('checked', false).trigger("refresh");
            $('label[for= "quotation_initialTopupFl-0"]').addClass("ui-checkbox-off").removeClass("ui-checkbox-on");   
            inputFieldCheckClicked(document.getElementById("quotation_initialTopupFl-0"));

            $("#basePlan_targetFundFl-0").prop('checked', false).trigger("refresh");
            $('label[for= "basePlan_targetFundFl-0"]').addClass("ui-checkbox-off").removeClass("ui-checkbox-on");
            inputFieldCheckClicked(document.getElementById("basePlan_targetFundFl-0"));
        }
    }
}

function quotation_initialTopupFl_func(object) {
    if (object != null) {
        if(object.checked){
            $("#initialInvesttopup_removed").val("");
            setReadOnly($("#initialInvesttopup_topUpAmount"), false);
            $("[id*='initialInvesttopup_']").parents('.project-data').show();
           
        }
        else{
            $("#initialInvesttopup_removed").val("YES");
            $("[id*='initialInvesttopup_']").parents('.project-data').hide();
            $("#initialInvesttopup_topUpAmount").val('');
        }
    }
    toggleOnFocus();
}

function quotation_regularTopupFl_func(object) {
    premiumPayingTerm = $('#basePlan_premiumPayingTerm').val();
    if (object != null) {
        if(object.checked){
            $("#regulartopup_removed").val("");
            setReadOnly($("#regulartopup_topUpPeriod"), false);
            setReadOnly($("#regulartopup_topUpAmount"), false);
            setReadOnly($("#regulartopup_topupFrequencyVal"), false);
            $("[id*='regulartopup_']").parents('.project-data').show();
            $("#regulartopup_topupFrequencyVal").val('1');
            $("#regulartopup_topUpPeriod").val(premiumPayingTerm);

        }
        else{
            $("#regulartopup_removed").val("YES");
            $("[id*='regulartopup_']").parents('.project-data').hide();
            $("#regulartopup_topUpPeriod").val('');
            $("#regulartopup_topUpAmount").val('');
            $("#regulartopup_topupFrequencyVal").val('');
        }
    }
    toggleOnFocus();
}

function basePlan_targetFundFl_func(object) {
    if (object != null) {
        if(object.checked){
            setReadOnly($("#basePlan_payingYears"), false);
            setReadOnly($("#basePlan_targetFundVal"), false);
            setReadOnly($("#basePlan_targetPeriod"), false);
            $('#basePlan_targetPeriodRefCd').selectmenu().selectmenu('enable');
            $("#targetFund input:not(#basePlan_targetFundFl-0):not(#basePlan_targetFundFl-0_hid), #targetFund select").parents('.project-data').show();
        }
        else{
            $('#basePlan_targetPeriodRefCd option:eq(0)')[0].selected = true;
            $('#basePlan_targetPeriodRefCd').selectmenu("refresh", true);
            $('#basePlan_payingYears').val('');
            $('#basePlan_targetFundVal').val('');
            $('#basePlan_targetPeriod').val('');
            $("#targetFund input:not(#basePlan_targetFundFl-0):not(#basePlan_targetFundFl-0_hid), #targetFund select").parents('.project-data').hide();
            
        }
    }
    toggleOnFocus();
}

function adhoctopupLst_addButton_func(object) {
    $.ajax({
        url: "/app/Quotation/addTopup",
        data: {
            'quotationObject': $('#quotation_object').val(), 
            'topupObjects': parseInt($('#topupCount').val()),
            'gridID': "adhoctopupLst",
            'columns': $(object).attr('data-columns'),
            'topUpTypeCd':"ADHOCTOPUP"
        },
        success: function(data) {
            $('#topupCount').val(parseInt($('#topupCount').val())+1);
            displayCount = parseInt($(".adhoctopupLst-main-class .button-add-section span:nth-child(2)").html())+1;
            $(".adhoctopupLst-main-class .button-add-section span:nth-child(2)").html(displayCount);
            sectionExist = $('.adhoctopupLst-main-class .table-section > table > tbody > tr');
            if (sectionExist.length > 0){
                $(".adhoctopupLst-main-class .table-section > table > tbody > tr:last").after(data);
            }
            else{
                $('.adhoctopupLst-main-class .table-section > table > tbody').html(data);
            }
            $(".adhoctopupLst-main-class .table-section > table > tbody").trigger('create');
            $(".adhoctopupLst-main-class .table-section > table").table('refresh');
            toggleOnFocus();
        }
    });
}

function adhoctopupLst_removeButton_func(object) {
    var checkboxMode = object.getAttribute("data-checkbox-mode");
    var id = object.id.replace("removeButton","removed");
    if(checkboxMode == "delete"){
        if(object.checked){
            $("#"+id).val("YES");
        }
        else{
            $("#"+id).val("");
        }
    }
}

function transferContributionLst_addButton_func(object) {
    $.ajax({
        url: "/app/Quotation/addTopup",
        data: {
            'quotationObject': $('#quotation_object').val(), 
            'topupObjects': parseInt($('#topupCount').val()),
            'gridID': "transferContributionLst",
            'columns': $(object).attr('data-columns'),
            'topUpTypeCd':"TRANSFERTOPUP"
        },
        success: function(data) {
            $('#topupCount').val(parseInt($('#topupCount').val())+1);
            displayCount = parseInt($(".transferContributionLst-main-class .button-add-section span:nth-child(2)").html())+1;
            $(".transferContributionLst-main-class .button-add-section span:nth-child(2)").html(displayCount);
            sectionExist = $('.transferContributionLst-main-class .table-section > table > tbody > tr');
            if (sectionExist.length > 0){
                $(".transferContributionLst-main-class .table-section > table > tbody > tr:last").after(data);
            }
            else{
                $('.transferContributionLst-main-class .table-section > table > tbody').html(data)
            }
            $(".transferContributionLst-main-class .table-section > table > tbody").trigger('create');
        }
    });
}

function transferContributionLst_removeButton_func(object) {
    var checkboxMode = object.getAttribute("data-checkbox-mode");
    var id = object.id.replace("removeButton","removed");
    if(checkboxMode == "delete"){
        if(object.checked){
            $("#"+id).val("YES");
        }
        else{
            $("#"+id).val("");
        }
    }
}


/********* Withdrawal related functions *********/
function quotationWithdrawal_addButton_func(object){
    var withdrawalCount = parseInt($('#quotationWithdrawalCount').val());
    columns = $(object).attr('data-columns');
    checkboxMode = $(object).attr("data-checkbox-mode");
    displayCount = $('.quotationWithdrawal-main-class .button-add-section .notification').text();
    $.ajax({
        url: "/app/Quotation/addWithdraw",
        data: {
            'quotationObject': $('#quotation_object').val(), 
            'withdrawalCount': withdrawalCount,
            'columns' : columns,
            'checkboxMode' : checkboxMode
        },
        success: function(data) {
            withdrawalCount = withdrawalCount + 1;
            $("#quotationWithdrawalCount").val(withdrawalCount);
            displayCount =  parseInt(displayCount) + 1; 
            $('.quotationWithdrawal-main-class .button-add-section .notification').text(displayCount);
            sectionExist = $('.quotationWithdrawal-main-class .table-section > table > tbody > tr');
            if (sectionExist.length > 0){
                $(".quotationWithdrawal-main-class .table-section > table > tbody > tr:last").after(data);
            }
            else{
                $('.quotationWithdrawal-main-class .table-section > table > tbody').html(data)
            }
            $(".quotationWithdrawal-main-class .table-section > table > tbody").trigger('create');
            quotation_solverTypeCd_func();
            if (application_view_mode == "mobile"){
                $(".quotationWithdrawal-main-class .table-section > table").table('refresh');
            }
            toggleOnFocus();
        }
    });
}

function quotationWithdrawal_removeButton_func(object) {
    checkboxMode = object.getAttribute("data-checkbox-mode");
    id = object.id.replace("removeButton","removed");
    if(checkboxMode == "delete"){
        if(object != null && object.checked){
            $("input#"+id).val("YES");
        }
        else{
            $("input#"+id).val("");
        }
    }
}

function quotation_withdrawalFl_func(){
    if ($("input:checkbox[id^='quotation_withdrawalFl']:not([id$='hid'])").is(":checked")) {
        $('.quotationWithdrawal-main-class').show();
        $('span[name="withdrawalFields"] select').selectmenu().selectmenu('enable');
        setReadOnly($('span[name="withdrawalFields"] input'), false);
        quotation_solverTypeCd_func();
    }
    else{
        $('.quotationWithdrawal-main-class').hide();
        $('.quotationWithdrawal-main-class input[type!="radio"][type!="hidden"]').val('');
        $('.quotationWithdrawal-main-class select').val('').change();
        $('.quotationWithdrawal-main-class input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");
        $(".quotationWithdrawal-main-class input[id$='_removed']").val('YES');
        $('span[name="withdrawalFields"] select').val('').change();
        $('span[name="withdrawalFields"] input[type!="radio"][type!="hidden"]').val('').change();
        $('span[name="withdrawalFields"] select').selectmenu().selectmenu('disable');
        setReadOnly($('span[name="withdrawalFields"] input'), true);
    }
    toggleOnFocus();
}

function quotation_solverTypeCd_func(){
    solverTypeCd = $("select#quotation_solverTypeCd");
    withdrawalFl = $('input#quotation_withdrawalFl').filter(':checked').val();
    age = $("input#primaryQuotationParty_age").val();
    var renderWithdrawalratetypecd = $('#renderWithdrawalratetypecd').val();
    if (solverTypeCd.fieldexists()){
        if (solverTypeCd.val() == "DATAENTRY"){
            setReadOnly($("input#quotation_payingYears"), true);
            setReadOnly($('.quotationWithdrawal-main-class input'), false);
            $('select[nme$="[withdrawalRateTypeCd]"]').selectmenu().selectmenu('disable');
            if (renderWithdrawalratetypecd == true){
                $('select[nme$="[withdrawalRateTypeCd]"] option:eq(0)')[0].selected = true;
                $('select[nme$="[withdrawalRateTypeCd]"]').selectmenu("refresh",true);
            }
            $("select#quotation_withdrawalRateTypeCd").selectmenu().selectmenu('disable');            
        }
        else if (solverTypeCd.val() == "MAXIMUMAMOUNTSOLVER" || solverTypeCd.val() == "REGULARAMOUNTSOLVER"){
            setReadOnly($("input#quotation_payingYears"), false);
            $("select#quotation_withdrawalRateTypeCd").selectmenu().selectmenu('enable');
            $("input[id*='quotationWithdrawal_frequencyVal']").val(1);
            setReadOnly($('[id$=quotationWithdrawal_policyYearFrom]'), false);
            setReadOnly($('[id$=quotationWithdrawal_policyYearTo]'), false);
            setReadOnly($('[id$=quotationWithdrawal_withdrawalAmount]'), false);
            setReadOnly($('[id$=quotationWithdrawal_frequencyVal]'), false);
            if (renderWithdrawalratetypecd == true){
                $('select[id$="[withdrawalRateTypeCd]"] option:eq(1)')[0].selected = true;
                $('select[id$="[withdrawalRateTypeCd]"]').selectmenu("refresh", true);

            }
            if (age != ''){
                setReadOnly($('[id*=quotationWithdrawal_ageFrom]'), false);
                setReadOnly($('[id*=quotationWithdrawal_ageTo]'), false);
            }
        }
        else if (solverTypeCd.val() == "PERIODSOLVER")
        {
            $("input#quotation_payingYears").val('');
            setReadOnly($("input#quotation_payingYears"), true);
            setReadOnly($('.quotationWithdrawal-main-class input'), false);
            $('[id$=quotationWithdrawal_policyYearTo]').val('');
            $('[id$=quotationWithdrawal_ageTo]').val('');
            setReadOnly($('[id$=quotationWithdrawal_policyYearTo]'), true);
            setReadOnly($('[id$=quotationWithdrawal_ageTo]'), true);
            $('select[id="quotation_withdrawalRateTypeCd"] option:eq(0)')[0].selected = true;
            $('select[id="quotation_withdrawalRateTypeCd"]').selectmenu("refresh",true);
            $("select[id='quotation_withdrawalRateTypeCd']").selectmenu().selectmenu('disable');
        }
        else if (solverTypeCd.val() == "WITHDRAWALOFCOUPON")
        {
            $("input#quotation_payingYears").val('');
            setReadOnly($("input#quotation_payingYears"), true);
            $('.quotationWithdrawal-main-class input[type!="radio"][type!="hidden"]').val('');
            setReadOnly($('.quotationWithdrawal-main-class input'), true);
            if (renderWithdrawalratetypecd == true){
                $('select[id$="[withdrawalRateTypeCd]"] option:eq(0)')[0].selected = true;
                $('select[id$="[withdrawalRateTypeCd]"]').selectmenu("refresh", true);
            }
            $("select#quotation_withdrawalRateTypeCd").selectmenu().selectmenu('disable');
        }
        else if (withdrawalFl != 'YES')
        {
            $("select#quotation_withdrawalRateTypeCd").selectmenu().selectmenu('disable');
            $('.quotationWithdrawal-main-class input[type!="radio"][type!="hidden"]').val('');
            setReadOnly($('.quotationWithdrawal-main-class input'), true);
            setReadOnly($("#quotation_payingYears"), true);
            if (renderWithdrawalratetypecd == true){
                $('select[id$="[withdrawalRateTypeCd]"] option:eq(0)')[0].selected = true;
                $('select[id$="[withdrawalRateTypeCd]"]').selectmenu("refresh", true);
            }
        }
        toggleOnFocus();
    }
}

function calculateAgeFrom(withdrawalPolicyYearFromObject){
    insuredAge = isNaN(parseInt($('#insured_age').val())) ? 0 : parseInt($('#insured_age').val());
    var solverTypeCd = $("select#quotation_solverTypeCd");
    if (solverTypeCd.fieldexists()){
        if ((solverTypeCd.val() == "MAXIMUMAMOUNTSOLVER") && (insuredAge != 0))
        {
            policyYearFromValue = parseInt($(withdrawalPolicyYearFromObject).val());
            var withdrawalName = $(withdrawalPolicyYearFromObject).attr('name');
            ageFrom = withdrawalName.replace("policyYearFrom", "ageFrom");
            if (isNaN(policyYearFromValue))
            {
                $('input[name="'+ageFrom+'"]').val('');
            }
            else{
                ageFromValue = $('input[name="'+ageFrom+'"]').val();
                ageFromValue = policyYearFromValue + insuredAge - 1;
                $('input[name="'+ageFrom+'"]').val(ageFromValue);
            }
        }
    }
}

function calculatePolicyFrom(withdrawalAgeFromObject){
    insuredAge = isNaN(parseInt($('#insured_age').val())) ? 0 : parseInt($('#insured_age').val());
    var solverTypeCd = $("select#quotation_solverTypeCd");
    if (solverTypeCd.fieldexists()){
        if ((solverTypeCd.val() == "MAXIMUMAMOUNTSOLVER") && (insuredAge != 0))
        {
            ageFromValue = parseInt($(withdrawalAgeFromObject).val());
            var withdrawalName = $(withdrawalAgeFromObject).attr('name');
            policyYearFrom = withdrawalName.replace("ageFrom", "policyYearFrom");
            policyYearFromValue = isNaN(parseInt($('input[name="'+policyYearFrom+'"]').val())) ? 0 : parseInt($('input[name="'+policyYearFrom+'"]').val());
            if (policyYearFromValue == 0 )
            {
                policyYearFromValue = ageFromValue - insuredAge + 1;
                $('input[name="'+policyYearFrom+'"]').val(policyYearFromValue);
            }
        }
    }
}

function calculateAgeTo(withdrawalPolicyYearToObject)
{
    insuredAge = isNaN(parseInt($('#insured_age').val())) ? 0 : parseInt($('#insured_age').val());
    var solverTypeCd = $("select#quotation_solverTypeCd");
    if (solverTypeCd.fieldexists()){
        if ((solverTypeCd.val() == "MAXIMUMAMOUNTSOLVER") && (insuredAge != 0))
        {
            policyYearToValue = parseInt($(withdrawalPolicyYearToObject).val());
            var withdrawalName = $(withdrawalPolicyYearToObject).attr('name');
            ageTo = withdrawalName.replace("policyYearTo", "ageTo");
            if (isNaN(policyYearToValue))
            {
                $('input[name="'+ageTo+'"]').val('');
            }
            else{
                ageToValue = $('input[name="'+ageTo+'"]').val();
                ageToValue = policyYearToValue + insuredAge - 1;
                $('input[name="'+ageTo+'"]').val(ageToValue);
            }
        }
    }
}

function calculatePolicyTo(withdrawalAgeToObject)
{
    insuredAge = isNaN(parseInt($('#insured_age').val())) ? 0 : parseInt($('#insured_age').val());
    var solverTypeCd = $("select#quotation_solverTypeCd");
    if (solverTypeCd.fieldexists()){
        if ((solverTypeCd.val() == "MAXIMUMAMOUNTSOLVER") && (insuredAge != 0))
        {
            ageToValue = parseInt($(withdrawalAgeToObject).val());
            var withdrawalName = $(withdrawalAgeToObject).attr('name');
            policyYearTo = withdrawalName.replace("ageTo", "policyYearTo")
            policyYearToValue = isNaN(parseInt($('input[name="'+policyYearTo+'"]').val())) ? 0 : parseInt($('input[name="'+policyYearTo+'"]').val());
            if (policyYearToValue == 0 )
            {
                policyYearToValue = ageToValue - insuredAge + 1;
                $('input[name="'+policyYearTo+'"]').val(policyYearToValue);
            }
        }
    }
}

function quotationWithdrawal_policyYearFrom_func(object){
    calculateAgeFrom(object);
}

function quotationWithdrawal_ageFrom_func(object) {
    calculatePolicyFrom(object);
}

function quotationWithdrawal_policyYearTo_func(object) {
    calculateAgeTo(object);
}

function quotationWithdrawal_ageTo_func(object) {
    calculatePolicyTo(object);
}

/********* Rider related functions *********/
function riderDetails_removed_func(object){
    deletePopup(object,'DELETE_CONFIRMATION','RIDER');
}

function deleteRIDER_Callback_func(object) {
    var fieldObject = $('#'+object.id).parent().find('select[name*="[productSeq]"]');
    var objectFieldName = fieldObject.attr('name');
    var riderObjectName = objectFieldName.substring(0, (objectFieldName.length-12));
    $('input[name="'+riderObjectName+'[removed]"]').val('YES'); 
    $('input[name="'+riderObjectName+'[object]"]').parents('.riderData').hide();
    var displayCount = $('#riderDetails_addButton .notification').text();
    displayCount = parseInt(displayCount) - 1;
    $('#riderDetails_addButton .notification').text(displayCount);
}

function riderDetails_addButton_func(object) {	
    var displayCount = $('#riderDetails_addButton .notification').text();
    $.ajax({
        url: "/app/Quotation/addRider",
        data: {
            'quotationObject': $('#quotation_object').val(),
            'riderObjects': (parseInt($('#riderCount').val()) - 1) + 100, 
        },
        success: function(data) {
            displayCount =  parseInt(displayCount) + 1; 
            objectIndex = (parseInt(displayCount)-1) + 100
            $('#riderDetails_addButton .notification').text(displayCount);
            $('#riderCount').val(parseInt($('#riderCount').val())+1);
            sectionExist = $(".riderDetails-main-class .riderData");
            if (sectionExist.length > 0){
                $(".riderDetails-main-class .riderData:last").after(data);
            }
            else{
                $(".riderDetails-main-class").prepend(data);
            }
            $(".riderDetails-main-class").trigger('create');
            $(document).ready(function(){
                $('#grid_'+objectIndex+'_riderDetails_insuredPartyRefGuid').parents('.project-data').hide();
            });
        } 
	});	
}

function riderDetails_productSeq_onFocus(obj){
    id = obj.id;
    var basePlanProductSeq = $('#basePlan_productSeq').val();
    lookupkey = obj.getAttribute("data-lookupkey");
    filterCondition = {'productSeq': basePlanProductSeq};
    loadLookupData(lookupkey, filterCondition, id);
}

function riderDetails_productPlanOptionCd_onFocus(obj){
    id = obj.id;
    selectedValue = $('#'+id).val();
    applicablePlanOptionsId = id.replace('productPlanOptionCd','applicablePlanOptions');
    var riderApplicablePlanOptions = $('#'+applicablePlanOptionsId).val();
    if ($('#riderAutoPopulationReqFlag').val() == "YES" && riderApplicablePlanOptions != null && riderApplicablePlanOptions != '' && riderApplicablePlanOptions != undefined){
        var optionStr = '' 
        options = riderApplicablePlanOptions.split(',');
        length = options.length;
        for(var k=0; k<length; k++){
            if(options[k])
            {
                option = options[k].split('|');
                optionStr = optionStr + "<option value ='"+option[0]+"'";
                if(selectedValue == option[0]){
                    optionStr = optionStr + ' selected '
                }
                optionStr = optionStr + ' >' + option[1] +  "</option>"
            }
        }
        $('#'+id).html(optionStr);
        $('#'+id).selectmenu().selectmenu("refresh");
    }
    else{
        fieldId = id.replace('productPlanOptionCd','productSeq');
        riderProductSeq = document.getElementById(fieldId);
        lookupkey = obj.getAttribute("data-lookupkey");
        filterCondition = {'productSeq': riderProductSeq.value};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function riderDetails_productPlanOptionCd_func(object){
    if($('#riderAutoPopulationReqFlag').val() == "YES" ){
        productPlanOptionCdId = object.id;
        impactedFieldsId = productPlanOptionCdId.replace('productPlanOptionCd','impactedFields');
        impactedFieldsVal = String($('#'+impactedFieldsId).val());
        if ( impactedFieldsVal == '' || (impactedFieldsVal.indexOf('productPlanOptionCd') !== -1)){
            evaluateRider(object);
        }
    }
}

function riderDetails_partyRoleCd_func(obj){
    var objectId = obj.id;
    var objectFieldName = objectId.replace('partyRoleCd','insuredPartyRefGuid');
    if(obj.value == 'SUPPLEMENTARY')
    {
        $('select[id="' + objectFieldName + '"]').parents('.project-data').show();
    }else
    {
        $('select[id="' + objectFieldName + '"]').parents('.project-data').hide();
    }   
}

function riderDetails_insuredPartyRefGuid_onFocus(obj){
    id = obj.id;
    lookupkey = obj.getAttribute("data-lookupkey");
    quotationObject = document.getElementById('quotation_object');
    filterCondition = {'object': quotationObject.value};
    loadLookupData(lookupkey, filterCondition, id);
}

function riderDetails_productSeq_func(obj){
    var riderProductSeqObj = obj.id;
    var riderRemovedObj = id.replace('productSeq','removed');
    var riderObject = id.replace('productSeq','object');
    var riderObjectValue = $('#' + riderObject).val();
    var riderIndex = obj.name.replace('Quotation[QuotationProduct][','');
    riderIndex = riderIndex.replace('][productSeq]','');
    
    if ($('#' + riderProductSeqObj).val() != "") {
        $('#' + riderRemovedObj).val('');
        $.ajax({
            url: "/app/Quotation/refreshRiderSection",
            method: 'POST',
            data : $('#sales_illustration_form').serialize() + '&riderObject='+riderObjectValue + '&riderCount='+riderIndex, 
            success: function(data) {
                $('#'+ riderObject).parents('.riderData').replaceWith(data);
				$(".riderDetails-main-class").trigger('create');	
                riderDetails_productSeq_onFocus(document.getElementById(riderProductSeqObj));
                var riderPrefix = riderProductSeqObj.replace('_productSeq','');
                var riderPremiumSAFlField = riderProductSeqObj.replace('productSeq','premiumSAFl');
                var riderPremiumSAFl = $('#' + riderPremiumSAFlField).val(); 
                enableDisableFormFields(riderPrefix + '_',riderPremiumSAFl, true);
                $('#grid_'+riderIndex+'_riderDetails_insuredPartyRefGuid').parents('.project-data').hide();
            }
        }); 
    }
    else {
        $('#' + riderRemovedObj).val('YES');
    }
}

function riderDetails_selected_func(object){
    setUnselectedRiders(object);
    evaluateRider(object);
}

function riderDetails_baseSumAssured_func(object){
    if($('#riderAutoPopulationReqFlag').val() == "YES" ){
        baseSumAssuredId = object.id;
        impactedFieldsId = baseSumAssuredId.replace('baseSumAssured','impactedFields');
        impactedFieldsVal = String($('#'+impactedFieldsId).val());
        if ( impactedFieldsVal == '' || (impactedFieldsVal.indexOf('baseSumAssured') !== -1)){
            evaluateRider(object);
        }
    }
}

function riderDetails_productTerm_func(object){
    if($('#riderAutoPopulationReqFlag').val() == "YES" ){
        productTermId = object.id;
        impactedFieldsId = productTermId.replace('productTerm','impactedFields');
        impactedFieldsVal = String($('#'+impactedFieldsId).val());
        if ( impactedFieldsVal == '' || (impactedFieldsVal.indexOf('productTerm') !== -1)){
            evaluateRider(object);
        }
    }
}

function riderDetails_premiumPayingTerm_func(object){
    if($('#riderAutoPopulationReqFlag').val() == "YES" ){
        premiumPayingTermId = object.id;
        impactedFieldsId = premiumPayingTermId.replace('premiumPayingTerm','impactedFields');
        impactedFieldsVal = String($('#'+impactedFieldsId).val());
        if ( impactedFieldsVal == '' || (impactedFieldsVal.indexOf('premiumPayingTerm') !== -1)){
            evaluateRider(object);
        }
    }
}

function setReadOnlyProductExtraFields(onload,module,accordionKey){
    if (module == 'RIDER'){
        if (onload){
            var loadingTypeCds = document.querySelectorAll('[id*="_riderExtraDetails_loadingTypeCd"]');
        }
        else{
            var loadingTypeCds = document.querySelectorAll('div#riderAutoPopulationDiv'+accordionKey+' [id*="_riderExtraDetails_loadingTypeCd"]');
        }
    }
    else{
        var loadingTypeCds = document.querySelectorAll('[id*="_quotationProductExtra_loadingTypeCd"]');
    }
    
    for(var i = 0; i < loadingTypeCds.length; i++){
        var loadingName = loadingTypeCds[i].getAttribute('name');
        var loadingPrefix = loadingName.replace('[loadingTypeCd]','');
        var loadingTypeCd = $("[name='"+loadingName+"']").val();
        var processingTypeCd = $("[name='"+loadingPrefix+"[processingTypeCd]']").val();
        var extraTypeCd = $("[name='"+loadingPrefix+"[extraTypeCd]']").val();

        setReadOnly($("[name='"+loadingPrefix+"[extraPercent]']"), true); 
        setReadOnly($("[name='"+loadingPrefix+"[extraPercDuration]']"), true); 
        setReadOnly($("[name='"+loadingPrefix+"[extraFlatAmt]']"), true); 
        setReadOnly($("[name='"+loadingPrefix+"[extraFlatDuration]']"), true);
        
        if(processingTypeCd == 'ENTERABLE' ){
            if(loadingTypeCd == 'FLAT'){
                setReadOnly($("[name='"+loadingPrefix+"[extraFlatAmt]']"), false); 
                $("[name='"+loadingPrefix+"[extraPercent]']").val(''); 
                $("[name='"+loadingPrefix+"[extraPercDuration]']").val(''); 
            }else if(loadingTypeCd == 'PERCENTAGE'){
                setReadOnly($("[name='"+loadingPrefix+"[extraPercent]']"), false);
                $("[name='"+loadingPrefix+"[extraFlatAmt]']").val(''); 
                $("[name='"+loadingPrefix+"[extraFlatDuration]']").val('');
            }else if(loadingTypeCd == 'BOTH' || loadingTypeCd == 'EITHER'){
                setReadOnly($("[name='"+loadingPrefix+"[extraPercent]']"), false); 
                setReadOnly($("[name='"+loadingPrefix+"[extraFlatAmt]']"), false); 
            }
            if(extraTypeCd == 'MEDICALTEMPLOADING' ){
                if(loadingTypeCd != 'PERCENTAGE')
                    setReadOnly($("[name='"+loadingPrefix+"[extraFlatDuration]']"), false); 
                if(loadingTypeCd!='FLAT')
                    setReadOnly($("[name='"+loadingPrefix+"[extraPercDuration]']"), false); 
            }
        }else if(processingTypeCd == 'DERIVED'){
            // do nothing temporarily
        }
    }
}

function setUnselectedRiders(object){
    var productSeq = object.id.replace("selected-0","productSeq");
    var partyRoleCd = object.id.replace("selected-0","partyRoleCd");
    var insuredPartyRefGuid = object.id.replace("selected-0","insuredPartyRefGuid");
    var productSeqValue = $('#'+productSeq).val();
    var insuredPartyRefGuidValue = $('#'+insuredPartyRefGuid).val();
    var unselectedRiders = $('#quotation_unselectedRiders').val();
    var riderKey = insuredPartyRefGuidValue + ':' + productSeqValue;
    if (!$(object).is(':checked'))
    {
        if (unselectedRiders == '')
        {
            unselectedRiders = riderKey;
        }
        else
        {
            if (unselectedRiders.indexOf(insuredPartyRefGuidValue) !== -1){
                // unselectedRiders = unselectedRiders.replace(insuredPartyRefGuidValue + ":",insuredPartyRefGuidValue+":"+productSeqValue+",");
                partyRiderArr = unselectedRiders.split('|');
                partyRiderArr.forEach(function(partyRider, index){
                    if(partyRider.indexOf(insuredPartyRefGuidValue) !== -1){
                        riderArray = partyRider.split(":")[1].split(",");
                        if(riderArray.indexOf(productSeqValue) === -1){
                            riderArray.push(productSeqValue);
                        }
                        if(riderArray.length > 0){
                            partyRider = insuredPartyRefGuidValue + ":" + riderArray.join(",");
                            partyRiderArr[index] = partyRider;
                        }
                    }
                });
                unselectedRiders = partyRiderArr.join("|");
            }
            else{
                unselectedRiders = unselectedRiders + riderKey ;
            }
        }
    }
    else
    {
        partyRiderArr = unselectedRiders.split('|');
        partyRiderArr.forEach(function(partyRider, index){
            if(partyRider.indexOf(insuredPartyRefGuidValue) !== -1){
                riderArray = partyRider.split(":")[1].split(",");
                riderArray.splice( riderArray.indexOf(productSeqValue), 1 );
                if(riderArray.length > 0){
                    partyRider = insuredPartyRefGuidValue + ":" + riderArray.join(",");
                    partyRiderArr[index] = partyRider;
                }
                else {
                    partyRiderArr.splice(index,1);
                }
            }
        });

        unselectedRiders = partyRiderArr.join("|");
    }
     if (unselectedRiders[unselectedRiders.length -1] != "|"){
        unselectedRiders = unselectedRiders + "|";
     }
        
    $('#quotation_unselectedRiders').val(unselectedRiders);
}

function evaluateRider(object){

    fieldName = object.id.split('_').pop();
    var riderObjectId = object.id.replace(fieldName,"object");
    var riderSelectedId = object.id.replace(fieldName,"selected-0");
    var riderPartyRefGuidId = object.id.replace(fieldName,"insuredPartyRefGuid");
    var riderPartyRoleCdId = object.id.replace(fieldName,"partyRoleCd");
    var riderObject = $('#'+riderObjectId).val();
    var partyRefGuid = $('#'+riderPartyRefGuidId).val();
    var partyRoleCd = $('#'+riderPartyRoleCdId).val();
    var clickedAccordians = $('#clickedAccordians').val();
    var accordionKey = $(object).parents('div[name="riderAutoPopulation"]').attr('id').replace('riderAutoPopulationDiv','');
    
    //on unchecking rider empty all corresponding fields
    if (!$('#'+riderSelectedId).is(':checked')){
        if (application_view_mode == "mobile"){
            var riderID = object.id.replace(fieldName,"productSeq");
            $('#'+riderID).parents('div.fields-container').find('input[type!=hidden][type!=radio][type!=checkbox]').val('');
            $('#'+riderID).parents('div.fields-container').find('select').val('');
        }else{
            $('#'+riderObjectId).parents('tr').find('input[type!=hidden][type!=radio][type!=checkbox]').val('');
            $('#'+riderObjectId).parents('tr').find('select').val('');
        }
    }

    uncollapsedGrid = [];
    $('div[name="riderAutoPopulation"]').each(function(index,element){
        if ($(this).find('.riderDetails-main-class').length > 0){
            var tempId = $(this).attr('id');
            if (tempId != ''){
                uncollapsedGrid.push(tempId);
            }
        }
    });


    if (application_view_mode == "mobile"){
        uncollapsedMobileRider = [];
        $("div[name='riderAutoPopulation'].slick-active .ui-collapsible:not(.ui-collapsible-collapsed)").find("[id*='rider-fields-']").each(function(index,element){
            uncollapsedMobileRider.push(element.id);
        });
    }



    $('div[name="riderAutoPopulation"] select').selectmenu('enable');
    $('div[name="riderAutoPopulation"] input[type!=hidden]').removeAttr("disabled");
    $('div[name="riderAutoPopulation"] input[type!=hidden]').removeAttr("readonly");
    $('div[name="riderAutoPopulation"] input[type!=hidden]').removeClass("readonly");

    $.ajax({
        url: "/app/Quotation/evaluateRider",
        method: 'POST',
        data: $('#sales_illustration_form').serialize() + "&riderObject="+riderObject +"&partyRefGuid="+partyRefGuid+"&partyRoleCd="+partyRoleCd+"&accordionKey="+accordionKey+"&clickedAccordians="+clickedAccordians,
        success: function(data){
            if (data != ""){
                $("div[data-role='popup']:not(#error-list):not(#summaryPopUp):not(#popup-benefits-details)").remove();
                temp = JSON.parse(data);
                impactedLifeAccordions = temp.impactedLifeAccordions.split(',');
                htmlContentOfImpactedLives = temp.html;
                $.each(impactedLifeAccordions, function(index, accordion_key) {
                    removeItem = 'riderAutoPopulationDiv'+accordion_key;
                    if ($.inArray(removeItem, uncollapsedGrid) > -1){
                        uncollapsedGrid = jQuery.grep(uncollapsedGrid, function(value) {
                            return value != removeItem;
                        });
                    }
                    htmlContent = htmlContentOfImpactedLives[accordion_key];
                    $('div#riderAutoPopulationDiv'+accordion_key).html(htmlContent);
                    $('div#riderAutoPopulationDiv'+accordion_key).trigger('create');
                    settingRiderData(accordion_key);
                });
                $.each(uncollapsedGrid, function(index, gridId) {
                    accordionKey = gridId.replace('riderAutoPopulationDiv','');
                    settingRiderData(accordionKey);
                });

                if (application_view_mode == "mobile" && uncollapsedMobileRider.length > 0){
                    $.each(uncollapsedMobileRider, function(index, elementId) {
                        $("#" + elementId).parents(".ui-collapsible.ui-collapsible-collapsed").collapsible("expand");
                    });
                }
            }
        }
    });
}

function populateRider(accordionKey){
    var riderInitialCount = $('#riderInitialCount'+accordionKey).val()
    $.ajax({
        url: "/app/Quotation/populateRider",
        method: 'POST',
        data: $('#sales_illustration_form').serialize() + "&accordionKey="+accordionKey+"&riderInitialCount="+riderInitialCount,
        success: function(data){
            $('div#riderAutoPopulationDiv'+accordionKey).html(data);
            $('div#riderAutoPopulationDiv'+accordionKey).trigger('create');
            existingAccKey = $('#clickedAccordians').val();
            if(existingAccKey != ''){
                existingAccKey = existingAccKey + ","+accordionKey;
            }else{
                existingAccKey = accordionKey
            }
            $('#clickedAccordians').val(existingAccKey);
            settingRiderData(accordionKey);
            $("[type='checkbox'][id*='riderDetails_selected']:not(:checked)").each(function(){
                setUnselectedRiders(this);
            });
            toggleOnFocus();
        }
    });
}

function settingRiderData(accordionKey) {
    var ridersPlanOptions = document.querySelectorAll('div#riderAutoPopulationDiv'+accordionKey+' select[id*="_riderDetails_productPlanOptionCd"]');
    for(var l = 0; l < ridersPlanOptions.length; l++){
        riderDetails_productPlanOptionCd_onFocus(ridersPlanOptions[l]);
    }
    
    var riders = document.querySelectorAll('div#riderAutoPopulationDiv'+accordionKey+' [id*="_riderDetails_productSeq"]');
    for(var i = 0; i < riders.length; i++){
        var riderId = riders[i].getAttribute('id');
        var riderPrefix = riderId.replace('_productSeq','');
        var riderPremiumSAFlField = riderId.replace('productSeq','premiumSAFl');
        riderPremiumSAFl = $('#' + riderPremiumSAFlField).val(); 
        
        if (application_view_mode == "mobile"){
            if ($('#'+riderPrefix+'_selected-0').is(':checked')){
                $('#'+riderId).parents('div.fields-container').find('select').selectmenu().selectmenu('enable');
                $('#'+riderId).parents('div.fields-container').find('input[type!=hidden][type!=checkbox]').removeClass('readonly');
                $('#'+riderId).parents('div.fields-container').find('input[type!=hidden][type!=checkbox]').removeAttr('readonly');
                $('#'+riderId).parents('div.fields-container').find('a').removeClass('readonly');
                enableDisableFormFields(riderPrefix + '_',riderPremiumSAFl, true); 
            }
            else{
                $('#'+riderId).parents('div.fields-container').find('select').selectmenu().selectmenu('disable');
                $('#'+riderId).parents('div.fields-container').find('input[type!=hidden][type!=checkbox]').addClass('readonly');
                $('#'+riderId).parents('div.fields-container').find('a').addClass('readonly');
                $('#'+riderId).parents('div.fields-container').find('input[type!=hidden][type!=checkbox]').attr('readonly','true');
            }
        }
        else{
            if ($('#'+riderPrefix+'_selected-0').is(':checked')){
                $('#'+riderId).parents('tr').find('select').selectmenu().selectmenu('enable');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').removeClass('readonly');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').removeAttr('readonly');
                $('#'+riderId).parents('tr').find('a').removeClass('readonly');
                enableDisableFormFields(riderPrefix + '_',riderPremiumSAFl, true); 
            }
            else{
                $('#'+riderId).parents('tr').find('select').selectmenu().selectmenu('disable');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').addClass('readonly');
                $('#'+riderId).parents('tr').find('a').addClass('readonly');
                $('#'+riderId).parents('tr').find('input[type!=hidden][type!=checkbox]').attr('readonly','true');
            }
        }


       
    }

    var riderDisableField = document.querySelectorAll('div#riderAutoPopulationDiv'+accordionKey+' input[id*="_riderDetails_riderDisableField"]');
    for(var i = 0; i < riderDisableField.length; i++){
        selectedId = riderDisableField[i].id.replace('riderDisableField','selected-0') 
        if (riderDisableField[i].value == 'YES'){
            $('#'+selectedId).checkboxradio().checkboxradio('disable');
        }
        else{
            $('#'+selectedId).checkboxradio().checkboxradio('enable');
        }
    }
    setReadOnlyProductExtraFields(false,'RIDER',accordionKey);
    disableAllIfAccepted();
    if (typeof window["attachMaskAll"] === "function") {
        attachMaskAll();
    }
}

function addMore_riderDetails(currentRiderIdPrefix) {
    var riderGuid = $('#'+currentRiderIdPrefix+'_guid').val();
    // NOTE: The selector is the hidden DIV element.
    $("#riderLoadingDiv-"+riderGuid).simpledialog2({
        width : '80%',
        top: '25%',
        left: '10%',
        themeDialog: 'a'
    });
    $('.ui-simpledialog-container').css('min-height','0');
}


function acceptIllustration(){
    loading('show');
    $.ajax({
        url: "/app/Quotation/acceptIllustration",
        data: { 'form': $('#sales_illustration_form').serializeHash()},
        success: function(data) {
        }
    });          
}

function viewIllustration(){
    $('input[id*="_riderDetails_selected"][type!="hidden"]').checkboxradio().checkboxradio('enable');
    $('select').selectmenu().selectmenu('enable');
    $('input').removeAttr("disabled");  
    $('input').removeAttr("readonly");  
    $('input[type= "radio"]').attr("disabled", false);
    loading('show');
    $.ajax({
        url: "/app/Quotation/viewIllustration",
        async: false,
        data: { 'form': $('#sales_illustration_form').serializeHash()},
        success: function(data) {
        }
    });  
}


function selectFNA(value) {
    $("#fnaId").val($(value).val());
}


function linkFNA(){
    var fnaDetails = "";
    $(document.getElementsByName("Quotation[fnaId]")).each(function(index,element){
        if(element.checked){
            fnaDetails = element.value;
        }
    });
    var quotationDetails = $("#quotationrefnumber").val();
    if (fnaDetails != null){
        $.ajax({
            url: "/app/Quotation/linkToFNAPopup",
            data: { fnaId: fnaDetails, quotationId : quotationDetails},
            headers: {'Transition-Enabled': false},
            success: function(data){
                if (data){
                    $.mobile.sdCurrentDialog.close();
                    submitTabForm($('#sym_current_Tab').val());
                }
                else{
                    $.mobile.sdCurrentDialog.close();
                    submitTabForm($('#sym_current_Tab').val());
                }
            },
        });
    }
    setTimeout(function(){ window.location.reload() }, 1500);
}

function getCollateral(objectId,fieldName){
    var id = objectId.replace('helpLink',fieldName);
    var productId = $('#'+id).val();
    $.ajax({
        url: "/app/Collateral/showpopup",
        data: { medianame: productId},
        headers: {'Transition-Enabled': false},
        success: function(data){
            
        }
    });

}

function popupFooterOkMobile(object) {
    var popupDivId = $(object).parents("div[data-role='popup']").attr("id");
    var popupDiv = $("#"+popupDivId);
    var formContentDivId = popupDivId.replace("popup-benefits-details","rider-fields");
    //set values in html dom before copying popup container html to respective hidden div
    $("#"+popupDivId +" .popup-benefits-content input[type=tel]").each(function () {
        $(this).attr('value', $(this).val());
    });
    $("#"+popupDivId +" .popup-benefits-content input[type=checkbox],input[type=radio]").each(function () {
        if($(this).is(":checked")){
            $(this).attr("value", "YES");
        }
        else {
            $(this).attr("value", "NO");
        }
    });
    $("#"+popupDivId +" .popup-benefits-content select").find(':selected').attr('selected', 'selected');
    var popupHtml = $("#"+popupDivId +" .popup-benefits-content div.fields-container")
    $("#"+formContentDivId).empty();
    $("#"+formContentDivId).append(popupHtml).enhanceWithin();
    $("#"+popupDivId +" .popup-benefits-content").empty();
    popupDiv.popup('close');
}

function popupFooterClearMobile(object) {
    var popupDivId = $(object).parents("div[data-role='popup']").attr("id");
    
    var formContentDivId = popupDivId.replace("popup-benefits-details","rider-fields");
   
    setRiderPopupContentMobile(popupDivId,formContentDivId);
}

function setRiderPopupContentMobile(popupDivId,formContentDivId){
    var popupDiv = $("#"+popupDivId);
    var riderFieldsHtml = $("#"+ formContentDivId +" div.fields-container").clone(true,true);
    $("#"+popupDivId +" .popup-benefits-content").empty();
    $("#"+popupDivId +" .popup-benefits-content").append(riderFieldsHtml);
    popupDiv.bind({
        popupafterclose: function(event, ui) { 
            popupDiv.attr("id","popup-benefits-details");

        }
    });
    $(".popup-benefits-content .error-msg a.icon-error-message").click(function () {
        var errPopupId = $(this).attr("href").substring(1);
        $("#"+ errPopupId+"-popup").addClass("show-err-popup-container")
        $("#"+ errPopupId+"-popup .icon-close").removeAttr('data-rel');
        $("#"+ errPopupId+"-screen").addClass("in-enhanced")
        $("#"+ errPopupId+"-popup .icon-close, #"+ errPopupId+"-screen").click(function () {
            event.preventDefault();
            $("#"+ errPopupId+"-popup").removeClass("show-err-popup-container")
            $("#"+ errPopupId+"-screen").removeClass("in-enhanced")
        })

    });

    if (typeof window["attachMaskAll"] === "function") {
        attachMaskAll();
    }
}

function riderHeaderClickMobile(object){
    var isSelected = '';
    isSelected = $(object).find("input[type=checkbox][id*='_riderDetails_selected']").val();
    if (isSelected == 'YES'){
        var riderHeader = $(object).children(".popup-header").text();
        var aHref = $(object).attr("href");
        var popupDiv = $("#popup-benefits-details");
        var popupDivId = aHref.substring(1);
        popupDiv.attr("id", popupDivId);
        $("#"+popupDivId +" .popup-heading-bg").html(riderHeader);
        formContentDivId = aHref.substring(1).replace("popup-benefits-details","rider-fields");

        setRiderPopupContentMobile(popupDivId,formContentDivId);

        popupDiv.popup('open');
        toggleOnFocus();
    }
}

function hideShowQuickLinkIcon(){
    var hiddenQuickLinkCount = 0
    var totalQuickLinkCount = $('.quicklink-details ul li').length;
    $('.quicklink-details ul li').each(function(){
        if ($(this).css('display') == 'none'){
            hiddenQuickLinkCount = hiddenQuickLinkCount + 1;
        }
    });
    if(totalQuickLinkCount == hiddenQuickLinkCount){
        $(".quicklink").hide();
    }
}

// this should always be last call, write any functions above this
var insuranceTypeCd = $('#quotation_insuranceTypeCd').val();
insertAfterScriptPath = $('script[src="/app/Quotation/QuoteCapture_Jazz.js"]')
if(insuranceTypeCd == 'AUTO'){
    includeJs("/app/Quotation/QuoteCaptureAuto_Jazz.js", insertAfterScriptPath);
}
else if(insuranceTypeCd == 'TRAVEL'){
    includeJs("/app/Quotation/QuoteCaptureTravel_Jazz.js", insertAfterScriptPath);
}
else if(insuranceTypeCd == 'HEALTH'){
    includeJs("/app/Quotation/QuoteCaptureHealth_Jazz.js", insertAfterScriptPath);
}
else{
    includeJs("/app/Quotation/QuoteCaptureLife_Jazz.js", insertAfterScriptPath);
}