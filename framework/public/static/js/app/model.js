console.log("models.js");

/**
 * Record app state.
 */
App.Model.State = Backbone.Model.extend({
	defaults: {
		section	: '', 	// current input section model id
		field	: '',	// current field model id
		$currentField	: '',	// current input field DOM element (read only)
		currentField	: '',	// current field model (read only)
		$currentDataField: '',  // current data field DOM element (read only)
		dataPanelScrolling: false // a flag to mark the data panel is scrolling by user
	},
	
	initialize: function() {
		
		this.sections = App.Collection.sections;
		this.on('change:field', function() {
			this.updateCurrentField();
		});
		this.on('change:section', function(model, data) {
			Tracking.trackPageview('FNA-'+ App.language + '/' + this.getCurrentPageName());
		}, this);
		
	},
	
	updateCurrentField: function() {
		
		var s = this.get('section');
		var f = this.get('field');
		
		// update $currentField
		var q = s ? '#' + s : '';
		q += f ? ' .' + f : '';
		this.set('$currentField', $(q));
		
		// update currentField
		var field = this.sections.getField(this.get('section'), this.get('field'));
		this.set('currentField', field);
		
		// update $currentDataField
		var q2 = '#data-fields';
		q2 += s ? ' .' + s : '';
		q2 += f ? ' .' + f : '';
		this.set('$currentDataField', $(q2));
	},
	
	getCurrentField: function() {
		return this.sections.get(this.get('section')).get('fields').get(this.get('field'));
	},
	
	/*
	 * return current section object
	 * if no next section, return null
	 */
	getCurrentSection: function() {
		return this.sections.get(this.get('section'));
	},
	
	/*
	 * return next section object
	 * if no next section, return null
	 */
	getNextSection: function() {
		var section = null;
		var index = this.sections.indexOf(this.getCurrentSection()) +1;
		if (index > 0) {
			section = this.sections.at(index);
		}
		return section;
	},
	
	/*
	 * return prev section object
	 * if no prev section, return null
	 */
	getPrevSection: function() {
		var section = null;
		var index = this.sections.indexOf(this.getCurrentSection()) -1;
		if (index >= 0) {
			section = this.sections.at(index);
		}
		return section;
	},
	
	getCurrentPageName: function() {
		var page =  this.getCurrentSection().get('name');
		page = (!page) ? data : page;
		return page;
	}
	

});

App.Model.Element = Backbone.Model.extend({
	defaults: {
		key			: "",
		related		: null,	/* control relationship of other fields (App.Model.Related) */
		active		: true	/* screen is showing this element */
	},
	
	initialize: function() {
		this.set('id',this.get('key'));
		
		var related = this.get('related');
		if (related) {
			related.owner = this;
			this.set('related', new App.Model.Related(related));
			//console.log(related);
		}
	}
});

App.Model.Section = App.Model.Element.extend({
	defaults: {
		background_image	: "",		/* only top level sections have background image */
		fields 				: null, 	/* object of App.Collection.Fields */
		bottons				: null,		/* buttons show on section data panel */
		prefill				: false,	/* when true, will auto prefill all fields to default values */
		info				: "",		/* the info page to be popup */
		
		// Not configable values below
		readied				: false,	/* The section reday to fill, when last section verified */
		verified			: false, 	/* All fields verified */
	},
	
	initialize: function() {
		
		App.Model.Element.prototype.initialize.apply(this, arguments);
		
		if (this.get('fields')) {
			var fields = this.get('fields');
			
			// pass section(this) to fields for referencing
			_.each (fields, function(field) {
				field.section = this;
			}, this);
			
			// create fields collection
			this.set('fields', new App.Collection.Fields(fields));
		}
		
		// convert the language of "info" string
		if (this.get('info')) {
			var info = this.get('info');
			info = info.replace('{App.language}', App.language);
			this.set('info', info);
		}
		
		App.Model.state.on('change:section', this.onSectionChange, this);
				
	},
	
	onSectionChange: function(model, data) {
		this.set('active', data === this.get('id'));
		this.prefill(model, data);
	},
	
	/*
	 * Auto prefill default to fields of section
	 */
	prefill: function(model, data) {
		if (data === this.id) {
			if (this.get('prefill') === true) {
				_.each(this.get('fields').models, function(f) {
					f.setDefaultValue();
				});
			}
		}
	},
	
	/*
	 * Verify all fields of the section
	 * If all fields verified, set verified to true
	 */
	verify: function() {
		
		var verified = true;
		var fields = this.get('fields');
		
		// verify data base on config file
		if (fields.models) {
			fields.each(function(field) {
				
				// If not valid and not skippable
				if (!field.isValid() && !field.get('skippable') ) {
					verified = false;
				}
				
				// If related not 'pass', no need to check this field.
				if (field.get('related')) {
					if (field.get('related').get('pass') === false) {
						verified = true;
					}
				}
			}, this);			
		} else {
			verified = false;
		}
		
		this.set('verified', verified);
		
		// If verified, set next section to 'readied'
		var nextSection = App.Collection.sections.getNextSection();
		if (nextSection) {
			nextSection.set('readied', verified);
		}
	},
	
	/*
	 * Return first field of the section
	 */
	getFirstField: function() {
		return this.get('fields').at(0);
	}
});

