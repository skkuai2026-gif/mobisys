//Function to hide/show as well as clear fields based on reflexive mapping
$.fn.reflexiveParentChildDisplayMapping = function(parentObj) {
	parentObj = $(parentObj);
	var parent = parentObj.data("questioncd");
	var applyOn = parentObj.data("applyon");
	var reflexiveValue = parentObj.val();
	if (parentObj.attr("type") == "radio") {
		var reflexiveValue = $("input[name='"+parentObj.attr("name")+"']:checked").val();
	}
	else{
		var reflexiveValue = parentObj.val();
	}

	var childTobeLoaded = parent+'|'+reflexiveValue;
	// calling ajax to populate child questions
	if (childTobeLoaded != null && childTobeLoaded != undefined && childTobeLoaded != ''){
		// loadChildQuestions(childTobeLoaded, parentObj.attr("name")); 
		// driving_parent = parent.split('|')[0];
		evaluateChildQuestions(parent, parentObj.attr("name"),childTobeLoaded);
		attachFieldEvents();
	}

	if (applyOn == 'YES'){
		var impactedQSetCds = parentObj.data("impactedqsetcds");
		driving_parent = parent.split('|')[0];
		getExpressionBasedChildQuestions(impactedQSetCds, driving_parent, parentObj);
		attachFieldEvents();
	}

	var nonMatchingReflexiveSelStr = "[data-parent='"+parent+"'][data-reflexivevalue!='"+reflexiveValue+"']";
	var matchingReflexiveSelStr = "[data-parent='"+parent+"'][data-reflexivevalue='"+reflexiveValue+"']";
	
	//Clear/reset fields
	$(nonMatchingReflexiveSelStr+"input[type='text']").each(function(){
		if($(this).val() != "") {
			$(this).val("").change();		
		}
	});
	$(nonMatchingReflexiveSelStr+"input[type='number']").each(function(){
		if($(this).val() != "") {
			$(this).val("").change();		
		}
	});
	$(nonMatchingReflexiveSelStr+"input[type='tel']").each(function(){
		if($(this).val() != "") {
			$(this).val("").change();		
		}
	});
    $(nonMatchingReflexiveSelStr+"textarea").each(function(){
		if($(this).val() != "") {
			$(this).val("").change();		
		}
	});
	$(nonMatchingReflexiveSelStr+"input[type='radio']").each(function(){
		if($(this).is(":checked")) {
			$(this).prop("checked", false).checkboxradio("refresh");
			$(this).reflexiveParentChildDisplayMapping(this);
		}
	})
	$(nonMatchingReflexiveSelStr+"input[type='checkbox']").prop("checked", false).checkboxradio("refresh").change();
	$(nonMatchingReflexiveSelStr+"select").each(function(){
		if($(this).val() != "") {
			$(this).val("").change();
		}
	});
	$(nonMatchingReflexiveSelStr+"input[name*='removed']").val("YES").change();
	$(matchingReflexiveSelStr+"input[name*='removed']").val("").change();

	//Hide questions or the entire block if the target question is the last visible question in the div
	$(nonMatchingReflexiveSelStr).parents("li.questionGrid").hide();
	$(nonMatchingReflexiveSelStr).each(function(){
        var parents = $(this).parents("li.questionGrid");
		if (parents.siblings("li.questionGrid[style!='display: none;']").length <= 0) {
            var questionSetBlock = parents.closest("ul.questionSetBlock");
            questionSetBlock.hide();
            if(questionSetBlock.siblings("li.questionGrid[style!='display: none;']").length <= 0) {
            	questionSetBlock.closest("div.sub-questionnaire-bg").hide();
            }
			if ($(this).parents("ul.questionSetBlock").find(".deleteButton").length > 0) {
				var hideDiv = $(this).parents(".questionSetBlock:first");
				if (!(typeof hideDiv.data("rowguid") === typeof undefined) && hideDiv.attr("data-rowguid") != "0") {
					hideDiv.hide();
					hideDiv.attr("data-removed", "true");
					hideDiv.find("input[name*='removed']").val("YES");
				}
			}
            questionSetBlock.siblings("div.addMoreButtonBlock[for='"+questionSetBlock.attr("for")+"']").hide();
		}
	});

	//Show questions or the entire block if the entire block is hidden
	$(matchingReflexiveSelStr).parents("li.questionGrid:not('.dummyQuestionClass')").show();
	$(matchingReflexiveSelStr).each(function(){
		var closestDiv = $(this).parents("li.questionGrid").closest("ul.questionSetBlock");
		if (closestDiv.attr("data-removed") == "false" || typeof closestDiv.data("removed") === typeof undefined) {
			closestDiv.show();
			closestDiv.closest("div.sub-questionnaire-bg").show();
		}
        closestDiv.siblings("div.addMoreButtonBlock[for='"+closestDiv.attr("for")+"']").show();
	});
	
	$("li.questionGrid[style='display:none;']").each(function(){
		if($(this).siblings("li.questionGrid:visible").length <= 0) {
			if ($(this).siblings('div.sub-questionnaire-bg:visible').length > 0){
				return;
			}
			questionSetBlock = $(this).closest("ul.questionSetBlock");
			questionSetBlock.hide();
			if(questionSetBlock.siblings("li.questionGrid:visible").length <= 0) {
				questionSetBlock.closest("div.sub-questionnaire-bg").hide();
			}
		}
	});
}


