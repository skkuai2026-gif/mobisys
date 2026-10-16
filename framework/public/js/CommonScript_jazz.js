/*######################################################################################
 Code for common validation start here
 ######################################################################################*/
var appDtFormat = "dd/MM/yyyy";
var locale = "en";
var initialFormSerialized = "";

function EntityType() {
	var entityTypeName;
	var dataType;
	var maxLength;
	var blacklistChars;
	var whitelistChars;
	var extendsEntityType;
	var minValue;
	var maxValue;
}

function fieldFocus(eventObj) {
	var eventSrcID = null;
	if (eventObj != null) {
		eventSrcID = eventObj.id;
	}
	try {
		//check for grid fields displayed as Sections
		//although ids are different we need to call a single callback function.
		//call on change of section grid if existing
		if(eventSrcID.indexOf('grid') == 0) {
			eventSrcID = eventSrcID.substring(eventSrcID.indexOf('_',eventSrcID.indexOf('_')+1)+1,eventSrcID.length);
		}
		//for radio buttons and checkbox the ids are different
		if(eventObj.type == 'radio' || eventObj.type == 'checkbox'){
			eventSrcID = eventSrcID.substring(0, eventSrcID.indexOf('-'));
		}
		retValue = eval(eventSrcID + '_onFocus(eventObj)');
	}
	catch(e){
		// alert(e.description );
	}
	
	return true;
}

function fieldBlur(obj) {
	var id = obj.id;
	// obj.style.background = '#FFFFFF';
	try {
		eval(id + '_blurFunc(obj)');
	} catch (e) {
		// alert(e.description );
	}
}

function inputFieldCheckClicked(obj) {
	if (obj != undefined && obj != null && obj != ""){
		if(obj.getAttribute("data-lookupkey") == "BOOLEAN" || obj.getAttribute("data-lookupkey") == "YESNO"){
			var name = obj.name.replace("_hid","");
			if (obj.checked) {
				obj.value = 'YES';
				var chkHidObj = document.getElementById(obj.id + '_hid');
				if(chkHidObj != null){
					chkHidObj.setAttribute("name", name + '_hid');
					chkHidObj.value = 'YES';
					obj.setAttribute("name", name);
				}
			}
			else{
				obj.value = 'NO';
				var chkHidObj = document.getElementById(obj.id + '_hid');
				if(chkHidObj != null){
					chkHidObj.setAttribute("name", name);
					chkHidObj.value = 'NO';
					obj.setAttribute("name", name + '_hid');
				}
			}
		}
		catchevent(obj);
		callEvaluateMetadata(obj);
	}
	return false;
}

function validateKeyPress(event,obj,locale,entityName){
	var maxlength = parseInt(obj.getAttribute("maxlength"));
	if ((maxlength > 0 && obj.value.length > maxlength) || ((event.keyCode || event.which) == 13)) {
		$(':focus').blur();
		event.preventDefault();
	}
}

/*
 * Function validate field on Web page using its EntityType attribute. On the
 * basis of entity type it will execute corresponding validation functions
 * @param entityName - entity type of field @param obj - current field @param
 * isRecursive - boolean variable
 */
function validateField(obj,locale,entityName) {
	var validated = true;
	if (entityName == 'undefined' || entityName == null) {
		entityName = obj.getAttribute('entity');	
	}
	// Deepali Singh: Commenting field mandatory alert on tab out as this feature is not required
	// if (obj.getAttribute('minoccurs') == "1") {
	// 	isMandatory = true;
	// }
	// else {
	// 	isMandatory = false;
	// }

	// if (isMandatory) {
	// 	if (!validateBlank(obj.value)) {
	// 		raiseAlert('ERR_WARNINGMANDATORY',[getFieldLabel(obj.id)],locale);
	// 		return false;
	// 	}
	// }
		     
	if (obj.attributes.casevalue != null &&
		obj.attributes.casevalue != '') {
		if (obj.attributes.casevalue.value == 'UPPER') {
			obj.value = obj.value.toUpperCase();
		}
		else if (obj.attributes.casevalue.value == 'LOWER') {
			obj.value = obj.value.toLowerCase();
		}
	}
		     
	var entity = getEntity(entityName);
	var parententity = null;

	if (entity != null) {
		if (validateBlank(entity.dataType) && obj.value!='') {
			validated = validateDataType(entity, obj);
		}

		if (validated && entity.maxLength) {
			validated = validateMaxLength(entity, obj);
		}

		if (validated && validateBlank(entity.blacklistChars)) {
			validated = validateBlackChars(entity, obj);
		}

		if (validated && validateBlank(entity.whitelistChars)) {
			validated = validateWhiteChars(entity, obj);
		}

		if (validated && validateBlank(entity.minValue)) {
			validated = validateMin(entity, obj);
		}

		if (validated && validateBlank(entity.maxValue)) {
			validated = validateMax(entity, obj);
		}

		if (validated && entityName=='emailAddressType') {
			validated = validateEmail(obj);
		}

		if (validated && validateBlank(entity.extendsEntityType) && entity.extendsEntityType!=entity.entityTypeName) {
			parententity = getEntity(entity.extendsEntityType);
		}

		if (validated && parententity != null) {
			validated = validateField(obj, locale, parententity.entityTypeName);
		}

		if (validated == undefined) {
			validated = true;
		}

	}

	if (validated && obj.hasAttribute('minlength')) {
		validated = validateMinLength(entity, obj);
	}

	if (validated && parententity == null) {
		validated = catchevent(obj);
	}
	callEvaluateMetadata(obj);
	return validated;
}

/*
 * Function returns current entity type object. @param entityTypeName - entity
 * type of field @return obj- return entity type
 */
function getEntity(entityTypeName) {
	var arrEntity = this.arrObj;
	if (arrEntity.length != 0) {
		for ( var e = 0; e < arrEntity.length; e++) {
			if (arrEntity[e].entityTypeName == entityTypeName) {
				var obj = arrEntity[e];
				return obj;
			}
		}
	}
	return null;
}

