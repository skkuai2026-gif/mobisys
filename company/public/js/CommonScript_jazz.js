/*######################################################################################
 Code for common validation start here
 ######################################################################################*/
var appDtFormat = "dd-M-yy";
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
	// console.log(obj);
	var id = obj.id;
	// console.log("id "+id);
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
	}
	return false;
}

function validateKeyPress(event,obj,locale,entityName){
	if ((event.keyCode || event.which) == 13) {
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

	if(obj.casevalue != null &&
		obj.casevalue != ''){
		if(obj.casevalue == 'UPPER'){
			obj.value = obj.value.toUpperCase();
		}
		else if(obj.casevalue == 'LOWER'){
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

	if (validated && parententity == null) {
		validated = catchevent(obj);
	}
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
		raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],'number');
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
			raiseAlert('ERR_REQUIREDPRD',[getLabel("integer",locale)],'integer');
			obj.value = "";
		}
		else
			raiseAlert('ERR_REQUIREDPRD',[getLabel("integer",locale)],'integer');
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
			raiseAlert('ERR_REQUIREDPRD',[getLabel("integer",locale)],'integer');
			obj.value = '';
			return false;
		}
	} else {
		if (isNaN(obj) || !isInt(obj)) {
			raiseAlert('ERR_REQUIREDPRD',[getLabel("integer",locale)],'integer');
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
	// var dtVal = null;
	// if (typeof (obj) == 'object') {
	// 	dtVal = obj.value;
	// } else {
	// 	dtVal = obj;
	// }
	// var valid = true;
	// if (validateBlank(dtVal))
	// 	valid = isDate(dtVal, appDtFormat);
	// alert(valid);
	// if(valid)
	// {
	// 	var year = dtVal.substring(6,dtVal.length);
	// 	if(parseInt(year) < 1900)
	// 		valid = false;
	// }
	// if (!valid) {
	// 	// raiseAlert('ERR_INVALIDWARNING',[getFieldLabel(obj.id),getLabel("date",locale)],locale);
	// 	if (typeof (obj) == 'object') {
	// 		obj.value = "";
	// 	}
	// 	return false;
	// }
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
			raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],'number');
			obj.value = '';
			return false;
		}
	} else {
		if (isNaN(obj) || !isInt(obj)) {
			raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],'number');
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
	var strValue = obj.value;
	if (strValue != null && strValue != '' && strValue != 'undefined') {
		if (obj.value.length > parseInt(entity.maxLength)) {
			raiseAlert('ERR_CHECKSIZE',null,locale);
			obj.value = "";
			return false;
		}
	} else {
		if (obj.length > parseInt(entity.maxLength)) {
			raiseAlert('ERR_CHECKSIZE',null,locale);
			obj = '';
			return false;
		}
	}
	return true;
}

/*
 * This Function check for black list characters of current entity type. @param
 * entity - current entity type @param obj - current field @return - true or
 * false.
 */
