function tab_basic_pageTabLoaded(){
    if ($("input:checkbox[id^='primaryQuotationParty_partySameAsCd']:not([id$='hid'])").is(":checked")) {
        $('#displayPrimary').hide();
    }
    else {
        $('#displayPrimary').show();
    }
    proposerQuotationParty_partyTypeCd_func();
    var sameAsFlag = false
    $('input[id*="supplementaryQuotationParty_partySameAsCd"][type="checkbox"]').each(function(){
        if(this.checked){
            sameAsFlag = true;
            return false;
        }
    });
    if (sameAsFlag){
        $('input[id*="supplementaryQuotationParty_partySameAsCd"][type="checkbox"]').each(function(){
            if(this.checked){
                $(this).parents('.add-section').find('.displayDriver').hide();
            }
            else{
                $(this).parents('.project-data').hide();
            }
        });
    }
    hideShowPremiumSummaryLink();
    disableAllIfAccepted();
}

function tab_premiumSummary_pageTabLoaded() {
    $('.main-content-wrapper').siblings('.footer-bg').hide();
    // $('#summaryPopUp').css('min-height','0px');
    saveAndPrevButton = $('.section-tab li .ui-link').eq(-2).attr('href');
    $('#saveAndPrevButton').attr('href', saveAndPrevButton);
    $('a.summaryTabView').css('width',$('#footerDivision').val());
}

function primaryQuotationParty_partySameAsCd_func(obj) {
    if ($("input:checkbox[id^='primaryQuotationParty_partySameAsCd']:not([id$='hid'])").is(":checked")) {
        $('#displayPrimary input[type!="radio"][type!="hidden"]').val(''); 
        $('#displayPrimary select').val('').change();
        $('#displayPrimary input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");
        $('#displayPrimary').hide();
    }
    else {
        $('#displayPrimary').show();
    }
}

function supplementaryQuotationParty_partySameAsCd_func(obj) {
    var id = obj.id;
    if (obj.checked){
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver input[type!=hidden][type!=checkbox][type!=radio]').val('');
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver select').val('');
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver').hide();
        $('input[id*="supplementaryQuotationParty_partySameAsCd"][type="checkbox"]').each(function(){
            if(this.id == id){
                // do nothing
            }
            else{
                $(this).parents('.project-data').hide();
            }
        });
    }
    else{
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver').show();
        $('input[id*="supplementaryQuotationParty_partySameAsCd"][type="checkbox"]').each(function(){
            $(this).parents('.project-data').show();
        });
    }
}

function supplementaryQuotationParty_addButton_func(object){
    var supplementLifeCount = parseInt($('#supplementLifeCount').val());
    var supQuotationProductCount = parseInt($('#supQuotationProductCount').val());
    insuranceTypeCd = $('#quotation_insuranceTypeCd').val();
    var displayCount = $('#supplementaryQuotationParty_addButton .button-add-section .notification').text();
    $.ajax({
        url: "/app/Quotation/addSupplementLife",
        data: {
            'quotationObject': $('#quotation_object').val(), 
            'supplementLifeCount': supplementLifeCount,
            'supQuotationProductCount':supQuotationProductCount,
            'displayCount':displayCount,
            'insuranceTypeCd': insuranceTypeCd
        },
        success: function(data) {
            supplementLifeCount = supplementLifeCount + 1;
            $("#supplementLifeCount").val(supplementLifeCount);

            supQuotationProductCount = supQuotationProductCount + 1;
            $("#supQuotationProductCount").val(supQuotationProductCount);
            
            displayCount =  parseInt(displayCount) + 1; 
            $('#supplementaryQuotationParty_addButton .button-add-section .notification').text(displayCount);
            sectionExist = $(".supplementaryQuotationParty-main-class >.ui-collapsible-set >.ui-collapsible");
            if (sectionExist.length > 0){
                $(".supplementaryQuotationParty-main-class > .ui-collapsible-set >.ui-collapsible:last").next('.clearfix').after(data);
            }
            else{
                $(".supplementaryQuotationParty-main-class >.ui-collapsible-set").prepend(data);
            }
            $(".supplementaryQuotationParty-main-class").trigger('create');
            
            $(".datepicker:not(.inputreadonly)").datepicker({
                changeMonth: true,
                changeYear: true,
                dateFormat: "dd/mm/yy",
                yearRange: "c-100:c+100"
            });
            var sameAsFlag = false
            $('input[id*="supplementaryQuotationParty_partySameAsCd"][type="checkbox"]').each(function(){
                if(this.checked){
                    sameAsFlag = true;
                    return false;
                }
            });
            if (sameAsFlag){
                partySameAsId = "grid_"+String(supplementLifeCount)+"_supplementaryQuotationParty_partySameAsCd-0"
                $('input[type="checkbox"][id="'+partySameAsId+'"]').parents('.project-data').hide();
            }
        }
    });
}

function supplementaryQuotationParty_removed_func(object){
    deletePopup(object, "DELETE_CONFIRMATION",'driver');
}

function deletedriver_Callback_func(object){
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