/*
 * Function to check empty field value @param value - value of field @return -
 * true or false
 */
function validateBlank(value) {
	if (value == null)
		return false;
	value = Trim(value);

	if (value != "")
		return true;
	else
		return false;
}

String.prototype.trim = function() {
	return this.replace(/^\s+|\s+$/, '');
};

function Trim(str) {
	if (str != null) {
		while (str.charAt(0) == (" ")) {
			str = str.substring(1);
		}
		while (str.charAt(str.length - 1) == " ") {
			str = str.substring(0, str.length - 1);
		}
	}
	return str;
}

/*
 * Function validates the data type of object According to data type of current
 * entity type it will execute its validateXXX(obj) function @param entity -
 * entity type of field @param obj - current object.
 */
function validateDataType(entity, obj) {
	var dataType = entity.dataType.toUpperCase();
	var flg = false;
	if(obj.value != ""){
		switch (dataType) {
		case 'DOUBLE':
			flg = validateDouble(obj);
			break;
		case 'SHORT':
			flg = validateShort(obj);
			break;
		case 'DATE':
			flg = validateDate(obj);
			break;
		case 'LONG':
			flg = validateLong(obj);
			break;
		case 'STRING':
			flg = true;
			break;
		}
		if(!flg){
			obj.value = "";
		}
	}
	return flg;
}

function isNumeric(val) {
	var validChars = '-0123456789.';

	for ( var i = 0; i < val.length; i++) {
		if (validChars.indexOf(val.charAt(i)) == -1)
			return false;
	}

	return true;
}

function isInt(val) {
	var validChars = '0123456789';

	for ( var i = 0; i < val.length; i++) {
		if (validChars.indexOf(val.charAt(i)) == -1)
			return false;
	}

	return true;
}

/*
 * This function validates String Object @param obj - current field @return -
 * true or false.
 */
function validateString(obj) {
	var strValue = obj.value;

	if (!isNaN(strValue)) {
		raiseAlert('ERR_REQUIREDPRD',[getLabel("stringValue",locale)],locale);
		obj.value = '';
		return false;
	}
	return true;
}

/*
 * This function validate double and float values. @param obj - current field
 * @return - true or false.
 */
function validateDouble(obj) {
	var strVal = null;
	if (typeof (obj) == 'object') {
		strVal = obj.value;
	} else {
		strVal = obj;
	}
	var valid = true;
	if (validateBlank(strVal)) {
		valid = isNumeric(strVal);
		var dblVar = parseFloat(strVal);
		// if isNAN returns true check numeric not required
		if (isNaN(dblVar)) {
			valid = false;
		}
	}
	if (!valid) {
		if (typeof (obj) == 'object') {
			raiseAlert('ERR_INVALIDWARNING',[getFieldLabel(obj.id),getLabel("number",locale)],locale);
			obj.value = "";
		}
		else
			raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],locale);
		return false;
	}
	return true;
}

/*
 * This Function validates short values. @param obj - current field @return -
 * true or false.
 */
function validateShort(obj) {
	var strValue = obj.value;
	if (strValue != null && strValue != '' && strValue != 'undefined') {
		if (isNaN(strValue) || !isInt(strValue)) {
			raiseAlert('ERR_REQUIREDPRD',[getLabel("integer",locale)],locale);
			obj.value = '';
			return false;
		}
	} else {
		if (isNaN(obj) || !isInt(obj)) {
			raiseAlert('ERR_REQUIREDPRD',[getLabel("integer",locale)],locale);
			obj = '';
			return false;
		}
	}
	return true;
}

/*
 * This Function validates date values. @param obj - current field @return -
 * true or false.
 */
function validateDate(obj) {
	var dtVal = null;
	if (typeof (obj) == 'object') {
		dtVal = obj.value;
	} else {
		dtVal = obj;
	}
	var valid = true;
	if (validateBlank(dtVal))
		valid = isDate(dtVal, appDtFormat);
	if(valid)
	{
		var year = dtVal.substring(6,dtVal.length);
		if(parseInt(year) < 1900)
			valid = false;
	}	
	if (!valid) {
		raiseAlert('ERR_INVALIDWARNING',[getFieldLabel(obj.id),getLabel("date",locale)],locale);
		if (typeof (obj) == 'object') {
			obj.value = "";
		}
		return false;
	}
	return true;
}

/*
 * This Function validates long values. @param obj - current field @return -
 * true or false.
 */
function validateLong(obj) {
	var strValue = obj.value;
	if (strValue != null && strValue != '' && strValue != 'undefined') {
		if (isNaN(obj.value) || !isInt(strValue)) {
			raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],locale);
			obj.value = '';
			return false;
		}
	} else {
		if (isNaN(obj) || !isInt(obj)) {
			raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],locale);
			obj = '';
			return false;
		}
	}
	return true;
}

/*
 * This Function check for maxlength of current entity type. @param entity -
 * current entity type @param obj - current field @return - true or false.
 */
function validateMaxLength(entity, obj) {
	var maxLength  = parseInt(obj.getAttribute("'maxlength'"));
	if (maxLength > 0 && obj.value.length > maxLength) {
		raiseAlert('ERR_CHECKSIZE',null,locale);
		obj.value = "";
		return false;
	}
	else{
		return true;
	}
}

/*
 * This Function check for black list characters of current entity type. @param
 * entity - current entity type @param obj - current field @return - true or
 * false.
 */
function validateBlackChars(entity, obj) {
	var strVal = entity.blacklistChars;
	if (strVal.trim().length > 0) {
		var pattern = new RegExp(strVal, "g");
		var strValue = obj.value;
		if (strValue != null && strValue != '' && strValue != 'undefined') {
			if (pattern.test(obj.value)) {
				raiseAlert('ERR_NOTALLOW',[strVal],locale);
				obj.value = '';
				return false;
			}
			return true;
		} else {
			if (pattern.test(obj)) {
				raiseAlert('ERR_NOTALLOW',[strVal],locale);
				obj = '';
				return false;
			}
			return true;
		}
	}
	return true;
}

