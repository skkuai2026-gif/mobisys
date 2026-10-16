console.log("validator.js");

App.Validator.rangeValidate = function(d) {
	if (d.value === '' || d.value < d.min || d.value > d.max) {
		return App.i18n.prop('selected_value_not_in_range');
	}		
};

App.Validator.optionValidate = function(d) {
	if (!_.contains(d.option, d.value)) {
		return App.i18n.prop('selected_value_not_in_list');
	}
};