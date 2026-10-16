$(document).ready(function(){
    tab_basic_pageTabLoaded();
});

function tab_basic_pageTabLoaded(){
    toggleOnFocus();
    enableDisableQuickLinks();
}


function tab_questionnaire_pageTabLoaded(){
    $(".questionnaireDiv input[type='checkbox']").click(function(){
        $('[name="'+$(this).attr('name')+'"]').prop("checked", false).checkboxradio("refresh");
        $(this).prop("checked", true).checkboxradio("refresh");
    });
    toggleOnFocus();
    enableDisableQuickLinks();
    if ($('#leadRPQ_statusCd').val() == "SIGNED"){
        disableAllFormFields();
    }
}


function tab_signature_pageTabLoaded(){
    initializeSignature();
    toggleOnFocus();
    enableDisableQuickLinks();
    if ($('#leadRPQ_statusCd').val() == "SIGNED"){
        disableAllFormFields();
    }
}


function submitForm(currentTab) {
    return true;
}

function enableDisableQuickLinks(){
    var statusCd = $('#leadRPQ_statusCd').val();
    if (statusCd == "SIGNED"){
        $(".quicklink-details, .quicklink").show();
        $(".quicklink-details ul li[id='quicklink_CAPTUREILLUSTRATION']").show();
    }
    else{
        $(".quicklink-details, .quicklink").hide();
        $(".quicklink-details ul li[id='quicklink_CAPTUREILLUSTRATION']").hide();
    }
    hideShowQuickLinkIcon();
}

// Hide show quick link icon if there are no links shown
function hideShowQuickLinkIcon(){
    var hiddenQuickLinkCount = 0
    var totalQuickLinkCount = $('.quicklink-details ul li').length;
    $('.quicklink-details ul li').each(function(){
        if ($(this).css('display') == 'none'){
            hiddenQuickLinkCount = hiddenQuickLinkCount + 1;
        }
    });
    if(totalQuickLinkCount == hiddenQuickLinkCount){
        $("#additionalOptionsFl").val('false');
    }
    else{
        $("#additionalOptionsFl").val('true');
    }
}