//Function to clone a block of grid questions with updated object mapping
function cloneGridQuestions(originalDiv, gridQuestionCount) {
	var newDiv = originalDiv.clone();
	var newRowGuid = parseInt(newDiv.data("rowguid")) + 1;
	//Update rowGuid
	newDiv.find("[name*='[rowGuid]']").val(newRowGuid);
	newDiv.attr("data-rowguid", newRowGuid);
	oldNewNameMapping = {};
	//Update ServiceQuestionResponse object index in id, name & value attributes
	newDiv.find("[name^='QuestionContainer[ServiceQuestionResponse]['],[value^='QuestionContainer[ServiceQuestionResponse]['],[id^='QuestionContainer[ServiceQuestionResponse]['],[for^='QuestionContainer[ServiceQuestionResponse][']").each(function(){
		if (typeof $(this).attr("name") !== typeof undefined && $(this).attr("name") !== false) {
			var oldName = $(this).attr("name");
			var index1 = oldName.indexOf("QuestionContainer[ServiceQuestionResponse][") + "QuestionContainer[ServiceQuestionResponse][".length;
			var oldCount = oldName.substr(index1, oldName.substr(index1).indexOf("]"))
			var newCount = parseInt(oldCount) + parseInt(gridQuestionCount);
			var oldNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+oldCount+"]";
			var newNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+newCount+"]";
			$(this).attr("name", oldName.replace(oldNamePrefix, newNamePrefix));
			oldNewNameMapping[oldNamePrefix] = newNamePrefix;
		}

		if (typeof $(this).attr("id") !== typeof undefined && $(this).attr("id") !== false) {
			var oldName = $(this).attr("id");
			var index1 = oldName.indexOf("QuestionContainer[ServiceQuestionResponse][") + "QuestionContainer[ServiceQuestionResponse][".length;
			var oldCount = oldName.substr(index1, oldName.substr(index1).indexOf("]"))
			var newCount = parseInt(oldCount) + parseInt(gridQuestionCount);
			var oldNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+oldCount+"]";
			var newNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+newCount+"]";
			$(this).attr("id", $(this).attr("id").replace(oldNamePrefix, newNamePrefix)+newRowGuid);
			oldNewNameMapping[oldNamePrefix] = newNamePrefix;
		}

		if (typeof $(this).val() !== typeof undefined && $(this).val() !== false) {
			if (typeof $(this).val() == "number"){
				var oldName = $(this).val().toString();
			}
			else{
				var oldName = $(this).val();
			}
			var index1 = oldName.indexOf("QuestionContainer[ServiceQuestionResponse][") + "QuestionContainer[ServiceQuestionResponse][".length;
			var oldCount = oldName.substr(index1, oldName.substr(index1).indexOf("]"))
			var newCount = parseInt(oldCount) + parseInt(gridQuestionCount);
			var oldNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+oldCount+"]";
			var newNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+newCount+"]";
			if (typeof $(this).val() == "number"){
				$(this).val($(this).val().toString().replace(oldNamePrefix, newNamePrefix));
			}
			else{
				$(this).val($(this).val().replace(oldNamePrefix, newNamePrefix));
			}
			oldNewNameMapping[oldNamePrefix] = newNamePrefix;
		}

		if (typeof $(this).attr("for") !== typeof undefined && $(this).attr("for") !== false) {
			var oldName = $(this).attr("for");
			var index1 = oldName.indexOf("QuestionContainer[ServiceQuestionResponse][") + "QuestionContainer[ServiceQuestionResponse][".length;
			var oldCount = oldName.substr(index1, oldName.substr(index1).indexOf("]"))
			var newCount = parseInt(oldCount) + parseInt(gridQuestionCount);
			var oldNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+oldCount+"]";
			var newNamePrefix = "QuestionContainer[ServiceQuestionResponse]["+newCount+"]";
			$(this).attr("for", $(this).attr("for").replace(oldNamePrefix, newNamePrefix));
			oldNewNameMapping[oldNamePrefix] = newNamePrefix;
		}
	});
	// manipulating the script tags of all controls
	newDiv.find('script').each(function() {
		for (var key in oldNewNameMapping) {
		  if (oldNewNameMapping.hasOwnProperty(key)) {
			scriptText = $(this).text();
            scriptText = scriptText.replace(key,oldNewNameMapping[key]);
        	eval($(this).text(scriptText));
		  }
		}
	})

	//Update ServiceQuestionResponse object & guid values in id, name & value attributes
	newObjVal = parseFloat(new Date().getTime().toString() + (newDiv.find("[name*='[object]']")[0].value%100).toPrecision(4));
	newDiv.find("[name*='[object]']").each(function(){
		oldObjVal = $(this).val();
		newObjVal = newObjVal + 1; 
		var newGuid = newObjVal.toString().replace(".", "_");
		var name = $(this).attr("name").substring(0, $(this).attr("name").lastIndexOf("["));

		$(this).val(newObjVal);
		newDiv.find("[name='"+name+"[guid]']").val(newGuid);
		newDiv.find("[name='"+oldObjVal+"']").attr("name", newObjVal);
	});

	//Add block delete button if not present while cloning div
	if (newDiv.find(".deleteButtonBlock").length <= 0) {
		var deleteButton = "<div class='ui-grid-d deleteButtonBlock'><div class='ui-block-a'></div><div class='ui-block-b'></div><div class='ui-block-c'></div><div class='ui-block-d'></div><div class='ui-block-e'>"
		deleteButton += "<div class='ui-btn ui-input-btn ui-corner-all ui-shadow ui-btn-inline ui-icon-delete ui-btn-icon-notext'>"
		deleteButton += "<input type='button' data-inline='true' data-icon='delete' data-iconpos='notext' class='deleteButton'>";
		deleteButton += "</div>";
		deleteButton += "</div></div>"
		newDiv.prepend(deleteButton);
	}

	//Clear/reset fields
	newDiv.find("input[type='text']").val("");
	newDiv.find("input[type='number']").val("");
	newDiv.find("input[type='tel']").val("");
    newDiv.find("textarea").val("");

	newDiv.find('label').each(function(){
		var oldName = $(this).attr("for");
		var newName = oldName+newRowGuid.toString();
		$(this).attr("for", $(this).attr("for").replace(oldName, newName));
	})

	newDiv.find('.ui-select, .ui-radio, .ui-controlgroup-controls, .ui-input-btn').each(function() {
		$(this).find('select').val("");
		$(this).after($(this).find('select'));

		$(this).after($(this).find('label'));
		$(this).find('input[type="radio"]').removeProp("checked");
		$(this).after($(this).find('input[type="radio"]'));
		$(this).find('input[type="checkbox"]').removeProp("checked");
		$(this).after($(this).find('input[type="checkbox"]'));

		$(this).after($(this).find('input'));

		$(this).remove();
	});

	newDiv.find('.dateicon').each(function() {
		var inputDiv = $(this).find('div');
		inputDiv.replaceWith(inputDiv.html());
		var input = $(this).find('.datepicker');
		input.attr("id",input.attr("id")+"_"+newRowGuid);
	});

	originalDiv.after(newDiv);
	originalDiv.parent().trigger('create');
	newDiv.find('script').each(function(){
      eval($(this).text());
    });

	attachFieldEvents();
}