function validateBlackChars(entity, obj) {
	var strVal = entity.blacklistChars;
	var strName = entity.entityTypeName;
	if (strVal.trim().length > 0) {
		var pattern = new RegExp(strVal, "g");
		var strValue = obj.value;

		// console.log("pattern"+pattern);
		if (strValue != null && strValue != '' && strValue != 'undefined') {
			if (pattern.test(obj.value)) {
				if (strName == "emailAddressType"){
				    raiseAlert('Please enter a valid email address.');
				}else{
				    raiseAlert('ERR_NOTALLOW',[strVal],locale);
			    }
				obj.value = '';
				return false;
			}
			return true;
		} else {
			if (pattern.test(obj)) {
				// raiseAlert('ERR_NOTALLOW',[strVal],locale);
				// obj = '';
				// return false;
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
			pattern = new RegExp(strwhiteVal, "g");
		}catch(e){
			// alert(e.description);
			raiseAlert(e.description,[],locale);
			return false;
		}
		var strValue = obj.value;
		if (strValue != null && strValue != '' && strValue != 'undefined') {
			if (!pattern.test(obj.value)) {
				raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],'number');
				obj.value = '';
				return false;
			}
		} else {
			if (!pattern.test(obj)) {
				raiseAlert('ERR_REQUIREDPRD',[getLabel("number",locale)],'number');
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
	var lat = str.indexOf(at)
	var lstr = str.length
	var ldot = str.indexOf(dot)
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

	return true
}

function validateEmail(obj) {
	var emailID = obj;

	if ((emailID.value == null) || (emailID.value == "")) {
		return true;
	}
	if (echeck(emailID.value) == false) {
		raiseAlert(getLabelValue("ERR_INVALIDEMAIL"),"",locale);
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
		return eval("this."+labelKey+"."+locale);
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
				ddateFormat: "dd-M-yy",
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
		// $.mobile.loading(showOrHide);
		if((!$('#shadow').hasClass('loader-wrapper')) && (showOrHide == 'show')){
            $('#shadow').addClass('loader-wrapper');
            $('#shadow').removeClass('displayNone');
        }
        if(($('#shadow').hasClass('loader-wrapper')) && (showOrHide == 'hide')){
            $('#shadow').removeClass('loader-wrapper');
            $('#shadow').addClass('displayNone');

        }
	}, 1);
	// if((!$('#shadow').hasClass('loader-wrapper')) && (showOrHide == 'show')){
 //    	$('#shadow').addClass('loader-wrapper');
 //    	$('#shadow').removeClass('displayNone');
	// }
	// if(($('#shadow').hasClass('loader-wrapper')) && (showOrHide == 'hide')){
 //    	$('#shadow').removeClass('loader-wrapper');
 //    	$('#shadow').addClass('displayNone');

	// }
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
        $("input[type='radio'][id*='"+targetField+"']").filter("[value='"+ targetMap[selectedValue] + "']").click().click();
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
            if (Object.keys(targetMap[selectedValue]).length == 0) {
                selected = " selected";
            }
            $.each(targetMap[selectedValue], function(lookupKey, lookupValue){
                optionString += "<option value='"+lookupKey+"'"+selected+">"+lookupValue+"</option>";
            });
            $("select[id='"+targetField+"']").html(optionString).change();
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

//
function fieldTargetValueMapFilterSetup1(mappingHash, filterable, object){
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
    lookupOrder={}
	i=0
	//console.log("targetmap"+targetMap[selectedValue])
    //On load event mapping
    if (filterable == "true" && targetMap[selectedValue]){
    	// console.log("1");
        $.each(targetMap[selectedValue], function(lookupKey, lookupValue){
            if (selectedTargetValue == lookupKey) {
				var temp=lookupValue.split("|")[0];
                optionString += "<option value='"+lookupKey+"' selected>"+temp+"</option>";
            }
            else {
            	// lookupValue=lookupValue.split("|")[0];
             //    optionString += "<option value='"+lookupKey+"'>"+lookupValue+"</option>";
            	lookupOrder[lookupValue.split("|")[1]] = lookupKey;
            }

        });
        keys = Object.keys(lookupOrder);
		i, len = keys.length;
		for (i = 0; i < len; i++) {
		  	k = keys[i];
		  	var res=targetMap[selectedValue][lookupOrder[k]];
		  	res=res.split("|")[0];
		  	optionString += "<option value='"+lookupOrder[k]+"'>"+res+"</option>";
		}

        $('select[id="'+targetField+'"]').empty('');
        $("select[id='"+targetField+"']").removeAttr("data-placeholder");
        $('select[id="'+targetField+'"]').append("<option data-placeholder='true'>Select</option>");
        $('select[id="'+targetField+'"]').append(optionString).change();
        // $('select[id="'+targetField+'"]').selectmenu().selectmenu("refresh");
        // $("select[id='"+targetField+"']").html(optionString).trigger("create");
    }
    else if (targetMap[selectedValue]){
    	// console.log("2");
        $("input[type='text'][id='"+targetField+"']").val(targetMap[selectedValue]);
        $("select[id='"+targetField+"']").val(targetMap[selectedValue]).trigger("refresh");
        $("input[type='radio'][id*='"+targetField+"']").filter("[value='"+ targetMap[selectedValue] + "']").click().click();
    }
    else {
    	// console.log("3");
    	 $("select[id='"+targetField+"']").removeAttr("data-placeholder");
    	 $('select[id="'+targetField+'"]').append("<option data-placeholder='true'>Select</option>");
    	 $('select[id="'+targetField+'"]').append("<option value=''>Select</option>");

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
		lookupOrder={}
		i=0
        if (filterable == "true" && targetMap[selectedValue]){
            var selected = '';
            if (Object.keys(targetMap[selectedValue]).length == 0) {
                selected = " selected";
            }
            $.each(targetMap[selectedValue], function(lookupKey, lookupValue){
				lookupOrder[lookupValue.split("|")[1]] = lookupKey;
			});
			keys = Object.keys(lookupOrder);
			i, len = keys.length;
			for (i = 0; i < len; i++) {
			  k = keys[i];
			  var res=targetMap[selectedValue][lookupOrder[k]];
			  res=res.split("|")[0];

			  optionString += "<option value='"+lookupOrder[k]+"'>"+res+"</option>";
			}
            $('select[id="'+targetField+'"]').empty('');
	        $("select[id='"+targetField+"']").removeAttr("data-placeholder");
	        $('select[id="'+targetField+'"]').append("<option data-placeholder='true'>Select</option>");
	        $('select[id="'+targetField+'"]').append(optionString).change();
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



function submitTabForm(nextTabId,shouldDiscard,navNextTabId) {
	shouldDiscard = shouldDiscard == null ? false:shouldDiscard;
	var initialShouldDiscard = shouldDiscard;
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
	if($('#fieldApplicabilityFlagFacet').val() == "YES" && !initialShouldDiscard && currTabVal == "tab_coverage"){
		shouldDiscard = false;
	}
	if($("#forceCOD").val() == "YES"){
		shouldDiscard = false;
	}
    // if (currTabVal == "tab_questionnaire" && $('#policy_statusCd').val() == "PENDING"){
    //     shouldDiscard = false;
    // }
	if(shouldDiscard) {
		params = {
			"id":document.getElementById('entityId').value,
			"sym_current_Tab":nextTabId,
			"sym_navbar":navNextTabId,
			"mode":"FETCH",
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
				// try{
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

					// refreshing quicklinks
					if($('#EAPPProposal').size()>0){
						var quicklinksHeader = htmldata.find('.header-action-bg');
						var quicklinksHeaderRefreshed = quicklinksHeader[0].innerHTML
						$(".header-action-bg").html(quicklinksHeaderRefreshed).enhanceWithin();
						$(".quicklink").off("click").on("click", function(){
							$(".quicklink-details").slideToggle("fast");
						});
					}
					var hiddenQuickLinkCount = 0
					if($('#sales_illustration_form').size()>0){
						var quicklinksHeader = htmldata.find('.header-action-bg');
						var quicklinksHeaderRefreshed = quicklinksHeader[0].innerHTML
						$(".header-action-bg").html(quicklinksHeaderRefreshed).enhanceWithin();
						$(".quicklink").off("click").on("click", function(){
							$(".quicklink-details").slideToggle("fast");
						});


					}

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

					//temporary skipping initialization of initialFormSerialized for rider tab
					if(document.getElementById('sym_current_Tab').value != "tab_rider" && document.getElementById('sym_current_Tab').value != "tab_selProduct" && document.getElementById('sym_current_Tab').value != "tab_withdrawal"){
						initialFormSerialized = $('#' + frmId).serialize();
					}

					$(".datepicker:not(.inputreadonly)").datepicker({
						changeMonth: true,
						changeYear: true,
						dateFormat: "dd-M-yy",
						yearRange: "1900:2099"
					});

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
						// $(".quicklink").show();
						$(".quicklink-details").hide();
					}
					if($("#quotFNAId").val()!='' && $("#quotFNAId").val()!=undefined){
						$(".quicklink").show();
    				}

					if (typeof window["attachMaskAll"] === "function") {
						attachMaskAll();
					}
					if (typeof window["attachMaskAllQes"] === "function") {
						attachMaskAllQes();
					}

					$("input[type='tel'][entity='transactionNumType']").on("keypress paste",function(e){
						if (e.type == "keypress"){
					        if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
						        return false;
						    }
					    }else if (e.type == "paste"){
					        if(e.originalEvent.clipboardData.getData('Text').match(/^\d*$/)){
					            e.preventDefault();
					        }
					    }
				    });

				    $("input[type='tel'][entity='yearType']").on("keypress paste",function(e){
						if (e.type == "keypress"){
					        if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
						        return false;
						    }
					    }else if (e.type == "paste"){
					        if(e.originalEvent.clipboardData.getData('Text').match(/^\d*$/)){
					            e.preventDefault();
					        }
					    }
				    });

				    $("input[type='text'][entity='contactNumType']").on("keypress paste",function(e){
						if (e.type == "keypress"){
					        if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
						        return false;
						    }
					    }else if (e.type == "paste"){
					        if(e.originalEvent.clipboardData.getData('Text').match(/^\d*$/)){
					            e.preventDefault();
					        }
					    }
				    });

				    $("input[type='tel'][entity='countType']").on("keypress paste",function(e){
						if (e.type == "keypress"){
					        if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
						        return false;
						    }
					    }else if (e.type == "paste"){
					        if(e.originalEvent.clipboardData.getData('Text').match(/^\d*$/)){
					            e.preventDefault();
					        }
					    }
				    });

				// }
				// catch(ee){
				// 	console.log('error in getting tab data : ' + ee.description);
				// }
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
				$t_fixed.find("tbody").remove().end().addClass("fixed").insertBefore($this);
				$t_fixed.find(".advance-search-field").remove();
				resizeFixed();
			}
			function resizeFixed() {
				$t_fixed.find("th").each(function(index) {
					$(this).css("width",$this.find("th").eq(index).outerWidth()+"px");
				});
			}
			var tablePos = $("table").offset().top - 62;
			function scrollFixed() {
				// $(".advance-search-btn a").text('Advanced Search');
				$(".advance-search-field").hide();
				var scrollpos = $(this).scrollTop() ;
				if(scrollpos >= tablePos ){
					$(".search-header-fixed.fixed").css({
						"display":"table",
						"top": "64px"
					});
				}else{
					$(".search-header-fixed.fixed").css({
						"display":"none",
						"top": "inherit"
					});
				}
			}
			$(window).resize(resizeFixed);
			$(".main-content-wrapper").scroll(scrollFixed);
			init();
		});
	};
})(jQuery);

