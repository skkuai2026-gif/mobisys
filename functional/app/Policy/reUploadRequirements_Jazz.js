var initialFormSerialized = "";
var currentSlickIndex = 0;
$(document).ready(function () {
	tab_requirement_pageTabLoaded();
});

function tab_requirement_pageTabLoaded(){
	if (application_view_mode == "mobile"){
        refreshSlickUiMobile(currentSlickIndex);
		$('.slider-nav').on('click', '.slick-slide', function(event) {
			event.preventDefault();
			currentSlickIndex = $(this).data('slick-index');
		});
		
		$('.collapse-panel .ui-collapsible-heading-collapsed:first').click();
    }
	var serviceDocumentDocumentCd = document.querySelectorAll('select[id*="_serviceDocument_documentCd"]');
	for(var i = 0; i < serviceDocumentDocumentCd.length; i++){
		var documentCdId = serviceDocumentDocumentCd[i].getAttribute('id');
        var servicedocGuid = documentCdId.replace('documentCd','guid');
        var guidValue = $('#'+servicedocGuid).val();
        var  servicedocselected = "";
		if($('#multiDocMode').val() == 'true'){
        	servicedocselected = documentCdId.replace('documentCd','selected-0');
	        if (!$('#'+servicedocselected).is(':checked')){
	        	$('a[id="capture'+guidValue+'"]').addClass('readonly');
	        }
        }
		serviceDocument_documentCd_onFocus(serviceDocumentDocumentCd[i])
		checkUploadStatus(servicedocselected);
	}
	$(".tablist-content").hide();
	$("#"+$("input[type='radio'][name='categorySelector']:checked").val()).show();
	$("input[type='radio'][name='categorySelector']").change(function(){
		$(".tablist-content").hide();
		$("#"+$(this).val()).show();
	});

	$(".dirtyImage").clone().each(function(i,img){
		parentkey = $(img).data("id").toString();
		if(parentkey.indexOf(".")==-1) {
			parentkey = parentkey+".0";
		}
		img.width = 1654;
		$(img, {
			load: function() {
				finalFile = $(img).pixastic("desaturate").pixastic("resize",{'width':1654,'height':img.height })[0].toDataURL("image/jpeg");
				$.ajax({
					type: "POST",
					url:"/app/Policy/updateProcessedImage", 
					data:{'fileString': finalFile,'parentKey': parentkey},
					success: function(){
					}
				});
			}
		});
	});


	$("#"+$(".categorySelector.active").attr("id")+"-panel").show();

	$(".categorySelector").click(function(e){
		e.preventDefault();
		e.stopPropagation();

		$(".requirement-content-wrapper-left ul p").removeClass("active");
		$(this).addClass("active");
		$(".tablist-content").hide();
		$("#"+$(this).attr("id")+"-panel").show();
	});

	$("a[href='#full-image']").click(function(){
		$("div#full-image img").attr("src",$(this).attr("for"));
	});

	$("#full-image").on({
		popupbeforeposition: function() {
			var maxHeight = $(window).height() - 100 + "px";
			$("#full-image img").css("max-height", maxHeight);
		}
	});
	initialFormSerialized = $('#requirementForm').serialize();
}

function reUploadRequirements() {
	$('input[type="checkbox"]').checkboxradio().checkboxradio('enable');
	submitRequirementForm();
	document.getElementById('requirementForm').submit();
	location.href = "/app/Policy/reUploadingDocumentsToServer?policyObject=" + $("#policy_object").val();
	loading('show');    
}

function serviceDocument_documentCd_onFocus(obj){
    if (obj != null){
        id = obj.id;
        lookupkey = obj.getAttribute("data-lookupkey");
        categoryCd = $("#"+id.replace("documentCd","docCategoryCd")).val();
        filterCondition = {'categoryCd' : categoryCd};
        loadLookupData(lookupkey, filterCondition, id);
    }
}

