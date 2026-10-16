$(document).ready(function () {
	$(".search-header-fixed").fixMe();
	
	$("a[href *= '#summaryPopUp']").on("click",function(){
		var href_string = $(this).attr("href");
		var object_string = href_string.substring(href_string.indexOf("{")+1,href_string.indexOf("}"));
		$.ajax({
			url: "/app/Quotation/summarypopup",
			data: {'quotation_object':object_string,'trigger_source':'search'},
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
                }
			}
		});
	});
	$('tr td b p[id="SearchProspectDO_quoteStatusCd_lbl"]').each(function () {	
		var innerHtml = $(this).parents('td').find("span.field-value").html();
		if(innerHtml == getLabel('ACCEPTED',locale) || innerHtml == getLabel('SYNCDONE',locale)){
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="view_email"]').parent().show();
		}
		else if (innerHtml == getLabel('COMPLETED',locale) || innerHtml == getLabel('ACCEPTED',locale) || innerHtml == getLabel('SYNCDONE',locale))
		{
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="summaryPopUp"]').parent().show();
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="view_email"]').parent().hide();
		}
		else{
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="view_email"]').parent().hide();
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="summaryPopUp"]').parent().hide();
		}	
	});


});



function summaryPopupClose() {
}

function deleteQUOTATION_Callback_func(argument) {
	document.forms[0].submit();
}