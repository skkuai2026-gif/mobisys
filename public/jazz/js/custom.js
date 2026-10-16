$(document).ready(function () {
	/*----------------------Global JS code start----------------------*/
	$(".setting").off("click").on("click", function(){
		$(".setting-details").slideToggle("fast");
		$(".profile-details").slideUp("fast");
	});

	$(".profile").off("click").on("click", function(){
		$(".profile-details").slideToggle("fast");
		$(".setting-details").slideUp("fast");
	});

	$(".quicklink").off("click").on("click", function(){
		$(".quicklink-details").slideToggle("fast");
	});

	$(".add-illustration").on("click", function(){
		$(".add-illustration-details").slideToggle("fast");
	});

	$(".datepicker:not(.inputreadonly)").datepicker({
		changeMonth: true,
		changeYear: true,
		dateFormat: "dd-M-yy",
		yearRange: "1900:2099"
	});
	$(".datepicker").on("click",function(){
		$(".ui-datepicker").show(); 
	});
	
	$("#dtBox").DateTimePicker({
		dateFormat: "dd/MM/yyyy",
		timeFormat: "hh:mm:ss",
		dateSeparator: "/",
		dateTimeFormat: "dd/MM/yyyy hh:mm:ss",
		titleContentTime: "",
		titleContentDateTime: "",
		setButtonContent: getLabel("SET",locale),
		clearButtonContent: getLabel("CLEAR",locale)
	});

	$('.row-details input, .row-details select, .row-details .ui-select a').on('focus', function () {
		$(this).closest('.row-details').addClass('row-details-focus');
	});
	$('.row-details input, .row-details select, .row-details .ui-select a').on('blur', function () {
		$(this).closest('.row-details').removeClass('row-details-focus');
	});
	/*----------------------Global JS code end----------------------*/


	/*----------------------Search page JS code start----------------------*/
	$(".advance-search-field").hide();
	$(".advance-search-btn").click(function(){
		setTimeout(function(){$(".advance-search-field").show();},300)
		$(".advance-search-field input").removeAttr("disabled");  
		$(".advance-search-field select").val("").selectmenu().selectmenu('enable').trigger("refresh");
		$("#search").val('');
		setReadOnly($("#search"),true);
		setReadOnly($("#search-go"),true);
		$("#search-go").addClass("buttonReadonly");
	});
	$(".close-advance-search-field").click(function(){
		$(".advance-search-field input").prop('disabled', true);
		$(".advance-search-field select").val("").selectmenu().selectmenu('disable').trigger("refresh");
		$(".advance-search-field").hide();
		setReadOnly($("#search"),false);
		setReadOnly($("#search-go"),false);
		$("#search-go").removeClass("buttonReadonly");
		advanceSearchFilter();
	});
	
	var actionStatusShow = $(".action-status-show");
	$(".action-toggle-close").click(function(){
		actionStatusShow.animate({
			'right': '-700',
			'opacity': '0'
		}, 300);
		$(this).closest("tr").removeClass("highlightActionToggle")
	});

	$(".action-toggle-open").click(function(){
		$(".action-status-show").show();
		actionStatusShow.animate({
			'opacity': '0'
		}, 300);
		$(this).closest(".action-toggle-bg").find(actionStatusShow).animate({
			'right': '0',
			'opacity': '1'
		}, 300);
		$("tr").each(function(){
			if ($(this).hasClass("highlightActionToggle")){
				$(this).removeClass("highlightActionToggle");
			}
		});
    	$(this).closest("tr").addClass("highlightActionToggle");
	});

	$("#search-go").click(function(){
		$(".delete-checkbox input").prop("checked", false).checkboxradio("refresh");
		document.forms[0].submit();
	});

	$("input[name='mainSearchField']").keypress(function (e) {
		if (e.which == 13) {
			document.forms[0].submit();
			return false;
		}
	});

	$(".advance-search-field input").keypress(function(e){
		return validateKeyPress(event,this,"en");
	});

	$(".delete-checkbox").hide();
	$(".delete-confirm-bg").hide();
    $(".delete-illustration").click(function(){
		$(".action-toggle-open").hide();
		$(".delete-checkbox").show();
		$(".delete-illustration").hide();
		$(".delete-confirm-bg").show();
		$(".advance-search-btn").addClass("advanceSearchButton");
		$(".btn-mobile-bg").addClass("addButton");
		$(".ui-field-contain").addClass("mainSearch");
	});
    $(".delete-confirm-bg .search-btn-bg a#cancel").click(function(){
		$(".action-toggle-open").show();
		$(".delete-checkbox").hide();
		$(".delete-checkbox input").prop("checked", false).checkboxradio("refresh");
		$(".delete-illustration").show();
		$(".delete-confirm-bg").hide();
		$(".advance-search-btn").removeClass("advanceSearchButton");
		$(".btn-mobile-bg").removeClass("addButton");
		$(".ui-field-contain").removeClass("mainSearch");

	});

    $("#search").on("keyup", function() {
	    var value = $(this).val().toLowerCase();
	    $("#searchTable tr").filter(function() {
	    	$(this).toggle($(this).children("td").clone().children().remove().end().text().toLowerCase().indexOf(value) > -1)
	    });
	});

	$(".advance-search-field input").on("keyup",function(){
		advanceSearchFilter();
	});

	$(".advance-search-field select, .advance-search-field input.datepicker").on("change",function(){
		advanceSearchFilter();
	});

	/*----------------------Search page JS code end----------------------*/

	$(document).mouseup(function (e){
		// setting-details menu close
		var setting = $(".setting-details, .setting ");
		if (!setting.is(e.target) && setting.has(e.target).length === 0){$(".setting-details").slideUp();}

		// profile-details menu close
		var profile = $(".profile-details, .profile");
		if (!profile.is(e.target) && profile.has(e.target).length === 0){ $(".profile-details").slideUp();}

		// quicklink-details
		var quicklinkdetails = $(".quicklink-details, .quicklink");
		if (!quicklinkdetails.is(e.target) && quicklinkdetails.has(e.target).length === 0) {$(".quicklink-details").slideUp(); }

		// profile-details menu close
		var addIllustration = $(".add-illustration-details, .add-illustration");
		if (!addIllustration.is(e.target) && addIllustration.has(e.target).length === 0){ $(".add-illustration-details").slideUp();}

		// action-status-show
		var actionstatusshow = $(".action-status-show");
		if (!actionstatusshow.is(e.target) && actionstatusshow.has(e.target).length === 0)
		{
			actionstatusshow.animate({
				'right': '-700',
				'opacity': '0'
			}, 200);
		}
	});
});


