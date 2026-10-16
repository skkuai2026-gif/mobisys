function tab_vehicleInsuredDetails_pageTabLoaded(){
    if ($("input:checkbox[id^='primaryPolicyPartyRole_partySameAsCd']:not([id$='hid'])").is(":checked")) {
        $('#displayPrimary').hide();
    }
    else {
        $('#displayPrimary').show();
    }
    var sameAsFlag = false
    $('input[id*="supplementaryPolicyPartyRole_partySameAsCd"][type="checkbox"]').each(function(){
        if(this.checked){
            sameAsFlag = true;
            return false;
        }
    });
    if (sameAsFlag){
        $('input[id*="supplementaryPolicyPartyRole_partySameAsCd"][type="checkbox"]').each(function(){
            if(this.checked){
                $(this).parents('.add-section').find('.displayDriver').hide();
            }
            else{
                $(this).parents('.project-data').hide();
            }
        });
    }
    disableFieldsIfQuotationRefGuid();
}

/********* Supplementary Life related functions *********/
function supplementaryDetails_addButton_func(object){
	var suplementaryInsuredCount = parseInt($('#suplementaryInsuredCount').val());
	var supPolicyProductCount = parseInt($('#supPolicyProductCount').val());
	var displayCount = $('#supplementaryDetails_addButton .button-add-section .notification').text();
	currentTab = $('#sym_current_Tab').val();
	 $.ajax({
        url: "/app/Policy/addMoreDriver",
        data: {
            'policyObject': $('#policy_object').val(), 
            'suplementaryInsuredCount': suplementaryInsuredCount,
            'supPolicyProductCount':supPolicyProductCount,
            'sym_current_Tab':currentTab,
            'displayCount':displayCount
        },
        success: function(data) {
            suplementaryInsuredCount = suplementaryInsuredCount + 1;
            $("#suplementaryInsuredCount").val(suplementaryInsuredCount);
            
            supPolicyProductCount = supPolicyProductCount + 1;
            $("#supPolicyProductCount").val(supPolicyProductCount);

            displayCount =  parseInt(displayCount) + 1; 
            $('#supplementaryDetails_addButton .button-add-section .notification').text(displayCount);
            sectionExist = $(".supplementaryDetails-main-class >.ui-collapsible-set >.ui-collapsible");
            if (sectionExist.length > 0){
                $(".supplementaryDetails-main-class > .ui-collapsible-set >.ui-collapsible:last").next('.clearfix').after(data);
            }
            else{
                $(".supplementaryDetails-main-class >.ui-collapsible-set").prepend(data);
            }

            $(".supplementaryDetails-main-class").trigger('create');
            
            $(".datepicker:not(.inputreadonly)").datepicker({
                changeMonth: true,
                changeYear: true,
                dateFormat: "dd/mm/yy",
                yearRange: "c-100:c+100"
            });
            var sameAsFlag = false
            $('input[id*="supplementaryPolicyPartyRole_partySameAsCd"][type="checkbox"]').each(function(){
                if(this.checked){
                    sameAsFlag = true;
                    return false;
                }
            });
            if (sameAsFlag){
                partySameAsId = "grid_"+String(supplementLifeCount)+"_supplementaryPolicyPartyRole_partySameAsCd-0"
                $('input[type="checkbox"][id="'+partySameAsId+'"]').parents('.project-data').hide();
            }
        }
    });
}


function primaryPolicyPartyRole_partySameAsCd_func(){
    if ($("input:checkbox[id^='primaryPolicyPartyRole_partySameAsCd']:not([id$='hid'])").is(":checked")) {
        $('#displayPrimary input[type!="radio"][type!="hidden"]').val(''); 
        $('#displayPrimary select').val('').change();
        $('#displayPrimary input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");
        $('#displayPrimary').hide();
    }
    else {
        $('#displayPrimary').show();
    }
}

function supplementaryPolicyPartyRole_partySameAsCd_func(obj) {
    var id = obj.id;
    if (obj.checked){
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver input[type!=hidden][type!=checkbox][type!=radio]').val('');
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver select').val('');
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver input[type=radio]').attr("checked", false).checkboxradio().checkboxradio("refresh");
        $('input[id="'+id+'"]').parents('.add-section').find('.displayDriver').hide();
        $('input[id*="supplementaryPolicyPartyRole_partySameAsCd"][type="checkbox"]').each(function(){
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
        $('input[id*="supplementaryPolicyPartyRole_partySameAsCd"][type="checkbox"]').each(function(){
            $(this).parents('.project-data').show();
        });
    }
}

function disableFieldsIfQuotationRefGuid(){
    if($('#policy_quotationRefGuid').val()!='' && $('#policy_policyNum').val()==''){
        currentTab = $('#sym_current_Tab').val();
        switch(currentTab){
            case "tab_vehicleDetails":
                setReadOnly($('#policy_autoRegistrationNum'), true);
                $('#policy_autoMakeCd').selectmenu().selectmenu('disable').trigger("refresh");
                $('#policy_autoModelCd').selectmenu().selectmenu('disable').trigger("refresh");
                break;
            case "tab_vehicleInsuredDetails":
                $('input[type="checkbox"][id*="primaryPolicyPartyRole_partySameAsCd"]').checkboxradio().checkboxradio('disable').trigger("refresh");
                disablePartyFieldsIfQuotationRefGuide("PolicyProposerDO");
                disablePartyFieldsIfQuotationRefGuide("PolicyPrimaryLifeDO");
                $('input[type="checkbox"][id*="supplementaryPolicyPartyRole_partySameAsCd"]').checkboxradio().checkboxradio('disable').trigger("refresh");

                supplementaryList = document.querySelectorAll('input[id*="_supplementaryParty_object"]');
                for(var j = 0; j < supplementaryList.length; j++){  
                    party = supplementaryList[j].id.replace("_object","");
                    disablePartyFieldsIfQuotationRefGuide(party);
                    $('i[id$="_removed"]').hide();
                }
                $('a[id$="supplementaryDetails_addButton"]').parent().hide();
                break;
        }

    }
}

function disablePartyFieldsIfQuotationRefGuide(party){
    setReadOnly($('#' + party +'_extensionName1'), true);
    setReadOnly($('#' + party +'_extensionName2'), true);
    setReadOnly($('#' + party +'_age'), true);
    $('input[type="radio"][id*="' + party +'_genderCd"]').checkboxradio().checkboxradio('disable').trigger("refresh");
    $('#' + party +'_birthDt').addClass('inputreadonly');
}

$(document).ready(function () {
    $("#quicklink_VIEWILLUSTRATION").hide();
    $("#quicklink_EAPPPREVIEW").hide();
    $("#quicklink_declaration").hide();
});