/*
 * This Function check for white list characters of current entity type. @param
 * entity - current entity type @param obj - current field @return - true or
 * false.
 */
function validateWhiteChars(entity, obj) {
	var strwhiteVal = entity.whitelistChars;
	if (strwhiteVal.trim().length > 0) {
		var pattern = null;
		try{
			pattern = new RegExp("^"+strwhiteVal+"$", "g");
		}catch(e){
			// alert(e.description);
			raiseAlert(e.description,[],locale);
			return false;
		}
		var strValue = obj.value;
		if (strValue != null && strValue != '' && strValue != 'undefined') {
			if (!pattern.test(obj.value)) {
				raiseAlert('ERR_REQUIREDPRD',[getLabel("characters",locale)+strwhiteVal],locale);
				obj.value = '';
				return false;
			}
		} else {
			if (!pattern.test(obj)) {
				raiseAlert('ERR_REQUIREDPRD',[getLabel("characters",locale)],locale);
				obj = '';
				return false;
			}
		}
	}
	return true;
}

/*
 * This Function check for min value of current entity type. @param entity -
 * current entity type @param obj - current field @return - true or false.
 */
function validateMin(entity, obj) {
	var strValue = obj.value;
	if (strValue != null && strValue != '' && strValue != 'undefined') {
		if (obj.value < parseFloat(entity.minValue)) {
			raiseAlert('ERR_CHECKGREATER',[entity.minValue],locale);
			obj.value = '';
			return false;
		}
	} else {
		if (obj != null && obj != '' && obj != 'undefined') {
			if (obj < parseFloat(entity.minValue)) {
				raiseAlert('ERR_CHECKGREATER',[entity.minValue],locale);
				obj = '';
				return false;
			}
		}
	}
	return true;
}

/*
 * This Function check for max value of current entity type. @param entity -
 * current entity type @param obj - current field @return - true or false.
 */
function validateMax(entity, obj) {
	var strValue = obj.value;
	if (strValue != null && strValue != '' && strValue != 'undefined') {
		if (obj.value > parseFloat(entity.maxValue)) {
			raiseAlert('ERR_CHECKLESSER',[entity.maxValue],locale);
			obj.value = '';
			return false;
		}
	} else {
		if (obj != null && obj != '' && obj != 'undefined') {
			if (obj > parseFloat(entity.maxValue)) {
				raiseAlert('ERR_CHECKLESSER',[entity.maxValue],locale);
				obj = '';
				return false;
			}
		}
	}
	return true;
}

/*
 * This Function check for email validation. @param str - email id string
 * @return - true or false.
 */
function echeck(str) {
	var at = "@"
	var dot = "."
	var dots = ".."
	var lat = str.indexOf(at)
	var lstr = str.length
	var ldot = str.indexOf(dot)
	var dash = '-'
	var name   = str.substring(0, str.lastIndexOf(at));
	var domain = str.substring(lat +1);
	if (str.indexOf(at) == -1) {
		return false
	}

	if (str.indexOf(at) == -1 || str.indexOf(at) == 0 || str.indexOf(at) == lstr) {
		return false
	}

	if (str.indexOf(dot) == -1 || str.indexOf(dot) == 0 || str.indexOf(dot) == lstr) {
		return false
	}

	if (str.indexOf(at, (lat + 1)) != -1) {
		return false
	}

	if (str.substring(lat - 1, lat) == dot || str.substring(lat + 1, lat + 2) == dot) {
		return false
	}

	if (str.indexOf(dot, (lat + 2)) == -1) {
		return false
	}

	if (str.indexOf(" ") != -1) {
		return false
	}

	if (str.indexOf(dots) >= 1){
		return false
	}

	if (str.indexOf(dash) == lat+1){
		return false
	}
	if (!domain.match(/(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]/)) {
		return false
	}

	return true
}

function validateEmail(obj) {
	var emailID = obj;

	if ((emailID.value == null) || (emailID.value == "")) {
		return true;
	}
	if (echeck(emailID.value) == false) {
		raiseAlert('ERR_INVALID',[getLabel("Email",locale)],locale);
		obj.value = '';
		return false;
	}
	return true;
}

/*
 * Function to raise an alert message with multilingual feature.
 * @exceptionCd - Exception code
 * @msgString - Comma seperated string values to be replaced in the message
 * @fieldObjToFocus - field object on which focus should be set after alert message.
 * @shdAlert - boolean true/false to indicate whether alert message should be given or just return the message without alert.
 */
function raiseAlert(exceptionCd,placeHolderArr,locale) {
	if ($("#locale").val()!=""){
		locale = $("#locale").val();
	}
	var result = getLabel(exceptionCd,locale);
	if (placeHolderArr!=null){
		for (var i = 0; i < placeHolderArr.length; i++) {
			result = result.replace("{"+(i+1)+"}",placeHolderArr[i]);
		}
	}

	$("#errorPopup").remove();
	$("body").append("<div data-role='popup' id='errorPopup' data-theme='a' class='ui-corner-all popup-wrapper error-popup'><div class='popup-close-cust'><a href='#' data-rel='back' class='icon-close'></a></div><div class='close-before-save'><p>"+result+"</p></div></div>").trigger("create");
	$("#errorPopup").popup('open');
	// alert(result);
    return result;
}

function getFieldLabel(itemId){
	var label = $("p[for='" + itemId + "']");
	if (label.length == 0) {
		element = $("[id='"+itemId+"']");
		$td = element.parents("td");
		$thList = element.parents("table").find("th");
		$tdList = element.parents("tr").find("td");
		if ($tdList.length > 0) {
			$tdList.each(function(index){
				if($(this).is($td)){
					label = $($thList[index]).find("p").html();
					label = label.substr(0,label.indexOf("<span>"));
				}
			});
		}
	}
	else {
		label = label.first().text();
	}
	
	return label.replace("*","");
}