function initializeSignature(){
    $('.signaturePad').each(function(){
        $(this).jSignature();
    	var fieldTarget = $(this).attr("for");
        var canvas = $(this).find("canvas");
        $(".overlay[for='"+fieldTarget+"']").css("width",canvas.width()+"px");
        $(".overlay[for='"+fieldTarget+"']").css("height",(canvas.height()+8)+"px");
        $(this).bind("change",function(e){
        	var canvasDataURL = $(this).jSignature("getData","default");
            $("#"+fieldTarget).val(canvasDataURL);
            if(canvasDataURL == ""){
            	$(".clearButtonDiv[for='"+fieldTarget+"']").hide();
            }
            else{
            	$(".clearButtonDiv[for='"+fieldTarget+"']").show();
            }
        });
    });
	$(".clearButton").click(function(){
    	var fieldTarget = $(this).attr("for");
		$(".signaturePad[for='"+fieldTarget+"']").jSignature("reset");
		$(".overlay[for='"+fieldTarget+"']").hide();
        $("#"+fieldTarget).val("");
    	$(".clearButtonDiv[for='"+fieldTarget+"']").hide();
	});
}

function initializeSignaturePopup(){
    $('.signaturePad').each(function(){
        $(this).jSignature();
    	var fieldTarget = $(this).attr("for");
        var canvas = $(this).find("canvas");
        $(".overlay[for='"+fieldTarget+"']").css("width",canvas.width()+"px");
        $(".overlay[for='"+fieldTarget+"']").css("height",(canvas.height()+8)+"px");
        $(this).bind("change",function(e){
        	var canvasDataURL = $(this).jSignature("getData","default");
            $("#"+fieldTarget).val(canvasDataURL);
           	$(".clearButtonDiv[for='"+fieldTarget+"']").show();
        });
    });
    
	$(".clearButton").click(function(){
    	var fieldTarget = $(this).attr("for");
		$(".signaturePad[for='"+fieldTarget+"']").jSignature("reset");
		$(".overlay[for='"+fieldTarget+"']").hide();
        $("#"+fieldTarget).val("");
	});

	// to adjust signature canvas size with div
	$( ".signaturePopup" ).on( "popupafteropen", function( event, ui ) {
		var canvasDataURL = $(this).jSignature("getData","default");
		canvas = $(this).find('canvas');
		overlay = $(this).find('.overlay');
		width = canvas.parent().css("width").replace("px","");
		canvas.attr("width",width);
		overlay.css("width",width + "px");
		height = canvas.parent().css("height").replace("px","");
		canvas.attr("height",height);
		overlay.css("height",height + "px");
		$(this).jSignature("setData",canvasDataURL);
	});
}