//Common function to attach all field level events
function attachFieldEvents(){
	$(".deleteButton").click(function(){
		var hideDiv = $(this).parents(".questionSetBlock:first");
		hideDiv.hide();
		hideDiv.attr("data-removed", "true");
		hideDiv.find("input[name*='removed']").val("YES");
	});

	$(".dateField").parents(".ui-input-text").css("width","100px");
	$(".dateField").addClass("ui-input-text");

	$(".amountField,.countField").each(function(){
		$(this).keypress(function(e){
			var regex = new RegExp("^[0-9]+$");
			var str = String.fromCharCode(!e.charCode ? e.which : e.charCode);
			if (regex.test(str) && !e.shiftKey && !e.ctrlKey && !e.altKey) {
		    	return true;
			}

			e.preventDefault();
			return false;
		});
	});

	$(".datepicker:not(.inputreadonly)").removeClass('hasDatepicker').removeData('datepicker').unbind().datepicker({
		showOn: 'focus',
	    showButtonPanel: true,
	    closeText: 'Clear', 
		changeMonth: true,
		changeYear: true,
		dateFormat: "dd/mm/yy",
		yearRange: "c-100:c+100",
		onClose: function () {
        var event = arguments.callee.caller.caller.arguments[0];
            if ($(event.delegateTarget).hasClass('ui-datepicker-close')) {
                $(this).val('');
            }
       	}
	});
}

