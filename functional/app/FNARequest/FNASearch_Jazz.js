$(document).ready(function () {
	$(".search-header-fixed").fixMe(); 
	$('tr td b p[id="SearchFNADO_statusCd_lbl"]').each(function () {
		var innerHtml = $(this).parents('td').find("span.field-value").html();
		if(innerHtml == getLabelValue('FNASIGNED') || innerHtml == getLabelValue('FNASUBMIT') || innerHtml == getLabelValue('SYNCDONE')){
			$(this).parents('tr').find('.delete-checkbox').children().hide()
		}
	});

	$('.delete-confirm-bg .search-btn-bg a#delete').click(function() {
		if($("input:checkbox[name='deleteCheck[]']:checked").length > 0){
			deletePopup(this,'DELETE_CONFIRMATION','FNA');
		}
	});
});

function deleteFNA_Callback_func(obj) {
	document.forms[0].submit();
}