function getLabel(labelKey,locale){
	if ($("#locale").val()!=""){
		locale = $("#locale").val();
	}
	try {
		if (eval("this."+labelKey+"."+locale) != undefined){
			return eval("this."+labelKey+"."+locale); 
		}
		else{
			return labelKey;
		}
	}
	catch(e){
		return labelKey;
	}
}

/*
 * ######################################################################################
 * Code for common validation end here
 * ######################################################################################
 */




$(document).on({
	ajaxSend: function () { loading('show'); },
	ajaxStart: function () { loading('show'); },
	ajaxStop: function () { loading('hide'); },
	ajaxComplete: function () { 
		loading('hide'); 
		$(document).ready(function(){	
			$("#dtBox").DateTimePicker({
				ddateFormat: "dd/MM/yyyy",
				timeFormat: "hh:mm:ss",
				dateSeparator: "/",
				dateTimeFormat: "dd/MM/yyyy hh:mm:ss",
				titleContentTime: "",
				titleContentDateTime: "",
				setButtonContent: getLabel("SET",locale),
				clearButtonContent: getLabel("CLEAR",locale)
			});
		});
	},
	ajaxError: function () { loading('hide'); }
});

function loading(showOrHide) {
	setTimeout(function(){
		$.mobile.loading(showOrHide);
	}, 1); 
	if((!$('#shadow').hasClass('loader-wrapper')) && (showOrHide == 'show')){
    	$('#shadow').addClass('loader-wrapper');
    	$('#shadow').removeClass('displayNone');
    	var newdiv = $( "<div class='layer'></div>");
    	$(newdiv).insertBefore(".main-content-wrapper");
	}
	if(($('#shadow').hasClass('loader-wrapper')) && (showOrHide == 'hide')){
    	$('#shadow').removeClass('loader-wrapper');
    	$('#shadow').addClass('displayNone');
    	$("div.layer").remove();
	}
}


/*Function to re evaluate Context based on runtime value change of driving field.
*	Evaluate the context for current object and its parents guid as well based on the current set of values.
*/

function reEvaluateContext(eventObj){
	var value = eventObj.value;
	var guidId = eventObj.id.substring(-1, eventObj.id.lastIndexOf('_')+1)+"contextGuid";
	var guidObj = $('input[id="'+guidId+'"]');
	var guidValue = guidObj.val();
	var eventSrcID = eventObj.id 
	if((eventObj.type == 'radio' || eventObj.type == 'checkbox') && eventSrcID.indexOf('-') >= 0)
	{
		eventSrcID = eventSrcID.substring(0, eventSrcID.indexOf('-'));
	}
	$.ajax({
	    url: "/app/Menu/reEvaluateContext",
	    data: 'guid='+guidValue + '&value='+value+'&id='+eventSrcID+'&name='+eventObj.name,
	    async:   false,
	    headers: {
	        'Transition-Enabled': false
	    },
	    success: function(data) {
	        
	    }
	});
}
/*Function to evaluate metadata based on runtime value change of driving field.
*	Enable/Disable Or Hide/Show or change the label and mandatory '*' of the fields on runtime based on the newly evaluated context.
*/
function evaluateMetadata(impactedField,drivingField){
	var value = impactedField.value;
	var metaDataCd = impactedField.getAttribute('metaDataFieldName');
	var guidId = impactedField.id.substring(-1, impactedField.id.lastIndexOf('_')+1)+"contextGuid";
	var guidObj = $('input[id="'+guidId+'"]');
	var guidValue = guidObj.val();
	obj = $('#'+impactedField.id);
	var eventSrcID = impactedField.id 
	if((impactedField.type == 'radio' || impactedField.type == 'checkbox') && eventSrcID.indexOf('-') >= 0)
	{
		eventSrcID = eventSrcID.substring(0, eventSrcID.indexOf('-'));
	}
	$.ajax({
	    url: "/app/Menu/evaluateMetadata",
	    data: 'guid='+guidValue + '&value='+value+'&id='+eventSrcID+'&name='+impactedField.name+'&metaDataCd='+metaDataCd,
	    async:   false,
	    headers: {
	        'Transition-Enabled': false
	    },
	    success: function(data) {
	    	//set default values for visibility and editable.
	    	enableField(obj);
	    	obj.show();
	    	obj.closest('p').siblings().show();
	    	obj.closest('span').show();
	    	obj.closest('.project-data').show();
	    	obj.closest('.project-data-full').show();
            var returnHash = $.parseJSON(data);
            enabled = returnHash["enabled"];
            label = returnHash["label"];
            visibility = returnHash["visibility"];
            minOccurs = returnHash["minOccurs"];
            maxlength =	returnHash["maxlength"]
			minlength = returnHash["minlength"] 	
            //update the label of the field.
            obj.parents(".project-data").find(".col-left").replaceWith(label);
            obj.parents(".project-data-full").find(".col-left").replaceWith(label);

            //disable the field as per metadata evaluation
            if(enabled == false || enabled == "false")
            {
            	disableField(obj);
            }

            //remove the error message and its class if the minoccurs is 0
            if(minOccurs == "" || parseInt(minOccurs) < 1)
            {
            	obj.parents('.col-right').children('.error-text').hide();
            	obj.parents('.col-right').children('.icon-error-message').hide();
            	obj.parents('.row-details').removeClass('error-msg');
            }

            //hide the field as per metadata evaluation
            if(visibility == false || visibility == "false")
            {
	    		obj.closest('.project-data').hide();
	    		obj.closest('.project-data-full').hide();
            }

            var attrMax = obj.attr('maxlength');
			if (typeof attrMax !== typeof undefined && attrMax !== false) {
                obj.attr("maxLength",maxlength)
            }

            var attrMin = obj.attr('minlength');
            if (typeof attrMin !== typeof undefined && attrMin !== false) {
                obj.attr("minlength",minlength)
            }
	    }
	});
}