// Function to load child questions on the fly
function loadChildQuestions(questionToBeLoaded,target) {
	$.ajax({
		url: "/app/Policy/loadChildQuestions",
		data: {'questionToBeLoaded' : questionToBeLoaded},
		async:   false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
        	if (data != ""){
        		var nextLis = $('li[for="'+target+'"]').nextAll('.questionGrid');
        		if (nextLis != null){
        			nextLis.each(function(){
        				childID = $(this).attr('for');
		        		var removedID = childID.replace('responseValue', 'removed');
		        		var parentQuestionCd = $('input[id="'+removedID+'"]').attr('data-parent');
		        		var reflexiveValue = $('input[id="'+removedID+'"]').attr('data-reflexivevalue');
		        		if (parentQuestionCd != null && parentQuestionCd != undefined){
		        			if (parentQuestionCd+'|'+reflexiveValue == questionToBeLoaded){
		        				$('input[id="'+removedID+'"]').parents('li').remove();
		        			}
		        		}
        			})
	        	}

        		var nextDivs = $('li[for="'+target+'"]').nextAll('.sub-questionnaire-bg');
        		if(nextDivs != null){
        			nextDivs.each(function(){
        				childUls = $(this).children('ul');
        				$.each(childUls, function(index, childUl) {
        					if($(childUl).children('li').length == 0){
								$(childUl).parent('.sub-questionnaire-bg').remove();
        					}
        					else{
		        				childID = $(childUl).children('li:first').attr('for');
				        		var removedID = childID.replace('responseValue', 'removed');
				        		var parentQuestionCd = $('input[id="'+removedID+'"]').attr('data-parent');
				        		var reflexiveValue = $('input[id="'+removedID+'"]').attr('data-reflexivevalue');
				        		if (parentQuestionCd != null && parentQuestionCd != undefined){
				        			if (parentQuestionCd+'|'+reflexiveValue == questionToBeLoaded){
				        				$(this).parent('.sub-questionnaire-bg').remove();
				        			}
				        		}
				        	}
        				})
        			})
        		}
        		$('li[for="'+target+'"]').after(data);
        		$('li[for="'+target+'"]').parents('ul').trigger('create');
        	}
        }
	})
}

