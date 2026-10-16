var act_object1
$(document).ready(function () {  
    $(".search-header-fixed").fixMe();  
    $('tr td b p[id="SearchLeadDO_statusCd_lbl"]').each(function () { 
        var innerHtml = $(this).parents('td').find("span.field-value").html();   
        if (innerHtml == getLabel('CLOSED',locale)) {
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="#closeLead"],.action-toggle-bg .action-status-show a[href*="/addGFNA"],.action-toggle-bg .action-status-show a[href*="/addFNA"],.action-toggle-bg .action-status-show a[href*="/addQuotation"]').parent().hide();
        }
        else if(innerHtml == getLabel('COMPLETE',locale)){
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="/addGFNA"],.action-toggle-bg .action-status-show a[href*="/addFNA"],.action-toggle-bg .action-status-show a[href*="/addQuotation"],.action-toggle-bg .action-status-show a[href*="#closeLead"]').parent().show();
        }
        else{
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="/addGFNA"],.action-toggle-bg .action-status-show a[href*="/addFNA"],.action-toggle-bg .action-status-show a[href*="/addQuotation"]').parent().hide();
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="#closeLead"]').parent().show();
        } 
    });

    // $('.delete-confirm-bg .search-btn-bg a#delete').click(function() {
    //     if($("input:checkbox[name='deleteCheck[]']:checked").length > 0) {
    //         deletePopup(this,'DELETE_CONFIRMATION','LEADS');
    //     }
    // });

    $('.action-toggle-bg .action-status-show a[href*="closeLead"]').click(function(){
        var object = $(this).attr('href');
        act_object1 = object.substring(object.indexOf("{")+1,object.indexOf("}"));
        deletePopup(object,"CLOSELEAD",'SearchLead');
    });
});

function deleteLEADS_Callback_func(argument) {
	document.forms[0].submit();
}

function deleteSearchLead_Callback_func(object){ 
    var act_object = act_object1
     $.ajax({
        url: "/app/Lead/closeLead",
        data: {'lead_object': act_object,'source':"search"},
        success: function(data){
            location.reload();
        }
     }); 
}

function deleteNoSearchLead_Callback_func(object){

}