function disableField(obj){
	if(obj.prop('nodeName') == "INPUT")
	{	
		if(obj.attr('type') == "radio"){
			obj.checkboxradio().checkboxradio('disable').trigger("refresh");
		}
		else{
			// obj.val('');
			setReadOnly(obj, true);
			obj.addClass('inputreadonly');
			obj.prop('disabled',true);
		}
	}
	else if(obj.prop('nodeName') == "SELECT")
	{
		// obj.val('').change();
		obj.selectmenu().selectmenu('disable').trigger("refresh");
	}
}


function enableField(obj){
	if(obj.prop('nodeName') == "INPUT")
    {	
    	if(obj.attr('type') == "radio"){
			obj.checkboxradio().checkboxradio('enable').trigger("refresh");
    	}
    	else{
    		setReadOnly(obj, false);
			obj.removeClass('inputreadonly');
			obj.prop('disabled',false);
    	}
	}
	else if(obj.prop('nodeName') == "SELECT")
	{
		obj.selectmenu().selectmenu('enable').trigger("refresh");
	}
}


function callEvaluateMetadata(eventObj) {
	var eventSrcID = null;
	if (eventObj != null) {
		eventSrcID = eventObj.id;
		contextEnabled = eventObj.getAttribute('contextEnabled');
		// console.log("contextEnabled = " + contextEnabled);
		// runTimeDrivingFieldNames = eventObj.getAttribute('runTimeDrivingFieldNames');
		if (contextEnabled == true || contextEnabled == 'true') {
			reEvaluateContext(eventObj);
			fieldToFind = eventSrcID.substring(eventSrcID.length, eventSrcID.lastIndexOf('_') + 1);
			if ((eventObj.type == 'radio' || eventObj.type == 'checkbox') && eventSrcID.indexOf('-') >= 0) {
				fieldToFind = fieldToFind.substring(0, fieldToFind.indexOf('-'));
			}
			var inputfieldList = $('input[runTimeDrivingFieldNames*="' + fieldToFind + '"]');
			var selectfieldList = $('select[runTimeDrivingFieldNames*="' + fieldToFind + '"]');

			for (var i = 0; i < inputfieldList.length; i++) {
				evaluateMetadata(inputfieldList[i], eventObj);
			}
			for (var i = 0; i < selectfieldList.length; i++) {
				evaluateMetadata(selectfieldList[i], eventObj);
			}
		}
	}
}
/*
 * Function to catch all events occurring on the page for every field. Upon on
 * change of every field the catchevent function would look for a function with
 * the name of <Input id> + '_func()' and this function would be called.. if
 * such a function does not exist it will be ignored.
 */
function catchevent(eventObj) {
	var retValue = true;
	var eventSrcID = null;
	if (eventObj != null) {
		eventSrcID = eventObj.id;
		contextEnabled = eventObj.getAttribute('contextEnabled');
		if(contextEnabled == true || contextEnabled == 'true')
		{
			reEvaluateContext(eventObj);
			fieldToFind = eventSrcID.substring(eventSrcID.length, eventSrcID.lastIndexOf('_')+1);
			if((eventObj.type == 'radio' || eventObj.type == 'checkbox') && fieldToFind.indexOf('-') >= 0)
			{
				fieldToFind = fieldToFind.substring(0, fieldToFind.indexOf('-'));
			}
			var inputfieldList = $('input[runTimeDrivingFieldNames*="'+fieldToFind+'"]');
			var selectfieldList = $('select[runTimeDrivingFieldNames*="'+fieldToFind+'"]');
			for (var i = 0; i < inputfieldList.length; i++) {
				evaluateMetadata(inputfieldList[i],eventObj);
			}
			for (var i = 0; i < selectfieldList.length; i++) {
				evaluateMetadata(selectfieldList[i],eventObj);
			}
		}

		callReflexiveFlag = $(eventObj).hasClass('callReflexiveClass');
		if(callReflexiveFlag){
			$(eventObj).reflexiveParentChildDisplayMapping(eventObj)
		}
	}
	// if field value has changed then set the corresponding status field value
	// to U
	if (eventSrcID != null && eventSrcID != '') {
		try {
			//check for grid fields displayed as Sections
			//although ids are different we need to call a single callback function.
			//call on change of section grid if existing
			if(eventSrcID.indexOf('grid') == 0) 
			{
				eventSrcID = eventSrcID.substring(eventSrcID.indexOf('_',eventSrcID.indexOf('_')+1)+1,eventSrcID.length);
			}
			//for radio buttons and checkbox the ids are different
			if((eventObj.type == 'radio' || eventObj.type == 'checkbox') && eventSrcID.indexOf('-') >= 0)
			{
				eventSrcID = eventSrcID.substring(0, eventSrcID.indexOf('-'));
			}
			retValue = eval(eventSrcID + '_func(eventObj)');
		}
		catch(e){
			// alert(e.description );
		}
			
		if(retValue == 'undefined')
			retValue = true;
	}
	return retValue;
}