function disableAllFormFields(){
	//alert("in disableAllFormFields");
	setReadOnly($('input[type="text"]'), true);
    setReadOnly($('input[type="tel"]'), true);
    setReadOnly($('input[type="num"]'), true);
    setReadOnly($('input[type="email"]'), true);
    setReadOnly($('textarea'), true);
    $(".datepicker:not(.inputreadonly)").addClass('inputreadonly');
    $(".datepicker").prop('disabled', true);
    $('input[data-field="time"],input[data-field="datetime"]').prop('disabled', true);
    $('select').selectmenu().selectmenu('disable').trigger("refresh");
    $('input[type="radio"]').checkboxradio().checkboxradio('disable').trigger("refresh");
    $('input[type="checkbox"]').checkboxradio().checkboxradio('disable').trigger("refresh");
    $('input[type="button"]').off('click');
    $('input[type="button"]').button('disable').trigger("refresh");
    $('a[id$="_addButton"]').hide();
    $('a[id$="generateWithdrawal"]').hide();
    $('a[id$="quotationWithdrawalCountDelete"]').hide();
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

function parseJwt(token) {
    var base64Url = token.split('.')[1];
    var base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    var jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));
    var result = JSON.parse(jsonPayload);
    $.ajax({
        url: "/app/AgentReg/sendDecodedToken",
        data: {'decodedToken': result},
        async: true,
        type: "POST",
        headers: {
          'Transition-Enabled': false
        },
        success: function(data) {

        }

    });
}