function takePicture(gridID, mode) {
	key = $('#'+gridID+'_docCategoryCd').val();
	serviceDocGuid = $('#'+gridID+'_guid').val();
	file = gridID+'_imageURL';
	status = gridID+'_acceptanceStatusCd';
	reciveDtId = gridID+'_receivedDt';
	image_count = gridID+'_imageCount';
	documentname = key
	if(mode == "gallery"){
		$.ajax({
			url:"/app/Policy/takePicture", 
			data: {'parentRefGuid':serviceDocGuid, 'choosePicture':'true'},
			success: function(data){}
		});
	}
	else if(mode == "document"){
		$.ajax({
			url:"/app/Policy/pickDocument", 
			data: {'parentRefGuid':serviceDocGuid},
			success: function(data){}
		});
	}
	else{
		$.ajax({
			url:"/app/Policy/takePicture", 
			data: {'parentRefGuid':serviceDocGuid},
			success: function(data){}
		});
	}
}

function updateFile(filename) {
	filename = filename.split('@SEPARATOR');
	fileType = "png";
	url = filename[0];
	if(filename[3].indexOf(".pdf") >= 0){
		url = "/public/jazz/images/pdf_512.png";
		fileType = "pdf";
	}
	else if(filename[3].indexOf(".gif") >= 0){
		url = "/public/jazz/images/gif_512.png";
		fileType = "gif";
	}
	else if(filename[3].indexOf(".doc") >= 0){
		url = "/public/jazz/images/doc_512.png";
		fileType = "doc";
	}
	else if(filename[3].indexOf(".tiff") >= 0){
		url = "/public/jazz/images/tiff_512.png";
		fileType = "tiff";
	}
	else if(filename[3].indexOf(".xls") >= 0){
		url = "/public/jazz/images/xls_512.png";
		fileType = "xls";
	}
	data = "<div class='proof-img' name='"+filename[1]+"'><a href='#full-image' data-rel='popup' data-position-to='window' data-transition='pop' for='"+url+"' data-imagevalue='"+filename[1]+"'><img class='dirtyImage' data-id='"+filename[1]+"' src='"+url+"'/></a><a style='position:absolute;top:0;z-index:99;right:0;' id='deleteAnchor"+filename[1]+"'  href=javascript:deletePopup('"+filename[1]+"','DELETE_CONFIRMATION','image'); data-servicedocGuid='"+filename[2]+"'><img src='/public/jazz/images/del.jpg' alt='Delete' title='Delete'></a></div>"
	
	if(application_view_mode == "mobile"){
        $("#tab-"+documentname+"-proof-panel div.documents-upload-gallery[name='"+filename[2]+"'] .sliderA").append(data).trigger("refresh");
    }
    else{
        $("#tab-"+documentname+"-proof-panel div.attach-image-section[name='"+filename[2]+"']").append(data).trigger("refresh");
    }

	var currentDate = new Date();
	$('#'+file).val(filename);
	$('#'+status).val("RECEIVED");
	$('#'+reciveDtId).val(currentDate.getDate()+"/"+(currentDate.getMonth()+1)+"/"+currentDate.getFullYear());
	imageCount = $('#'+image_count).val();
	
	if (isNaN(parseInt(imageCount)) || isNaN(parseInt(imageCount)) < 0){
		imageCount = 0
	}
	$('#'+image_count).val(parseInt(imageCount) + 1);
	
	$("a[href='#full-image']").click(function(event){
		if(fileType == "pdf" || fileType == "doc" || fileType == "xls" || fileType == "tiff" || fileType == "gif" || fileType == "jpg"){
			event.preventDefault();
			event.stopPropagation();
			$.ajax({
				url: "/app/Policy/openDocument",
				data: {'imageObject': $(this).attr('data-imagevalue')},
				success: function(data) {}
			});
		}
		else{
			$("div#full-image img").attr("src",$(this).attr("for"));
		}
	});

	$("#full-image").on({
		popupbeforeposition: function() {
			var maxHeight = $(window).height() - 100 + "px";
			$("#full-image img").css("max-height", maxHeight);
		}
	});
}

