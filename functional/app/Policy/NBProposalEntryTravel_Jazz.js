function tab_travellerDetails_pageTabLoaded(){
	initializeTab();
}

function tab_paymentGateway_pageTabLoaded(){

}

/********* Supplementary Life related functions *********/
function supplementaryDetails_addButton_func(object){
	var suplementaryInsuredCount = parseInt($('#suplementaryInsuredCount').val());
	var supPolicyProductCount = parseInt($('#supPolicyProductCount').val());
	var displayCount = $('#supplementaryDetails_addButton .button-add-section .notification').text();
	currentTab = $('#sym_current_Tab').val();
	 $.ajax({
        url: "/app/Policy/addMoreTraveller",
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
        }
    });
}
