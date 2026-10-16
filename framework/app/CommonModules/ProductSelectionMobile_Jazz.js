$(document).ready(function(){
	var offlineApplicationEnvironment = $("#offlineApplicationEnvironment").val();
	var onLoad = true;
	//insert product list into family list collapsible panel
	$(".product_list").each(function(){
		dataParent = $(this).attr("data-parent");
		$(this).detach().appendTo($("[data-familyid='" + dataParent + "']"));
		$("[data-familyid='" + dataParent + "']").append("<div class='clearfix'></div>");

	});

	// insert product version list into product list collapsible panel
	$(".version_list").each(function(){
		dataParent = $(this).attr("data-parent");
		$(this).detach().appendTo($("[data-productid='" + dataParent + "']"));
		$("[data-familyid='" + dataParent + "']").append("<div class='clearfix'></div>");

	});

	// insert plan list into product or product version list collapsible panel
	$(".plan_list").each(function(){
		dataParent = $(this).attr("data-parent");
		if(offlineApplicationEnvironment == "UAT"){
			$(this).detach().appendTo($("[data-versionid='" + dataParent + "']"));
		}
		else{
			$(this).detach().appendTo($("[data-productid='" + dataParent + "']"));	
		}

		$("[data-familyid='" + dataParent + "']").append("<div class='clearfix'></div>");
	});
	$(".product-selection-wrapper-mobile").enhanceWithin();

	$(".selectProductFamily").click(function(){
		if (onLoad == true){
			$(this).parents(".ui-collapsible").trigger("expand").collapsible("refresh");
			$(".selectProductId:checked").click();
		}
		else{
			$(this).parents(".ui-collapsible").collapsible("expand");
		}
		
	});

	$(".selectProductId").click(function(){
		$(".selectProductId").parents(".ui-collapsible").collapsible("collapse");
		if(onLoad){
			$(this).parents(".ui-collapsible").trigger("expand").collapsible("refresh");
			if (offlineApplicationEnvironment == "UAT"){
				$(".selectProductVersion:checked").click();
			}
		}
		else{
			$(this).parents(".ui-collapsible").collapsible("expand");
			$(".selectProductPlan").prop("checked", false).checkboxradio().checkboxradio("refresh");
		}
	});

	$(".selectProductVersion").click(function(){
		$(".selectProductVersion").parents(".ui-collapsible").collapsible("collapse");
		if(onLoad){
			$(this).parents(".ui-collapsible").trigger("expand").collapsible("refresh");
		}
		else{
			$(this).parents(".ui-collapsible").collapsible("expand");
			$(".selectProductPlan").prop("checked", false).checkboxradio().checkboxradio("refresh");
		}
	});

	$(".selectProductPlan").click(function(){
		var selectProductId = $(this).parents(".plan_list").attr("data-parent");
		$("#"+selectProductId).attr("checked",true).checkboxradio("refresh");
	});
	
	$(".selectProductFamily:checked").click();

	onLoad = false;	

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