App.Model.Field = App.Model.Element.extend({
	defaults: {
		data_type		: null,		/* category, numeric, currency, percentage */		
		field_type		: null,		/* select, slider, number-input */
		default_value	: null,		
		min				: null,		/* min value of rangeValidate */
		max				: null,		/* max value of rangeValidate */
		option			: [],		/* options of 'select' */
		skippable		: false, 	/* is the filed can be empty? */
		validate		: null, 	/* name of validate function (App.Validator) */
		
		// Not configable values below
		section			: null,		/* reference to parent section, passed by Section model when init */
		value			: null,		/* user input value */
		f_value			: null		/* formated value */
	},
	initialize: function() {
		
		App.Model.Element.prototype.initialize.apply(this, arguments);
		
		if (this.get('validate')) {
			this.validate = App.Validator[this.get('validate')];
		}
		if (this.get('field_type') === 'number_input') {
			this.set('option', [6,7,8,9,0,'number_input_ok','number_input_back',1,2,3,4,5]);
		}
		this.on('change:value', this.onValueChange, this);
		this.onValueChange(this.get('value'));
		
		App.Model.state.on('change:field', this.onFieldChange, this);
			
	},
	
	onFieldChange: function(model, data) {
		// chack active
		var active = data === this.get('id') && model.get('section') === this.get('section').get('id');
		this.set('active', active);
		
		// update default value
		if (active) {
			this.setDefaultValue();
		}
		
	},
	
	onValueChange: function(model, data) {
		
		var v = '';
		if (data || data === 0) {
			switch (this.get('data_type')) {
			case 'numeric':
				v = DQ.addCommas(data);
				break;
			case 'currency':
				v = '' + DQ.addCommas(data);
				break;
			case 'percentage':
				v = data + '%';
				break;
			case 'category':
				v = App.i18n.prop(data);
				break;
			default:
				v = (data === undefined) ? '' : data;
				break;
			}	
		}
		this.set('f_value', v);
		
		// If it is last field of section, ask section model to vailfy all input field
		this.get('section').verify();
	},
	
	setDefaultValue: function(hardReset) {
		if ((this.get('value') === null || hardReset === true) && this.get('default_value') !== null) {
			this.set('value', this.get('default_value'));				
		}
		
		// Special handling
		// Protection: Years for Supporting
		if (this.get('id') == 'years_for_supporting' && (this.get('value') === null || hardReset === true)) {
			var age = App.Collection.sections.getField('information', 'age').get('value');
			var value = 65 - age;
			value = (value < 0) ? 0 : value;
			this.set('value', value);
		}
		// console.log('setDefaultValue()', this);
	},
	
	/*
	 * Return true, if it is last field of collection
	 */
	isLastField: function() {
		var index = this.collection.models.length;
		var flag = false;
		if (index > 0) {
			flag = (this.collection.at(index-1) === this);
		}
		return flag;
	},
	
	/*
	 * Return next field of collection
	 * Return null if no next field
	 */
	getNextField: function() {
		var index = this.collection.models.indexOf(this);
		return this.collection.at(index+1);
	},
	
	/*
	 * Return prev field of collection
	 * Return null if no next field
	 */
	getPrevField: function() {
		var index = this.collection.models.indexOf(this);
		return this.collection.at(index-1);
	}
	
});



/**
 * Watching a field,
 * once the value of field is in condition,
 * the 'pass' to be true
 */
App.Model.Related = Backbone.Model.extend({
	defaults: {
		owner	: null,
		watch	: [],	/* e.g. [ { section:'',field:'' } ] */
		cond	: '',	/* e.g. "value == 0" */
		pass	: false /* 'watch' field value passed 'condition' */
	},
	
	initialize: function() {
				
		/**
		 * Listen to target field change,
		 * If value march 'condation', set 'pass' to true
		 */
		function createRelated(model)
		{
			var watch = this.get('watch');
			var field = model.getField(watch.section, watch.field);
			field.on('change', function(model) {
				/*jshint unused:false */
				var value = model.get('value');
				this.set('pass', eval(this.get('cond')));
				//console.log(value, this.get('cond'), this.get('pass'));
			}, this);
		}
				
		App.Collection.sections.once('created', createRelated,  this);
		
		this.on('change:pass', function(model, data) {
			// clean up related fields, if 'pass' is false
			if (model) {
				var owner = model.get('owner');
				if (model && data === false) {
					owner.set('value', null);
					//console.log('clean up related value', owner);
				}				
			}
		});
	} 
	
});

/**
 * Handle alert window
 */
App.Model.Alert = Backbone.Model.extend({
	defaults: {
		message : "Message..."
	}
});