//Function to setup a filter to map fields based on FieldTargetValueMap
function fieldTargetValueMapFilterSetup(mappingHash, filterable, object){
    var mappingHash = JSON.parse(mappingHash);
    var drivingField = object+"_"+mappingHash.drivingField;
    var targetField = object+"_"+mappingHash.targetField;
    var targetMap = mappingHash.targetMapList;

    if($("input[id*='"+drivingField+"']:eq(0)").attr("type") == "radio"){
        var selectedValue = $("input[id*='"+drivingField+"']:checked").val();
    	drivingField = $("input[id*='"+drivingField+"']:eq(0)").attr("name");
    }
    else {
        var selectedValue = $("[id='"+drivingField+"']").val();
        drivingField = $("[id='"+drivingField+"']").attr("name");
    }               
    var optionString = "<option value=''>Select</option>";
    var selectedTargetValue = $("select[id='"+targetField+"']").val();
    
    //On load event mapping
    if (filterable == "true" && targetMap[selectedValue]){
        $.each(targetMap[selectedValue], function(lookupKey, lookupValue){
            if (selectedTargetValue == lookupKey) {
                optionString += "<option value='"+lookupKey+"' selected>"+lookupValue+"</option>";
            }
            else {
                optionString += "<option value='"+lookupKey+"'>"+lookupValue+"</option>";
            }
        });
        $("select[id='"+targetField+"']").html(optionString).trigger("create");
    }
    else if (targetMap[selectedValue]){
    	
        $("input[type='text'][id='"+targetField+"']").val(targetMap[selectedValue]);
        $("select[id='"+targetField+"']").val(targetMap[selectedValue]).trigger("refresh");
        // $("input[type='radio'][id*='"+targetField+"']").filter("[value='"+ targetMap[selectedValue] + "']").click().click();
    }
    else {
        $("select[id='"+targetField+"']").html(optionString).trigger("create");
    }
    
    //On change event mapping
    $("[name='"+drivingField+"']").change(function(){
    	if($(this).attr("type") == "radio"){
        	selectedValue = $(this).filter(":checked").val();
        }
        else{
			selectedValue = $(this).val();	
        }
        optionString = "<option value=''>Select</option>";
        if (filterable == "true" && targetMap[selectedValue]){
            var selected = '';
            if (Object.keys(targetMap[selectedValue]).length == 1) {
                selected = " selected";
            }
            $.each(targetMap[selectedValue], function(lookupKey, lookupValue){
            	if (($("#"+targetField).prop('disabled')) == false){
            		optionString += "<option value='"+lookupKey+"'"+selected+">"+lookupValue+"</option>";
                	$("select[id='"+targetField+"']").html(optionString).change();
            	}
            });  
        }
        else if (targetMap[selectedValue]){
        	
            $("input[type='text'][id='"+targetField+"']").val(targetMap[selectedValue]);
            $("select[id='"+targetField+"']").val(targetMap[selectedValue]).change();
            $("input[type='radio'][id*='"+targetField+"']").filter("[value='"+ targetMap[selectedValue] + "']").click().click();      
        }
        else {
            $("select[id='"+targetField+"']").html(optionString).change();
        }
    });
}

function setReadOnly(field, readonly){
	if(readonly)
	{        
		field.attr('readonly', 'true');
		field.addClass('readonly');          
	}
	else // !readonly
	{
		field.removeAttr('readonly');
		field.removeClass('readonly');
	}
}

function setNextFieldFocus(input,e){
}

$.fn.fieldexists = function() {
    if(typeof this[0] != 'undefined') {
        return true; 
    } else {
        return false;
    }
}

$.fn.selectit = function(option) {
	$("select[name='"+this.attr('name')+"'] option:eq("+option+")")[0].selected = true;
	this.selectmenu().selectmenu("refresh",true);
}

/*
 * Function to load the lookup data to be called for dynamically fetching data
 * based on single filter condition
 * @param paramType - The lookup param type code e.g. - COUNTRY/CHANNE
 * @param filterCondition - the filter criteria value based on which lookup data is to be loaded
 * @param comboBoxTo - the SelectOption object where data is to be loaded
 */
function loadLookupData(paramType, filterCondition, comboBoxTo) {
	selectedValue = $('#'+comboBoxTo).val();
	lookup = {'selectedValue' : selectedValue , 'lookupKey' : paramType};
	$.extend(filterCondition,lookup)
    $.ajax({                 
        url: "/app/Lookupvalue/getLookupData",
        data: filterCondition,
        async:  false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
            if(data != null){
				$('#'+comboBoxTo).html(data);
				$('#'+comboBoxTo).selectmenu().selectmenu("refresh");
            }
        }
    });
}

function evaluateProductFacetModel(facetId, productSeq, className){
	var frmId = document.forms[0].id;
	var frmObj = $("#" +frmId);
	var result = "";
	params = frmObj.serialize()+"&facetId="+facetId+"&productSeq="+productSeq+"&className="+className;
	$.ajax({                 
        url: "/app/Lookupvalue/getPolicyModelLookupData",
        data: params,
        async:  false,
        headers: {
            'Transition-Enabled': false
        },
        success: function(data) {
        	result = data;
        }
    });
    return result;
}

