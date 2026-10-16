$(document).ready(function () {
	$(".search-header-fixed").fixMe(); 
	$('tr td b p[id="SearchPolicyDO_policyNum_lbl"]').each(function () {
		var innerHtml = $(this).parents('td').find("span.field-value").html();
		if(innerHtml==""){
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="reUploadImages"]').parent().hide();
		}
	});
	$('tr td b p[id="SearchPolicyDO_overallUWDecisionCd_lbl"]').each(function () {
		var innerHtml = $(this).parents('td').find("span.field-value").html();
		if (innerHtml == null || innerHtml == undefined || innerHtml == ""){
			$(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="showPolicyResult"]').parent().hide();
		}
	});
	
	// $('.delete-confirm-bg .search-btn-bg a#delete').click(function() {
	// if($("input:checkbox[name='deleteCheck[]']:checked").length > 0) {
	// 		deletePopup(this, 'DELETE_CONFIRMATION','Policy');
	// 	}
	// });
});

function SearchPolicyCriteriaDO_baseProductId_onFocus(obj){
	if (obj != null){
		id = obj.id;
		lookupkey = obj.getAttribute("data-lookupkey");
		filterCondition = {};
		loadLookupData(lookupkey, filterCondition, id);
	}
}


function deletePolicy_Callback_func(argument) {
	document.forms[0].submit();
}