// Function to load child question on the fly by evaluating expression
function getExpressionBasedChildQuestions(impactedQSetCds, drivingParent, parentObj) {
	target = parentObj.attr("name");
	currentQuestionId = parentObj.attr('id');
	currentQuestionParent = parentObj.data('parent');;
	currentQuestionReflexiveValue = parentObj.data('reflexivevalue');
	// finding length of target's child question
	if ($('li[for="'+target+'"]').next('div.sub-questionnaire-bg').length > 0){
		//Clear/reset child fields only
		$.each($('li[for="'+target+'"]').nextAll(), function(index, each_div) {
			if($(each_div).is('li')){
				return false;
			}
			$.each($(each_div).find("input[type='number'],input[type='tel'],input[type='text'],select"),function(formElement) {
				if($(this).val() != "") {
					$(this).val("");	
				}
			})
			$.each($(each_div).find("input[name*='removed']"),function(formElement) {
				$(this).val("YES");	
			})
			$.each($(each_div).find("input[type='radio']"),function(formElement) {
				if($(this).is(":checked")) {
					$(this).prop("checked", false).checkboxradio("refresh");
				}
			})
		});
    }
	$.ajax({
		url: "/app/Policy/getExpressionBasedChildQuestions",
		data: $('#EAPPProposal').serialize() +'&drivingParent='+drivingParent+'&impactedQSetCds='+impactedQSetCds,
		async:   false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
        	if (data != ""){
                jsonData = JSON.parse(data);
                $.each(jsonData, function(impactedQSetCd, htmlData) {
                	htmlContent = $($.parseHTML(htmlData,null,true));
                	if($('div,li').find('[data-onlyquestionsetcd="'+impactedQSetCd+'"]').length > 0){
                		if($('div').find('div[data-onlyquestionsetcd="'+impactedQSetCd+'"]').length > 0 ){
                			liHtml = (htmlContent).find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]');
                			liSiblingsHtml = (htmlContent).find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').siblings('li,div');
                			$('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').nextAll('.sub-questionnaire-bg').remove();
                			$('li').find('[data-onlyquestionsetcd="'+impactedQSetCd+'"]').replaceWith(liHtml);
                			$('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').after(liSiblingsHtml);
                			$('div').find('[data-onlyquestionsetcd="'+impactedQSetCd+'"]').parents('ul').trigger('create');
                		}
                		else{
                			if ($('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').length > 0){
                				liHtml = (htmlContent).find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]');
                				liSiblingsHtml = (htmlContent).find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').siblings('li,div');
                				$('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').nextAll('.sub-questionnaire-bg').remove();
                				$('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').replaceWith(liHtml);
                				$('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').after(liSiblingsHtml);
                				$('div').find('li[data-onlyquestionsetcd="'+impactedQSetCd+'"]').parents('ul').trigger('create');
                			}
                		}
                	}
                	else{
		                if ($('li[for="'+target+'"]').siblings('div.sub-questionnaire-bg').length > 0){
		                	$('li[for="'+target+'"]').siblings('div.sub-questionnaire-bg').last().after(htmlContent);
		                }
		                else{
		                	$('li[for="'+target+'"]').after(htmlContent);
		                }
		        		$('li[for="'+target+'"]').parents('ul').trigger('create');
		        	}
		        })
		        if(currentQuestionParent != null && currentQuestionParent != undefined){
		        	$('[id="'+currentQuestionId+'"]').attr('data-parent',currentQuestionParent);
		        }
		      	if(currentQuestionReflexiveValue != null && currentQuestionReflexiveValue != undefined){
		        	$('[id="'+currentQuestionId+'"]').attr('data-reflexivevalue',currentQuestionReflexiveValue);
		        }
		        $('.sub-questionnaire-bg').filter(function(){ return $(this).find('ul.questionSetBlock').children("li").length == 0}).each(function() {
					$(this).hide();
				})
        	}
        }
	})
}


