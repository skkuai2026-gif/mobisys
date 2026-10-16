console.log('view/input-panel.js');

App.View.Section = Backbone.View.extend({
	
	initialize:function () {
		this.appState = arguments[0].appState;
		this.render();
	},
	
	render: function() {
		this.$el.empty();

		_.each(this.model.models, function(model) {
			
			// <section> tag
    		var $section = $("<section>", { id: model.toJSON().id });
    		    		    		
    		// create fields
    		_.each(model.get('fields').models, function(field) {
    			
				// create field
				var obj = { el		: $section,
    						model	: field };
				switch (field.get('field_type')) {
					case 'slider':
						new App.View.SliderField(obj);
						break;
						
					case 'select':
						new App.View.SelectField(obj);
						break;
						
					case 'number_input':
						new App.View.NumberInputField(obj);
						break;
						
					case 'sum':
						// auto sum function, no input field need
						break;
						
					case 'calculateTotalExpensesPerYear':
						// Cal.calculateTotalExpensesPerYear() function, no input field need
						break;
					
					case 'non_field':
						// non field need
						break;

					default:
						new App.View.Field(obj);
						break;
				}
    				
    		}, this);

    		this.$el.append($section);
    		
    	}, this);
				
		return this;
	}
	
});

App.View.Field = Backbone.View.extend({
	
	initialize: function() {
		
		this.appState = App.Model.state;
		this.$self = undefined; // the dom element holding the field
		this.render();
		this.model.on('change:active', this.onActiveChange, this);
		this.model.on('change:value', this.onValueChange, this);
		this.appState.on('change:field', this.onFieldChange, this);
		
		var related = this.model.get('related');
		if (related) {
			related.on('change:pass', this.checkRelated, this);
			this.checkRelated(related, related.get('pass'));
		}
		
		
	},
	
	render:function() {
		var html = App.Template['field_' + this.model.get('field_type')];
		if (html) {
			var template = _.template(html);
			this.$el.append(template(this.model.toJSON()));
			this.$self = this.$el.children().last(); // pass the dom element to $self
			
			// set field height and center to screen
			this.$self.css('padding-top', App.fieldPaddingTop).height(App.viewHeight);
			
		} else {
			// if the template can't be find in template file, it should be inputed wrong field_type in data/config.json.js file.
			console.error("No template found by field_type: " + this.model.get('field_type') + ". Please check the data/config.json.js file.");
		}
		return this;
	},
	
	onActiveChange: function(model, active) {
		if (active) {
			$('.question_knob', this.$self).addClass('active');
		} else {
			$('.question_knob', this.$self).removeClass('active');
		}
	},
	
	checkRelated: function(model, pass) {
		if (pass) {
			this.$self.addClass('related-pass').removeClass('related-fail');
		} else {
			this.$self.addClass('related-fail').removeClass('related-pass');
		}
	},
	
	onFieldChange: function(model, field) {
	},
	
	onValueChange: function(model, filed) {
	},
	
	scrollNext: function() {
		if (this.model.isValid) {
			$('.question_knob', this.$self).removeClass('active');
			_.delay(function() { // wait a sec before auto scroll to next field
				// console.log('scrollNext()');
				App.View.scroller.iScroll._execEvent('scrollStart');
				App.View.scroller.iScroll.next();			
			}, 800, this);
		}
	}
});

App.View.SliderField = App.View.Field.extend({
	
	initialize:function () {
		App.View.Field.prototype.initialize.apply(this, arguments); // super
				
		this.$knob = $('.knob', this.$self);
		this.$knob.knob({
			'release': this.onKnobRelease,
			'self': this,
			'buttonSize': 30,
			'buttonColor': '#fff'
		});
		
		// When touch slide button
		$('canvas', this.$self).bind('touchstart mousedown', $.proxy(function() {
			this.$knob.trigger('configure', { buttonSize: 60, buttonColor: App.secondaryColor });
			App.View.scroller.iScroll.disable();
		}, this));
		
		// When release touch button
		$('canvas', this.$self).bind('touchend mouseup', $.proxy(function() {
			this.$knob.trigger('configure', { buttonSize: 40, buttonColor: '#fff' });
			App.View.scroller.iScroll.enable();
		}, this));
		
	},
		
	onActiveChange: function(model, active) {
		App.View.Field.prototype.onActiveChange.apply(this, arguments);
		if (active) {
			
			// slide to default value when value did not input
			// if (!model.get('value')) { // it will have bug if value == 0
			if (model.get('value') == null) {
				
				var value = { val: Number(model.get('value')) };
				TweenLite.to(value, 1, {
					model: model,
					val: Number(model.get('default_value')), 
					onUpdate:function (tween, $knob) {
						$knob.val(tween.target.val, false).trigger('change');
					}, 
					onUpdateParams:[ "{self}", this.$knob ],
					onComplete: function() {
						model.set('value', model.get('default_value'));
					}
				});
			} else {
				this.model.set('value', model.get('value'));
			}
		}
	},
	
	onValueChange: function(model, data) {
		App.View.Field.prototype.onValueChange.apply(this, arguments);
		
		// push model data to view
		this.$knob.val(data, false).trigger('change');
	},
	
	onKnobRelease: function(value) {
		this.o.self.model.set('value', value);
		this.o.self.scrollNext();
	}
	
});

App.View.SelectField = App.View.Field.extend({
	
	initialize:function () {
		App.View.Field.prototype.initialize.apply(this, arguments);
		
		this.pieInput = new App.View.PieInput({
			el: $('.pie-input', this.$self),
			model: this.model
		});
		
		this.pieInput.arcs.on(App.click, this.onPieClick.bind(this));
		this.model.on('change:value', this.onValueChange, this);
	},
	
	onPieClick: function(d) {
		d.data.model.set('value', d.data.value);
		this.scrollNext();
	},
	
	onActiveChange: function(model, active) {
		App.View.Field.prototype.onActiveChange.apply(this, arguments);
		if (active) {
			this.pieInput.$el.addClass('active');
		} else {
			this.pieInput.$el.removeClass('active');
		}
	},
	
	onValueChange: function(model) {
		App.View.Field.prototype.onValueChange.apply(this, arguments);
		$('.value', this.$self).text(model.get('f_value'));
	}
});

App.View.NumberInputField = App.View.Field.extend({
	
	initialize:function () {
		App.View.Field.prototype.initialize.apply(this, arguments);
		
		function onClick(d) {
			var value = d.data.value;
			var model = d.data.model;
			switch (value) {
			
			case 'number_input_back':
				model.set('value', 0);
				break;
				
			case 'number_input_ok':
				this.scrollNext();
				break;
				
			default:
				var v = Number(String(Number(model.get('value'))) + value);
				if (v >= model.get('min') && v <= model.get('max')) {
					model.set('value', v);				
				}
				break;
			}
		};
		
		this.pieInput = new App.View.PieInput({
			el: $('.pie-input', this.$self),
			model: this.model
		});
		this.pieInput.arcs.on(App.click, onClick.bind(this));
		
		this.model.on('change:value', function(model) {
			$('.value', this.$self).text(model.get('f_value'));
		}, this);
		
	},
	
	onActiveChange: function(model, active) {
		App.View.Field.prototype.onActiveChange.apply(this, arguments);
		if (active) {
			this.pieInput.$el.addClass('active');
		} else {
			this.pieInput.$el.removeClass('active');
		}
		
	},
	
	onValueChange: function(model) {
		App.View.Field.prototype.onValueChange.apply(this, arguments);
		$('.value', this.$self).text(model.get('f_value'));
	}
});
