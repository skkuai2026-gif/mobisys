$(document).ready(function(){
	var offlineApplicationEnvironment = $("#offlineApplicationEnvironment").val();
	var productFamilyCd = $("#basePlan_productFamilyCd").val();
	var productId = $("#basePlan_productId").val();
	var productSeq = $("#basePlan_productSeq").val();
	var productVersion = $("#basePlan_productVersion").val();
	var productPlanOptionCd = $("#basePlan_productPlanOptionCd").val();
	var onLoad = true;

	$(".product_list, .plan_list, .version_list").hide();

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
			$(".product-page-col-4").css('left','0%');
		}

		// Render Plan Section
		$(".product-page-col-4").animate({'left': '75%'},500);
		$(".product-page-col-4 div[data-parent='"+selectedProductVersion.val()+"'] h4").html(selectedProductVersion.data('label'));
		$(".product-page-col-4 div[data-parent='"+selectedProductVersion.val()+"']").show();

		onLoad = false;
	});


	$(".selectProductId").click(function(){
		var selectedProductId = $(".selectProductId:checked");
		// Hide Version & Plan section
		$(".plan_list, .version_list").hide();

		// Clear Version section
		if(!onLoad){
			$(".selectProductVersion, .selectProductPlan").prop("checked", false).checkboxradio().checkboxradio("refresh");
			$(".plan-option-wrapper, .product-page-col-4").css('left','0%');
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

		// Show Version section
		if(offlineApplicationEnvironment == "UAT"){
			$(".plan-option-wrapper").animate({'left': '50%'},500);
		} 
		else {
			$(".plan-option-wrapper").animate({'left': '66.66%'},500);
		}
		$(".plan-option-wrapper div[data-parent='"+selectedProductId.val()+"'] h4").html(selectedProductId.data('label'));
		$(".plan-option-wrapper div[data-parent='"+selectedProductId.val()+"']").show();
	});


	$(".selectProductFamily").click(function(){
		// Hide Product, Version & Plan section
		$(".product_list, .plan_list, .version_list").hide();

		// Clear Product section
		if(!onLoad){
			$(".selectProductId, .selectProductVersion, .selectProductPlan").prop("checked", false).checkboxradio().checkboxradio("refresh");
			$(".product-name-wrapper, .plan-option-wrapper, .product-page-col-4").css('left','0%');
		}
		else{
			$(".selectProductId:checked").click();
		}

		// Show Product section
		if(offlineApplicationEnvironment == "UAT"){
			$(".product-name-wrapper").animate({'left': '25%'},500);
		} 
		else {
			$(".product-name-wrapper").animate({'left': '33.33%'},500);
		}
		$(".product-name-wrapper div[data-parent='"+$(".selectProductFamily:checked").val()+"']").show();
	});


	// Trigger Family section change
	$(".selectProductFamily:checked").click();

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
	var productFamily = $(".selectProductFamily:checked").val();

	if (productFamily === undefined){
		if ($("#basePlan_productFamilyCd").val() != ""){
			raiseAlert("PLEASE_SELECT_PRODUCT_FAMILY",[],locale);
	        return false;
	    }
	}
	else{
		var productId = $(".product_list[data-parent='"+productFamily+"'] .selectProductId:checked").val();
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
	}
	return true;
}