$(document).ready(function(){
	initializeSignature();
	$("a[data-rel='popup']").click(function(){
		$("#exclusionExtra tbody tr").hide();
		$("#exclusionExtra tbody tr#"+$(this).attr("data-popupID")).show();

		$("#loadingExtra tbody tr").hide();
		$("#loadingExtra tbody tr."+$(this).attr("data-popupID")).show();
	});


	if($("#uwType").val()=="TYPE3" || $("#uwType").val()=="TYPE4"){
		var checklistFl = true;
		$(".checklist").each(function(){
			if($(this).val() != "DONE"){
				checklistFl = false;
			}
		});

		$("#okButton").hide();
		if($("#policy_counterOfferDecisionCd").val()==""){
			$("#counterOfferDecisionCdText").hide();
			$("#counterOfferSignatureDiv").hide();
			$("#checklist-header").hide();
			$("#checklist-chart").hide();
			$("#counterOfferDiv").show();
		}
		else if($("#policy_counterOfferDecisionCd").val()=="ACCEPTED"){
			$("#counterOfferDiv").show();
			$("#counterOfferActions").hide();
			if(checklistFl){
				$("#quotationActions").hide();
				disableAllFormFields();
			}
			if($("#quotationChecklist").val() == "DONE"){
				$("#quotationActions").hide();
			}
		}
		else {
			$("#counterOfferDecisionCdText").show();
			$("#counterOfferSignatureDiv").hide();
			$("#checklist-header").hide();
			$("#checklist-chart").hide();
			$("#counterOfferDiv").show();
		}
	}
	else {
		$("#okButton").hide();
		$("#counterOfferDiv").hide();
	}


	$("#acceptButton").click(function () {
		$("#counterOfferActions").hide();
		$("#counterOfferDecisionCdText span").html('ACCEPTED');
		$("#counterOfferDecisionCdText").show();
		$("#policy_counterOfferDecisionCd").val('ACCEPTED');

		if($("#uwType").val()=="TYPE4"){
			$.ajax({
				url: "/app/Policy/sendCounterOfferResponse?action=createQuotationCopy",
				data: $('#policyOutputForm').serializeHash(),
				async: false,
				headers: {
					'Transition-Enabled': false
				},
				success: function(data) {
					console.log(data);
					data = JSON.parse(data);
					$("#quotationRefNumText").html(data["quotationRefNum"]);
					$("#viewIllustrationButton").attr("href",data["viewIllustration"]);
					$("#acceptIllustrationButton").attr("href",data["acceptIllustration"]);
					$("#quotationChecklist").val("");
					$("#quotationChecklist").siblings("p").find("img").attr("src","/public/jazz/images/progress-pending.png");
					$("#quotationActions").show();
					$("#checklist-header").show();
					$("#checklist-chart").show();
					$("#counterOfferSignatureDiv").show();
					$("#counterOfferSignature_removed").val("");
				}
			});
		}
		else if($("#uwType").val()=="TYPE3"){
			$("#checklist-header").show();
			$("#checklist-chart").show();
			$("#counterOfferSignatureDiv").show();
			$("#counterOfferSignature_removed").val("");
		}
	});


	$("#rejectButton").click(function () {
		$("#checklist-header").hide();
		$("#checklist-chart").hide();
		$("#counterOfferActions").hide();
		$("#counterOfferSignatureDiv").hide();
		$("#counterOfferDecisionCdText span").html('DECLINED');
		$("#counterOfferDecisionCdText").show();
		$("#policy_counterOfferDecisionCd").val('DECLINED');
		$("#counterOfferSignature_removed").val("YES");
		$("#okButton").show();
	});


	$("#okButton, #editProposalButton, #captureAdditionalRequirementsButton").click(function () {
		document.policyOutputForm.submit();
	});

	$("canvas.jSignature").bind("click touchstart", function(){
		$("#signatureChecklist").val("DONE");
		var checklistFl = true;
		$(".checklist").each(function(){
			if($(this).val() != "DONE"){
				checklistFl = false;
			}
		});

		if(checklistFl){
			$("#okButton").show();
		}
	});
});