function deletePopup(obj, messageLabel, module) {
	labelKeys = 'Yes|No';
	var labelValues = getLabelValues(labelKeys);
	var yes = labelValues.Yes;
	var no = labelValues.No;
	var del_conf_msg = getLabelValue(messageLabel,module);

    $('<div>').simpledialog2({ 
    	mode: 'button', buttonPrompt: del_conf_msg, 
    	buttons : {
	      	yes: { 
		        click: function () { 
		        	try{
		        		eval('delete'+module+'_Callback_func(obj)');
		        	}
					catch(ee){
						console.log('delete popup callbackFunction missing : ' + ee.description);
					}
		        },
		        label: yes
	      	},
	      	no: {
		        click: function () { 
		        	try{
		        		eval('deleteNO'+module+'_Callback_func(obj)');
		        	}
					catch(ee){
						console.log('delete no popup callbackFunction missing : ' + ee.description);
					}
		        },
		        icon: "delete",
		        theme: "c",
		        label: no
	      	}
    	}
  	});
    $('.ui-simpledialog-container').css('min-height','0').appendTo('body');
}

function advanceSearchFilter(){
	var idArr = [];
	$(".advance-search-field input, .advance-search-field select").each(function(){
		idArr.push($(this).attr("id"));
	});
	var table = document.getElementById("searchTable");
	var tr = table.getElementsByTagName("tr");

	for (var j = 0; j < tr.length; j++) {
		isValid = true;
		var resultArray = [];
		for (i = 0; i < idArr.length; i++) {
			value = "";
			id = idArr[i];
			if ($("#"+id).is("input")){
				value = $("#"+id).val().toLowerCase();
			}
			else if ($("#"+id).is("select")){
				if($("#"+id).val()!=""){
					value = $("#"+id + " option:selected").html().replace(/^\s+|\s+$/g,'').toLowerCase();
				}
			}

			if (value != ""){
				var innerHtml = $("#searchTable p[for='"+id+"']:eq("+j+")").parents('td').html();
				innerHtml = innerHtml.replace(innerHtml.substring(innerHtml.indexOf('<b'), innerHtml.indexOf('</b>')+4),"");
				innerHtml = innerHtml.replace(/^\s+|\s+$/g,'').toLowerCase();
				// console.log("value:" + value);
				// console.log("innerHtml:" + innerHtml);
				resultArray.push(innerHtml.indexOf(value) > -1);
			}
		}
		
		result = resultArray.every(function(element,index,array){return element==true }); 
		$(tr[j]).toggle(result);
	}
}

var flag = true;
var flag1 = true;


/************************ collateral-insurance-me ************************************/

$(document).on("pageshow", "#collateral-insurance-me", function () {
	if(flag){
		flag = false;
    }
	$(".collapse-panel li").click(function(){
		var curId3 = $(this).attr('data-name');
		$(".collapse-panel li").removeClass("active");
		$("#video-gallery, .collateral-collapse-cust").hide();
		$("#"+curId3).show();
		$(this).addClass("active");
	});
});


/********************************* FNA & PRQ *******************************************/
$(document).on("pageshow", "#fna-page", function () {
	if(flag){
		flag = false;
	
    $(".add-correct-icon").click(function(){
		if($(this).hasClass("icon-added")){
			$(this).html('ADD')
			$(this).removeClass("icon-added");
		}else{
			$(this).html('<i class="icon-tick"></i>')
			$(this).addClass("icon-added");
		}
		
	});

	$(".tab-cust").click(function(){
		$(".tab-cust").removeClass("active");
		$(this).addClass("active");
		$(".content-table").hide();
		var getCurTab= $(this).attr("data-title");
		$("."+getCurTab).show();
	});
	
	}
});


/********************************* RPQ - Evaluation Sign **************************************/
$(document).on("pageshow", "#rpq-evaluation-sign", function () {
	if(flag1){
		$('#agent-sign').jSignature({'UndoButton':true});
		$('#applicant-sign').jSignature({'UndoButton':true});
		flag1= false;
	}
});

function navigateButton(link) {
	$.ajax({
		url: "/app/Menu/navigateToUrl",
		data: {'link': link},
		success: function(data) {},
		async: false
	});
}