$(document).ready(function(){
	var offlineApplicationEnvironment = $("#offlineApplicationEnvironment").val();
	var productFamilyCd = $("#basePlan_productFamilyCd").val();
	var productId = $("#basePlan_productId").val();
	var productSeq = $("#basePlan_productSeq").val();
	var productVersion = $("#basePlan_productVersion").val();
	var productPlanOptionCd = $("#basePlan_productPlanOptionCd").val();
	var columnWidth = $('#noOfColumnsFor'+productSeq).val();
	var numberOfPlanOptions = $('#countOfPlanOptionsFor'+productSeq).val();

	var onLoad = true;

	$(".plan_list, .version_list").hide();

	$(".selectProductPlan").click(function(){
		if(offlineApplicationEnvironment == "UAT"){
			var selector = $(".plan-option-wrapper div[data-parent='"+$(".selectProductVersion:checked").val()+"'] .selectProductPlan:checked");
		}
		else{
			var selector = $(".plan-option-wrapper div[data-parent='"+$(".selectProductId:checked").val()+"'] .selectProductPlan:checked");
		}
	});


	$(".selectProductVersion").click(function(){
		var selectedProductVersion = $(".selectProductVersion:checked");
		// Hide Plan section
		$(".plan_list").hide();

		// Clear Plan Section
		if(!onLoad){
			$(".selectProductPlan").prop("checked", false).checkboxradio().checkboxradio("refresh");
			$(".plan-option-wrapper").css('left','0%');
		}
		if(selectedProductVersion.length > 0){
			$(".product-page-col-1").animate({'width': columnWidth+'%'},500);
			$(".product-page-col-2").animate({'width': columnWidth+'%'},500);
			$(".product-page-col-2").animate({'left': columnWidth+'%'},500);
		}

		// Render Plan Section
		for(var i = 3; i <= (2+parseInt(numberOfPlanOptions)); i++)
	    {
			animateArea = (columnWidth*(i-1)).toFixed(2);
			$(".product-page-col-"+i).animate({'left': animateArea+'%'},500);
			$(".product-page-col-"+i).animate({'width': columnWidth+'%'},500);
	    }
		$(".plan-option-wrapper div[data-parent='"+selectedProductVersion.val()+"'] h4").html(selectedProductVersion.data('label'));
		$(".plan-option-wrapper div[data-parent='"+selectedProductVersion.val()+"']").show();

		onLoad = false;
	});


	$(".selectProductId").click(function(){
		var selectedProductId = $(".selectProductId:checked");
		var productSeq = selectedProductId.attr('id');
		var selectProductVersion = $(".selectProductVersion:checked");
		// Hide Version & Plan section
		$(".plan_list, .version_list").hide();

		// Clear Version section
		if(!onLoad){
			$(".selectProductVersion, .selectProductPlan").prop("checked", false).checkboxradio().checkboxradio("refresh");
			$(".plan-option-wrapper, .plan-version-wrapper").css('left','0%');
		}
		else{
			// Trigger Version section change
			if(offlineApplicationEnvironment == "UAT"){
				$(".selectProductVersion:checked").click();
			}
			else{
				onLoad = false;
			}
		}
		columnWidth = $('#noOfColumnsFor'+productSeq).val();
		numberOfPlanOptions = $('#countOfPlanOptionsFor'+productSeq).val();

		// Show Version section
		if(offlineApplicationEnvironment == "UAT"){
			if(selectProductVersion.length > 0 ){
				$(".plan-version-wrapper").animate({'left': columnWidth+'%'},500);
				$(".plan-version-wrapper").animate({'width': columnWidth+'%'},500);
			}
			else{
				$(".plan-version-wrapper").animate({'left': '25%'},500);
				$(".plan-version-wrapper").animate({'width': '25%'},500);
			}
			$(".plan-version-wrapper div[data-parent='"+selectedProductId.val()+"'] h4").html(selectedProductId.data('label'));
			$(".plan-version-wrapper div[data-parent='"+selectedProductId.val()+"']").show();
		} 
		else {
			if(selectedProductId.length > 0){
				$(".product-page-col-1").css('width',columnWidth+'%');
				$(".product-page-col-1").animate({'width': columnWidth+'%'},500);
			}
			// i is starting from 2 because product has no version directly plan options
			for(var i = 2; i <= (1+parseInt(numberOfPlanOptions)); i++)
		    {
				animateArea = (columnWidth*(i-1)).toFixed(2);
				$(".product-page-col-"+i).css('width',columnWidth+'%');
				$(".product-page-col-"+i).animate({'left': animateArea+'%'},500);
				$(".product-page-col-"+i).animate({'width': columnWidth+'%'},500);
		    }
			$(".plan-option-wrapper div[data-parent='"+selectedProductId.val()+"'] h4").html(selectedProductId.data('label'));
			$(".plan-option-wrapper div[data-parent='"+selectedProductId.val()+"']").show();
		}
	});


	// Trigger Product section change
	$(".selectProductId:checked").click();

	if ($(".footer-bg a").length == 4) {
		$(".footer-bg a:eq(0),.footer-bg a:eq(2),.footer-bg a:eq(3),.section-tab a").click(function(event){
			if (!submitValidate()){
				event.preventDefault();
				event.stopPropagation();
			}
		});
	}
	else {
		$(".footer-bg a:eq(1),.footer-bg a:eq(2),.section-tab a").click(function(event){
			if (!submitValidate()){
				event.preventDefault();
				event.stopPropagation();
			}
		});
	}
});



function submitValidate(){
	var offlineApplicationEnvironment = $("#offlineApplicationEnvironment").val();

	var productId = $(".selectProductId:checked").val();
	if (productId === undefined){
		raiseAlert("PLEASE_SELECT_PRODUCT",[],locale);
    	return false;
	}
	else{
		if(offlineApplicationEnvironment == "UAT"){
			var productVersion = $(".version_list[data-parent='"+productId+"'] .selectProductVersion:checked").val();
			if (productVersion === undefined){
				raiseAlert("ERR_PLZSELECT",[getLabel("productVersion",locale)],locale);
	        	return false;
			}
			else{
				if ($(".plan_list[data-parent='"+productVersion+"'] .selectProductPlan").length>0 && $(".plan_list[data-parent='"+productVersion+"'] .selectProductPlan:checked").val() === undefined){
					raiseAlert("ERR_PLZSELECT",[getLabel("planOptionCd",locale)],locale);
        			return false;
				}
			}
		}
		else{
			if ($(".plan_list[data-parent='"+productId+"'] .selectProductPlan").length>0 && $(".plan_list[data-parent='"+productId+"'] .selectProductPlan:checked").val() === undefined){
				raiseAlert("ERR_PLZSELECT",[getLabel("planOptionCd",locale)],locale);
    			return false;
			}
		}
	}
	return true;
}