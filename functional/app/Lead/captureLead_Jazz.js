$(document).ready(function(){
    $(".basictop-navarea").fixHeader();
    initialFormSerialized = '';

    $('#quicklink_CLOSELEAD').click(function(object){
        deletePopup(object,"CLOSELEAD",'Lead');
    });
    hideShowQuicklinks();
    toggleOnFocus();
    if($("#lead_leadId").val()!=''){
        initialFormSerialized = $('#leadForm').serialize();
    }
    lead_nationality_func();

});


function submitForm(currentTab) {
    if($("#lead_leadId").val() ==''){
       initialFormSerialized = ''
    }
    return true;
}


function tab_basic_pageTabLoaded(){
    toggleOnFocus();
    hideShowQuicklinks();
    $(".basictop-navarea").fixHeader();
    lead_nationality_func();
    disableDragging();
}


function tab_contact_pageTabLoaded(){
    toggleOnFocus();
    hideShowQuicklinks();
    $(".basictop-navarea").fixHeader();
}


function tab_activity_pageTabLoaded(){
    toggleOnFocus();
    hideShowQuicklinks();
    $(".basictop-navarea").fixHeader();
}


function leadActivity_addButton_func(object){
	var ActivityCount = parseInt($('#leadActivityCount').val());
	var displayCount = $('#leadActivity_addButton .button-add-section .notification').text();
    $.ajax({
        url: "/app/Lead/addActivity",
        data: {
            'leadObject': $('#lead_object').val(),
            'leadActivityCount': ActivityCount
        },
        success: function(data) {
            leadActivityCount = ActivityCount + 1;
            $("#leadActivityCount").val(leadActivityCount);
            displayCount =  parseInt(displayCount) + 1; 
            $('#leadActivity_addButton .button-add-section .notification').text(displayCount);
            sectionExist = $(".leadActivity-main-class >.collapse-panel >.ui-collapsible");
            if (sectionExist.length > 0){
                $(".leadActivity-main-class > .collapse-panel >.ui-collapsible:last").next('.clearfix').after(data);
            }
            else{
                $(".leadActivity-main-class > .collapse-panel").prepend(data);
            }
            $(".leadActivity-main-class").trigger('create');
            
            $(".datepicker:not(.inputreadonly)").datepicker({
                showOn: 'focus',
                showButtonPanel: true,
                closeText: 'Clear', 
                changeMonth: true,
                changeYear: true,
                dateFormat: "dd/mm/yy",
                yearRange: "c-100:c+100",
                onClose: function () {
                var event = arguments.callee.caller.caller.arguments[0];
                    if ($(event.delegateTarget).hasClass('ui-datepicker-close')) {
                        $(this).val('');
                    }
                }
            });
            toggleOnFocus();
            disableDragging();
        }
    });
}

function leadActivity_removed_func(object){
    deletePopup(object, "DELETE_CONFIRMATION",'Activity');
}

function deleteActivity_Callback_func(object){
    var fieldObject = $('#'+object.id.replace("removed","object"));
    var objectFieldName = fieldObject.attr('name');
    var act_object = fieldObject.val();
    $.ajax({
        url: "/app/Lead/removeLeadActivity",
        data: {
            'leadActivityObject': act_object
        },
        success: function(data) {
            var grandparent = fieldObject.parents(".leadActivity-main-class");
            fieldObject.parents(".ui-collapsible").remove();
            grandparent.trigger('create');
            var displayCount = $('#leadActivity_addButton .button-add-section .notification').text();
            displayCount = parseInt(displayCount) - 1;
            $('#leadActivity_addButton .button-add-section .notification').text(displayCount);
        }
    });
}

function deleteNOActivity_Callback_func(object){
    var fieldObject = $('#'+object.id.replace("removed","object"));
    var objectFieldName = fieldObject.attr('name');
    var grandparent = fieldObject.parents(".leadActivity-main-class");
    grandparent.trigger('create');
    var displayCount = $('#leadActivity_addButton .button-add-section .notification').text();
    $('#leadActivity_addButton .button-add-section .notification').text(displayCount);
}