function submitTabForm(nextTabId,shouldDiscard,navNextTabId) { 
	shouldDiscard = shouldDiscard == null ? false:shouldDiscard;
	var currTab = document.getElementById('sym_current_Tab');
	var currTabVal = '';

	var currNav = document.getElementById('sym_navbar');
	var currNavVal = '';

	if (currNav != null){
		currNavVal = currNav.value;
		if (currNav.value != null && (currNav.value.split('-')[0] != nextTabId)){
			currNav.value = null
		}
		if(navNextTabId != null){
			currNav.value = navNextTabId;
		}
	}

	if(currTab != null) {
		currTabVal = currTab.value;
		currTab.value = nextTabId;
	}

	var continuewithSubmit = true;
	if(!shouldDiscard && typeof submitForm == 'function') {
		continuewithSubmit = submitForm(currTabVal);
	}
	if(!continuewithSubmit)
		return;
	var frmId = document.forms[0].id;
	var frmObj = $("#" +frmId);
	var params = null;
	
	// Check if form is modified else just trigger FETCH
	initialFormSerialized = initialFormSerialized.replace(/sym_current_Tab=[^&]*&/i, "").replace(/sym_navbar=[^&]*&/i, "");
	submitFormSerialized = $("#" +document.forms[0].id).serialize().replace(/sym_current_Tab=[^&]*&/i, "").replace(/sym_navbar=[^&]*&/i, "");
	if(initialFormSerialized == submitFormSerialized) {
		shouldDiscard = true;
	}

	if(shouldDiscard) {
		params = {
			"id":document.getElementById('entityId').value,
			"sym_current_Tab":nextTabId,
			"sym_navbar":navNextTabId,
			"mode":"FETCH",
			"currentTab":currTabVal,
			"formData":frmObj.serializeHash()
		}
	}
	else{
		$('select').removeAttr('disabled').trigger("create");
		$('input[type="checkbox"]').checkboxradio().checkboxradio('enable');
        $('select').selectmenu().selectmenu('enable');
        $('input').removeAttr("disabled");  
        $('input').removeAttr("readonly");  
        $('input[type= "radio"]').attr("disabled", false);
		params = frmObj.serialize()+"&currentTab="+currTabVal+"&currentNavTab="+currNavVal;
	}
	try{
		$.ajax({ // create an AJAX call...
			data: params, // get the form data
			type: frmObj.attr('method'), // GET or POST
			url: frmObj.attr('action'), // the file to call
			transition: "slide",
			success: function(response) { // on success..
				try{
					$("div[data-role='popup']:not(#error-list):not(#summaryPopUp)").remove();
					var htmldata = $($.parseHTML(response,null,true));
					var objFound = htmldata.find('#' + frmId);
					var returnVal = objFound[0].innerHTML;
					frmObj.empty();
					frmObj.html(returnVal).enhanceWithin();

					//replacing updated header text
					var pageHeader = htmldata.find('#page-header h2');
					var pageHeaderRefreshed = pageHeader[0].innerHTML
					$("#page-header h2").html(pageHeaderRefreshed).enhanceWithin();

					var errFound = htmldata.find('#error-list');
					var errRefreshed = errFound[0].innerHTML ;
					$("#error-list").html(errRefreshed).enhanceWithin();
					if(errRefreshed.length>0){
						$("a[href='#error-list']").parent().show();
						$(".error-notification").html($("#error-list li.errorMessage").length+$("#error-list h4.incompleteTab").length);
					}
					else{
						$("a[href='#error-list']").parent().hide();	
						$(".error-notification").html("");
					}

					var pageTabLoadedFunc = document.getElementById('sym_current_Tab').value + '_pageTabLoaded';
					if (typeof window[pageTabLoadedFunc] === "function") {
						eval(pageTabLoadedFunc + '()');
					}
					pageScroll();
					equispaceNavbar();

					//temporary skipping initialization of initialFormSerialized for rider tab
					if(document.getElementById('sym_current_Tab').value != "tab_rider" && document.getElementById('sym_current_Tab').value != "tab_selProduct"){
						initialFormSerialized = $('#' + frmId).serialize(); 
					}

					datePicker();

					$('.row-details input, .row-details select, .row-details .ui-select a').on('focus', function () {
						$(this).closest('.row-details').addClass('row-details-focus');
					});
					$('.row-details input, .row-details select, .row-details .ui-select a').on('blur', function () {
						$(this).closest('.row-details').removeClass('row-details-focus');
					});
					
					if($("#additionalOptionsFl").val()=="false"){
						$(".quicklink,.quicklink-details").hide();
					}
					else{
						$(".quicklink-details").hide();
					}

					if (typeof window["attachMaskAll"] === "function") {
						attachMaskAll();
					}
					disableDragging();

					//Show Log Button
					var showLogFlag = parseInt($("#showLogFlag").val());
					var modelFileName = $("#modelFileName").val();

					if(showLogFlag == 1 && modelFileName != ""){
						$("#policyModelLogLink").attr('href','javascript: showLogFile("'+modelFileName+'")');
						$("#showLogBtn").show(); 
					}
					else
						$("#showLogBtn").hide();
				}
				catch(ee){
					console.log('error in getting tab data : ' + ee.description);
				}
				if(application_view_mode == "mobile"){
				  $(".datepicker:not(.inputreadonly)").click(function(){$(this).datepicker('show')});
				}
			}
		});
	}catch(er){
		console.log('error in getting form data : ' + er.description);
	}
}

function initializeTab(){
	jQuery(".basic-contentwrapper" ).on("scroll", function( event ) { 
		var scrollpos = $(this).scrollTop();
		if($(window).width() > 989){
			if(scrollpos >= 70){
				$(".subTabs .ui-navbar").css({
					'position': 'fixed',
						'top': '89px',
						'right': '47px',
						'left':'30px',
						'background': '#fff',
						'z-index': '9'
					});
				$(".subTabs .ui-content").css("margin-top", "75px");
				
				$(".basictop-navarea").css({
					'position': 'fixed',
					'top': '14px',
					'z-index': '9'
					});
			}else{
				$(".subTabs .ui-navbar").css({
						'position': 'relative',
						'top': '0',
						'right': '0px',
						'left':'0px',
				});
				$(".basictop-navarea").css({
					'position': 'relative',
					'top': '0px'
				});
				$(".subTabs .ui-content").css("margin-top", "inherit");
					
			}
		}
	}); 

	(function ($) {
    $.fn.replaceClass = function (pFromClass, pToClass) {
        return this.removeClass(pFromClass).addClass(pToClass);
    };
	}(jQuery));

	$(".row-info-bg .declaration-radio input").click(function(){
		var htmlText = $(this).val();
		var className = $(this).attr("data-classname");
		$(this).parents(".row-info-bg").find(".second-radio-question").hide();
		$(this).parents(".row-info-bg").find(".first-radio-question, .second-radio-question").find("label").replaceClass("ui-radio-on","ui-radio-off");
		if(htmlText == 'yes'){
			$(this).parents(".row-info-bg").find("."+className).show();
		}else{
			$(this).parents(".row-info-bg").find("."+className).hide();
		}
	});
}