// Function to load child question on the fly by evaluating expression
function evaluateChildQuestions(drivingParent, target, questionToBeLoaded) {
	$.ajax({
		url: "/app/Policy/evaluateChildQuestions",
		data: $('#EAPPProposal').serialize() +'&drivingParent='+drivingParent+'&questionToBeLoaded='+questionToBeLoaded,
		async:   false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
        	if (data != ""){
        		var nextLis = $('li[for="'+target+'"]').nextAll('.questionGrid');
        		if (nextLis != null){
        			nextLis.each(function(){
        				childID = $(this).attr('for');
		        		var removedID = childID.replace('responseValue', 'removed');
		        		var parentQuestionCd = $('input[id="'+removedID+'"]').attr('data-parent');
		        		var reflexiveValue = $('input[id="'+removedID+'"]').attr('data-reflexivevalue');
		        		if (parentQuestionCd != null && parentQuestionCd != undefined){
		        			if (parentQuestionCd+'|'+reflexiveValue == questionToBeLoaded){
		        				$('input[id="'+removedID+'"]').parents('li').remove();
		        			}
		        		}
        			})
	        	}

        		var nextDivs = $('li[for="'+target+'"]').nextAll('.sub-questionnaire-bg');
        		if(nextDivs != null){
        			nextDivs.each(function(){
        				childUls = $(this).children('ul');
        				$.each(childUls, function(index, childUl) {
        					if($(childUl).children('li').length == 0){
								$(childUl).parent('.sub-questionnaire-bg').remove();
        					}
        					else{
		        				childID = $(childUl).children('li:first').attr('for');
				        		var removedID = childID.replace('responseValue', 'removed');
				        		var parentQuestionCd = $('input[id="'+removedID+'"]').attr('data-parent');
				        		var reflexiveValue = $('input[id="'+removedID+'"]').attr('data-reflexivevalue');
				        		if (parentQuestionCd != null && parentQuestionCd != undefined){
				        			if (parentQuestionCd+'|'+reflexiveValue == questionToBeLoaded){
				        				$(this).parent('.sub-questionnaire-bg').remove();
				        			}
				        		}
				        	}
        				})
        			})
        		}
        		$('li[for="'+target+'"]').after(data);
        		$('li[for="'+target+'"]').parents('ul').trigger('create');
        	}
        }
	})
}


$(document).ready(function(){
	$(".addMoreButton").click(function(){
		cloneGridQuestions($(this).parents("div.ui-grid-b").prevAll("ul[data-removed='false']:first"), $(this).data("gridquestioncount"));
	});
	$("ul[data-rowguid]").each(function(){
		var rowguid = $(this).attr("data-rowguid");
		var dateInputs = $(this).find(".dateicon .datepicker");
		dateInputs.each(function(){
			$(this).attr("id", $(this).attr("id")+"_"+rowguid);
		});
	});
	attachFieldEvents();
	
	$("li.questionGrid[style='display:none;']").each(function(){
		if($(this).siblings("li.questionGrid:visible").length <= 0) {
			if ($(this).siblings('div.sub-questionnaire-bg:visible').length > 0){
				return;
			}
			questionSetBlock = $(this).closest("ul.questionSetBlock");
			questionSetBlock.hide();
			if(questionSetBlock.siblings("li.questionGrid:visible").length <= 0) {
				questionSetBlock.closest("div.sub-questionnaire-bg").hide();
			}
		}
	});
	$("div.questionnaire-bg").each(function(){
		if($(this).find("div.sub-questionnaire-bg").length <= 0) {
			$(this).hide();
		}
	});

	$('.sub-questionnaire-bg').filter(function(){ return $(this).find('ul.questionSetBlock').children("li").length == 0}).each(function() {
		$(this).hide();
	})
});