function getAge(birthDt, fieldId1, fieldId2, fieldId3) {
	var objectField = fieldId1.replace('age','object');
    age = 0;
    $.ajax({
        url: "/app/Lead/getAge",
        data: {'birthDt': birthDt},
        async:   false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            ageParts = data.split("|");
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
    $.ajax({
        url: "/app/Lead/getBirthDt",
        data: {'age':age},
        async: false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            $('#'+ fieldId).val(data).change(toggleOnFocus());
        }
    });
}

function lead_dob_func(object){
    age = object.id.replace("dob","age")
    getAge(object.value, age, '', '');
}

function lead_age_func(object){
    dob = object.id.replace("age","dob")
    getDOB(object.value, dob);
}


function lead_natureofDutyId_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#lead_industryCd').val();
        filterCondition = {'industryCd' : industryCd};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function lead_occupationCd_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        industryCd = $('select#lead_industryCd').val();
        natureOfDuty = $('select#lead_natureofDutyId').val();
        filterCondition = {'industryCd' : industryCd, 'natureOfDuty' : natureOfDuty};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function deleteLead_Callback_func(object){
    var act_object =$('#lead_object').val();
    $.ajax({
        url: "/app/Lead/closeLead",
        data: {'lead_object': act_object},
        success: function(data){    
        }
     }); 
}

function deleteNoLead_Callback_func(object){

}

function lead_industryCd_onFocus(obj){
    $("select#lead_natureofDutyId").val('').change(); 
    $("select#lead_occupationCd").val('').change(); 
}


//Function to get city, state based on country, pincode
function getPincodeCityStateCountryLookups(lookup, value) {
    var ajaxData = "";
    var selectID = "";
    var spanID = "";

    countryId = "lead_country";
    pincodeId = "lead_pincode";
    stateId = "lead_state";
    cityId = "lead_city";

    switch (lookup) {
        case "district":
            ajaxData = "option=district&countryCd="+$('select[id="'+countryId+'"]').val()+"&pinCode="+$('input[id="'+pincodeId+'"]').val()+"&fieldValue="+value;
            selectID = stateId;
            break;
        case "city":
            ajaxData = "option=city&countryCd="+$('select[id="'+countryId+'"]').val()+"&pinCode="+$('input[id="'+pincodeId+'"]').val()+"&fieldValue="+value;
            selectID = cityId;
            break;
    }

    $.ajax({
        url: "/app/Lead/getPincodeCityStateCountryLookups",
        async: false,
        data: ajaxData,
        headers: {
          'Transition-Enabled': false
        },
        success: function(data) {
            if (data != "") {
                $('#'+selectID).val(data).change(toggleOnFocus());
               
            }
        }
    });
}

function lead_country_func(obj) {
    getPincodeCityStateCountryLookups("district", $("#lead_state").val());
    getPincodeCityStateCountryLookups("city", $("#lead_city").val());
}

function lead_pincode_func(obj) {
    getPincodeCityStateCountryLookups("district", $("#lead_state").val());
    getPincodeCityStateCountryLookups("city", $("#lead_city").val());
}

function hideShowQuicklinks(){
    var status = $("#lead_statusCd").val();
    if (status == "COMPLETE"){
        $("#quicklink_FNA,#quicklink_GFNA,#quicklink_Quotation,#quicklink_CLOSELEAD").show();
    }
    else if(status =="CLOSED"){
        disableAllFormFields();
        $("#quicklink_FNA,#quicklink_GFNA,#quicklink_Quotation,#quicklink_CLOSELEAD").hide();
    }
    else if($("#lead_leadId").val() =='') {
        $("#quicklink_FNA,#quicklink_GFNA,#quicklink_Quotation,#quicklink_CLOSELEAD").hide();
    }
    else{
        $("#quicklink_CLOSELEAD").show();
        $("#quicklink_FNA,#quicklink_GFNA,#quicklink_Quotation").hide();
    } 
    hideShowQuickLinkIcon();  
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
       $("a[href = '#'] .icon-menu-bar").hide(); 
    }
    else{
        $("a[href = '#'] .icon-menu-bar").show(); 
    }
}

function lead_nationality_func(obj){
    var nationality = $('#lead_nationality').val();
    if (nationality == "OTHERS")
    {
        $("#lead_otherNationality").parents(".project-data").show();
    }
    else
    {
        $("#lead_otherNationality").parents(".project-data").hide();
        $("#lead_otherNationality").val("");
    }
}