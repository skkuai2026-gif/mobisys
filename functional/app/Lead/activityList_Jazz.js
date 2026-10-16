$(document).ready(function () {
	$(".advance-search-btn").click(function(){
		$('[data-field = "datetime"]').attr("data-field","date");
	});

});

function typechange(duration)
{
	$("#currentTab").val(duration);
	$("#index").val(0);
	document.getElementById('activitySearchForm').submit();
}

function indexchange(index)
{
	var previousval = parseInt($("#index").val());
	if (index == "NEXT")
	{
		$("#index").val(previousval+1);
	}
	else
	{
		$("#index").val(previousval-1);
	}
	document.getElementById('activitySearchForm').submit();
}

$('.delete-confirm-bg .search-btn-bg a#delete').click(function() {
	if($("input:checkbox[name='deleteCheck[]']:checked").length > 0) {
		deletePopup(this,'DELETE_CONFIRMATION','Activity');
	}
});

function deleteActivity_Callback_func(argument) {
	document.forms[0].submit();
}

function deleteNOActivity_Callback_func(argument) {
}