function removeImages(servicedocGuid, imagevalue, numberOfimages) {
	imagevalue = imagevalue || "";
	numberOfimages = numberOfimages || "single";
	var servicedocObj = servicedocGuid.replace('_','.');
	var servicedocObjId = $('input[value="'+servicedocObj+'"]').attr('id');
	var imageCountId = servicedocObjId.replace('object','imageCount');
	var imageCount = $('#'+imageCountId).val();
	if (isNaN(parseInt(imageCount))){
		imageCount = 0
	}
	$.ajax({                                    
		url: "/app/Policy/removeImage",
		async: false,
		data: {'imageObject': imagevalue,'servicedocGuid': servicedocGuid,'numberOfimages':numberOfimages},
		success: function(data) {
			if(data != null){
	            var parseData = $.parseJSON(data);
	            var objects = parseData.split(",");
	            $.each(objects, function(index, value) {
					$(".proof-img[name='"+value+"']").remove();
	            })
			}
		}
	});
	if (numberOfimages == 'single'){
		$(".proof-img[name='"+imagevalue+"']").remove();
		$("div#full-image").popup( "close" );
		$('#'+imageCountId).val(parseInt(imageCount) - 1);
	}
	else{
		$('#'+imageCountId).val(0);
	}
}

function submitRequirementForm() {
	$.ajax({                                    
		url: "/app/Policy/submitRequirements",
		method: 'POST',
		async: false,
		data: $('#requirementForm').serialize(),
		headers: {
        	'Transition-Enabled': false
        },
		success: function(){
			
		}
	});
}

function deleteimage_Callback_func(imageObject) {
	var servicedocGuid = $('[id="deleteAnchor'+imageObject+'"]').attr('data-servicedocGuid');
	removeImages(servicedocGuid, imageObject);
}

function deleteimages_Callback_func(servicedocGuid) {
	removeImages(servicedocGuid, '', 'all');
}

function deleteNOimages_Callback_func(servicedocGuid){
	if($('#multiDocMode').val() == 'true'){
		var servicedocObj = servicedocGuid.replace('_','.');
		var servicedocObjId = $('input[value="'+servicedocObj+'"]').attr('id');
		var selectedtId = servicedocObjId.replace('object','selected-0');
		$('#'+selectedtId).prop('checked', true);
		newName = $('#'+selectedtId).attr('name').replace('_hid','');
		$('#'+selectedtId).attr('name', newName);
		$('#'+selectedtId).val('YES');
		$('label[for="'+selectedtId+'"]').removeClass('ui-checkbox-off');
		$('label[for="'+selectedtId+'"]').addClass('ui-checkbox-on');
	}
}

function serviceDocument_selected_func(obj){
	selectedID = obj.id.substring(0, obj.id.indexOf('-'));
	var guidId = selectedID.replace('selected','guid');
    var servicedocGuid = $('#'+guidId).val();
    var imageCountId = selectedID.replace('selected','imageCount');
    var imageCount = $('#'+imageCountId).val();
    if (isNaN(parseInt(imageCount))){
		imageCount = 0
	}
	
    if (obj != null){
    	if(obj.checked == false){
    		if (imageCount > 0) {
				deletePopup(servicedocGuid,'DELETE_CONFIRMATION','images');
			}
			$('a[id="capture'+servicedocGuid+'"]').addClass('readonly');
		}
		else{
			$('a[id="capture'+servicedocGuid+'"]').removeClass('readonly');
		}
    }
}

function checkUploadStatus(obj){
	var uploadStatus = obj.replace('selected-0','uploadStatus');
	var status = $("#"+uploadStatus).val();
	if (status == "DONE"  && $('#'+obj).is(':checked')){
		$("input[type='checkbox'][id="+obj+"]").checkboxradio().checkboxradio('disable').trigger("refresh");
	}
}