;(function($) {
	$.fn.fixMe = function() {
		return this.each(function() {
			var $this = $(this),
			$t_fixed;
			function init() {

				$t_fixed = $this.clone();
				$t_fixed.find(".advance-search-field").remove();
				$t_fixed.find("tbody").remove().end().addClass("fixed").insertBefore($this);
				resizeFixed();
			}
			function resizeFixed() {
				$t_fixed.find("th").each(function(index) {
					if (index == 0){
						var padding = $this.find("th[role='columnheader']:first").css("padding");
						$(this).css("padding",padding);	
					}
					var width = $this.find("th[role='columnheader']").eq(0).width()+"px"
						$(this).css("width",$this.find("th[role='columnheader']").eq(index).width()+"px");
				});

            }
            function scrollFixed() {
            	var offset = $(this).scrollTop();
            	tableOffsetTop = $this.offset().top;
            	if (offset < tableOffsetTop){
            		$t_fixed.hide();
            	}
            	else if(offset >= tableOffsetTop){	
          			$t_fixed.show();
            	}
            }
            init();
            $(".main-content-wrapper").scroll(scrollFixed);
	        });
		};
	}
)(jQuery);


function disableAllFormFields(){
	setReadOnly($('input[type="text"]'), true);
	setReadOnly($('input[type="datetime"]'), true);
    setReadOnly($('input[type="tel"]'), true);
    setReadOnly($('input[type="num"]'), true);
    setReadOnly($('input[type="email"]'), true);
    setReadOnly($('textarea'), true);
   	setReadOnly($('input[type="time"]'), true);
    $(".datepicker:not(.inputreadonly)").addClass('inputreadonly');
    $(".datepicker").prop('disabled', true);
    $('input[data-field="time"]').prop('disabled', true);
    $('input[type="time"]').prop('disabled', true);
    $('input[type="datetime"]').prop('disabled', true);
    $('select').selectmenu().selectmenu('disable').trigger("refresh");
    $('input[type="radio"]').checkboxradio().checkboxradio('disable').trigger("refresh");
    $('input[type="checkbox"]').checkboxradio().checkboxradio('disable').trigger("refresh");
    $('input[type="button"]').off('click');
    $('input[type="button"]').button('disable').trigger("refresh");
    $('a[id$="_addButton"]').hide();
    $('.takepic').hide();
    $('i[id$="_removed"]').hide();
    $('.main-content-wrapper button').attr('disabled','disabled');
    $('.footer-bg a').hide();
    $('a[id*="deleteAnchor"]').hide();
}

function showDialog(title,message,type,autohide, mainPageId) {
    returnValue = false;        
    $.ajax({
        url: "/app/Menu/showPopUp",
        data: {'title': title, 'message': message},
        success: function(data) {},
        async: false                    
    });          
}

function getLabelValues(labelKeys)
{
    var labelValues = labelKeys;
    $.ajax({
        url: "/app/LabelValue/getMultipleLabelValue",
        data: { 'labelKeys': labelKeys},
        async: false,
        success: function(data){
            if (data!="")
            {
                labelValues = JSON.parse(data);
            }
        }
    });
    return labelValues;
}

function getLabelValue(labelKey,replaceParameter){
    var labelValue = labelKey;
    $.ajax({
        url: "/app/LabelValue/getLabelValueForJs",
        data: { 'labelKey': labelKey, 'replaceParameter' : replaceParameter},
        async: false,
        success: function(data){
            if (data!="")
            {
                labelValue = data;
            }
        }
    });
    return labelValue;
}

function extractImageData(extractedData){
	var containerId = extractedData["containerId"];
	var objectValue = $("#"+containerId+"_object").val();
	var fieldNamePrefix = $("[name='"+objectValue+"']").val();
    $("input[data-metadataCd][name^='"+fieldNamePrefix+"'], select[data-metadataCd][name^='"+fieldNamePrefix+"']").each(function(){
        var metadataCd = $(this).attr("data-metadataCd");
        var value = extractedData[metadataCd];
        if (value != null){
            if ($(this).is(':radio')){
                $(this).prop("checked",false).checkboxradio("refresh");
                $("input[id='"+$(this).attr("id")+"'][value='"+value+"']").prop("checked",true).checkboxradio("refresh");
            }
           
            if ($(this).is(':text') || $(this).is('select')) {
                $(this).val(value).change();
            }
        }
    });
}

function takePictureOCR(choosePicture, controllerName, containerId) {
	$.ajax({
		url:"/app/"+controllerName+"/takePicture",
        data: {'choosePicture': choosePicture, 'isOcr': true, 'containerId': containerId},
		async: true,
		success: function(data){}
	});
}


;(function($) {
	$.fn.fixHeader = function() {
		var $this = $(this),
		$t_fixed;
		function init() {
			$t_fixed = $this.clone();
			$t_fixed.find("i").remove().end().addClass("freeze").insertBefore($this);
		}
		var tablePos = $(this).offset().top - 62;
		function scrollFreeze(){
			var scrollpos = $(this).scrollTop() ;
			if(scrollpos >= tablePos && scrollpos >= 37){
				$t_fixed.addClass("displayHeader");
			}else{
				$t_fixed.removeClass("displayHeader");
			}
		}
		$(".main-content-wrapper").scroll(scrollFreeze);
		init();
	};
})(jQuery);


function validateMinLength(entity, obj) {
	var minlength = parseInt(obj.getAttribute("minlength"));
	if (minlength > 0 && obj.value.length < minlength) {
		raiseAlert('ERR_MINLENGTH',[minlength],locale);
		obj.value = "";
		return false;
	}
	else{
		return true;
	}
}

//Function to switch between different search options.
function setSearchStageAndSubmit(stage) {
	$("#currentTab").val(stage);
	$('#alertStage').val(stage);
	var formName = $("#search-table").closest("form").attr('name');
	eval('document.' + formName + '.submit();');
}

//Function to show Policy Model Log/Set global variable to log file name
function showLogFile(logFileName){
    $.ajax({
        url: "/app/Menu/showLogFile",
        data: { logFileName: logFileName},
        success: function(data){
        }
    });
}