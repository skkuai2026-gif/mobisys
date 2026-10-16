console.log('view/data-panel.js');

App.View.PanelMenu = Backbone.View.extend({
	
	initialize: function() {
		this.appState = arguments[0].appState;
		this.render();
		this.$el.on(App.click, this.onClick.bind(this));
	},
	
	render: function() {
		this.$el.empty();
		var template = _.template(App.Template.data_panel_menu);
		_.each(this.model.models, function(model, index) {
			this.$el.append(template(_.extend(model.toJSON(), { i : index-1 })));				
    	}, this);
	},
	
	onClick: function() {
	}
});

App.View.DataPanelMenu = App.View.PanelMenu.extend({
	
	initialize: function() {
		App.View.PanelMenu.prototype.initialize.apply(this, arguments);
		var childrenField = this.model.getField('information', 'num_of_children');
		this.onChildrenChange(childrenField, childrenField.get('value'));
				
		childrenField.on('change:value', this.onChildrenChange);
		this.appState.on('change:section', this.onSectionChange, this);
		this.model.on('change:verified', this.checkVerified, this);
	},
	
	onChildrenChange: function(model, data) {
		var $education_icon = $('.data-panel-menu .education', this.$el);
		if (data > 0) {
			$education_icon.show();
		} else {
			console.log('hide education icon');
			$education_icon.hide();
		}
	},
	
	onSectionChange: function(model, section) {
		
		// handle 'welcome' section
		if (section === 'welcome' || section === 'welcome2' || section === 'welcome3' || section === 'welcome4') {
			$('#data-panel').addClass('welcome');
			$('#data-panel').hide();
			var temp = _.template(App.Template.welcome_page_panel)();
			$("div.field.image.get_ready_to_live").html(temp);
			TweenMax.fromTo($("div.field.image.get_ready_to_live .welcome_arrow img"), 0.4, {marginTop:App.viewHeight/2-85, repeat:-1}, {marginTop:App.viewHeight/2-110, repeat:-1, yoyo:true});
		} else {
			$('#data-panel').show();
			$('#data-panel').removeClass('welcome');
		}
		
		// handle 'active' style
		$('a', this.$el).removeClass('active');
		$('.'+section+' a', this.$el).addClass('active');
		
		// handle 'filled' style
		_.each(this.model.models, function(model) {
			var $el = $('.'+model.get('id')+' a', this.$el);
			if (model.get('verified') === true) {
				$el.addClass('filled');
				$el.attr("data-filled", true);
			} else {
				$el.removeClass('filled');
				$el.attr("data-filled", false);
			}
			if (model.get('readied') === true) {
				$el.addClass('readied');
			} else {
				$el.removeClass('readied');
			}
		}, this);
		
	},
	
	onClick: function(e) {
		
		var $target = $(e.target);
		var sid = $target.parent().attr('data-fid');
		
		if ($target.hasClass("filled") || $target.hasClass("active") || $target.hasClass("readied")) {
			if (sid) {
				this.appState.set( {
					'section': sid,
					'field': 'separator' 
				});
			}				
		}
	},
	
	checkVerified: function(model, data) {
		// console.log(model, data);
	}
});

App.View.DataPanel = Backbone.View.extend({
	
	initialize: function() {
		this.$self = undefined;
		this.scroller = undefined;
		this.isScrolling = false; // a flag mark scroller is scrolling
		this.appState = arguments[0].appState;
		this.render();
		this.appState.on('change:section', this.onSectionChange, this);
		this.appState.on('change:$currentDataField', this.onFieldChange, this);
		this.scroller.on('scrollStart', this.onScrollStart.bind(this));
		this.scroller.on('scrollEnd', this.onScrollEnd.bind(this));
	},
	
	render: function() {
		this.$el.empty();
		
		_.each(this.model.models, function(model) {
			
			this.$self = $(">ul:last-child", this.$el.append('<ul>'));
			this.$self.addClass(model.get('id')).attr('data-section', model.get('id'));
			new App.View.DataPanelSection({
				el		: this.$self,
				model	: model,
				appState: this.appState
			});
    	}, this);
		
		this.scroller = new IScroll('#data-fields');
		
		return this;
	},
	
	onSectionChange: function(model, section) {
		// show active sections
		var $activeSection = $('>.'+section, this.el);
		if ($activeSection.length > 0) {
			$('>ul', this.el).addClass('inactive');
			$activeSection.removeClass('inactive');
		}
		this.scroller.refresh();
		this.scroller.scrollTo(0,0);
	},
	
	onFieldChange: function(model,data) {
		// if the field is out of the panel, scroll the panel to show the field
		var p = model.get('$currentDataField').position();
		this.scroller.refresh(); // Fix Education
		if (p) {
			// console.log(p)
			if (p.top > App.dataPanelBottom) {
				// console.log('scroll up need');
				this.scroller.scrollToElement(App.Model.state.get('$currentDataField')[0]);
			}
			if (p.top < 0) {
				this.scroller.scrollTo(0,0);
			}
			
		}
	},
	
	onScrollStart: function() {
		this.appState.set('dataPanelScrolling', true, { silent : true } );
	},
	
	onScrollEnd: function() {
		this.appState.set('dataPanelScrolling', false, { silent : true });
	}
});

App.View.DataPanelSection = Backbone.View.extend({
	
	events:{
		'click .fa-info-circle'		: 'showInfo',
		'touchend .fa-info-circle'	: 'showInfo'
	},
	
	initialize: function() {
		this.appState = arguments[0].appState;
		this.render();
		this.appState.on('change:section', this.onSectionChange, this);
	},
	
	render: function() {
		var template = _.template(App.Template.data_panel_section);
		this.$el.append(template(this.model.toJSON()));
		
		var fields = this.model.get('fields').models;
		if (fields) {
			
			_.each(fields, function(field) {
				
				switch (field.get('field_type')) {
				
				case 'separator':
					// do nothing
					break;
				
				case 'image':
					this.$el.append('<li>'+ App.i18n.prop(field.get('option').text) + '</li>');
					break;
					
				case 'sum':
					new App.View.SumField({
						el		: this.$el,
						model	: field,
						appState: this.appState
					});	
					break;
									
				default:
					// create field
					new App.View.DataPanelField({
						el		: this.$el,
						model	: field,
						appState: this.appState
					});						
					break;
				}
			}, this);
		}
		
		this.$el.append( _.template(App.Template.data_panel_footer_field));
		return this;
	},
	
	showInfo: function(e) {
		Cal.openResource($('a', e.currentTarget).attr('href'), true);
		Tracking.trackEvent('FNA-'+ App.language + '/' + App.Model.state.getCurrentPageName(), 'Click', 'Notes', '');
		e.preventDefault();
	},
	
});

App.View.DataPanelField = Backbone.View.extend({
	
	initialize: function() {
		this.$self = undefined;
		this.appState = arguments[0].appState;
		this.render();
		this.model.on('change:value', this.onValueChange, this);
		this.appState.on('change:field', this.onFieldChange, this);
		
		// on related changed
		var related = this.model.get('related');
		if (related) {
			related.on('change:pass', function(model, pass) {
				if (pass) {
					this.$self.show();
				} else {
					this.$self.hide();
				}
			}, this);
			related.trigger('change:pass'); // check it when init
		}
	},
	
	render: function() {
		var template = _.template(App.Template.data_panel_field);
		var data = this.model.toJSON();
		if (data.indent) {
			data.data_type += ' indent'; 
		}
		if (data.noborder) {
			data.data_type += ' no-border'; 
		}
		this.$el.append(template(data));
		this.$self = this.$el.children().last();
		this.$self.on(App.click, $.proxy(this.onClick, this));
		return this;
	},
	
	onValueChange: function(model) {
		var text = model.get('f_value');
		$('.data', this.$self).text(text.replace('$', App.i18n.prop('hkd') ));
	},
	
	onFieldChange: function(model, data){
		if (this.model.get('id') === data) {
			this.$self.addClass('active');
		} else {
			this.$self.removeClass('active');
		}
	},
	
	onClick: function() {
		if ((this.model.isValid() || this.model.getPrevField().isValid()) && !this.appState.get('dataPanelScrolling')) {
			var fid = this.$self.attr('data-fid');
			var sid = $(this.$self.parent()).attr('data-section');
			console.log('update appState section:', sid, 'field:', fid);
			this.appState.set('section', sid);
			this.appState.set('field', fid);			
		}
	}
	
});

App.View.DataPanelBotton = Backbone.View.extend({
	
	events:{
		'click .reset'		: 'onReset',
		'touchend .reset'	: 'onReset',
		'click .prev'		: 'prevSecton',
		'touchend .prev'	: 'prevSecton',
		'click .next'		: 'nextSection',
		'touchend .next'	: 'nextSection',
		'click .result'		: 'goResult',
		'touchend .result'	: 'goResult'
	},
	
	initialize: function() {
		this.appState = arguments[0].appState;
		this.template = _.template(App.Template.data_panel_botton);
		
		this.appState.on('change:section', this.onSectionChange, this);
		this.model.on('change:verified', this.checkVerified, this);
	},
		
	onSectionChange: function(model, data) {
		this.$el.empty();
		var section = this.model.get(data);
		_.each(section.get('bottons'), function(b){
			this.$el.append(this.template(b));				
		},this);
		
		// Result button
		this.$el.append(this.template({type:'result', link:''}));
		
		// check verified
		this.checkVerified();
	},
	
	checkVerified: function() {
		
		// If all sections isVerified, show "RESULT" button & hide "RESET" button
		var totalSections = $('.data-panel-menu a').length - $('.data-panel-menu :hidden a').length;
		var filledSections = $('.data-panel-menu a[data-filled="true"]').length;
		if (totalSections == filledSections) {
			$('.result', this.$el).show();
			$('.reset', this.$el).hide();
		} else {
			$('.result', this.$el).hide();
			$('.reset', this.$el).show();
		}
	},
	
	onReset: function(e) {
		
		var owner = this;
		
		Shadowbox.open({
			content: 'pages/'+App.language+'/reset-confirm.html?'+App.i18n.prop(this.appState.get('section')),
			type: "iframe",
			player: "iframe",
			width: 390,
			height: 200,
			options: { 
				onFinish : function(e) {

					$("iframe").on("load", function(e){
						$(this).contents().find("#reset-confirm-btn").on('click', function(e){
							$.each($("#"+owner.appState.get('section')+" .field"),function(){
								$.each($(this).find("svg g g"),function(){
									owner.model.resetFields(owner.appState.get('section'));
									
									var temp_class = $(this).attr("class");
									if (temp_class == "slice active") {
										$(this).attr("class","slice");
									}
								});
							});
							
							Shadowbox.close();
							
							owner.appState.set('field','separator');
							
						});
						$(this).contents().find("#reset-cancel-btn").on('click', function(e){
							Shadowbox.close();
						});
						
					});
				}
			}
		});
		
		Tracking.trackEvent('FNA-'+ App.language + '/' + App.Model.state.getCurrentPageName(), 'Click', 'Reset', '');
	},
	
	prevSecton: function(e) {
		Tracking.trackEvent('FNA-'+ App.language + '/' + App.Model.state.getCurrentPageName(), 'Click', 'Prev', '');
		var section = this.appState.getPrevSection();
		this.goSection(section);
	},
	
	nextSection: function(e) {
		
		var pass = true;
		
		// Check fields
		var section = this.appState.getCurrentSection();
		var nextSection = this.appState.getNextSection();
		
		// All fields filled
		section.get('fields').each(function(f) {
			if (f.get('value') === null && f.get('skippable') === false) {
				
				if (f.get('related')) {
					if (f.get('related').get('pass') === true) {
						pass = false;
					}
				} else {
					pass = false;
				}
			}
			if (!pass) {
				App.Model.alert.set('message', App.i18n.prop('all_fields_must_be_filled'));
			}
			
		});
		
		// Protection: Years for Supporting
		if (section.get('id') == 'protection') {
			if (section.get('fields').get('years_for_supporting').get('value') == 0 || section.get('fields').get('other_monthly_expenses').get('value') == 0) {
				App.Model.alert.set('message', App.i18n.prop('other_monthly_expenses_error'));
				this.appState.set( {
					'section': 'protection',
					'field': 'years_for_supporting'
				});
				pass = false;
			}
		}
		
		if (pass) {
			
			Tracking.trackEvent('FNA-'+ App.language + '/' + App.Model.state.getCurrentPageName(), 'Click', 'Next', '');

			var s = section.get('id');
			var children = this.model.getField('information', 'num_of_children').get('value');
			
			if (s === 'education' || (s === 'retirement' && !children > 0)) {
				console.log('Last section completed, goto result');
				App.Result.getResult(this.model);
			} else {
				this.goSection(nextSection);							
			}
			
		}
		
	},
	
	goSection: function(section) {
		if (section) {
			this.appState.set({ 
				'section': section.id,
				'field': section.getFirstField().id
			});
		}
	},
	
	goResult: function() {
		App.Result.getResult(App.Collection.sections);
		Tracking.trackEvent('FNA-'+ App.language + '/' + App.Model.state.getCurrentPageName(), 'Click', 'Result', '');
	}
	
});

App.View.SumField = App.View.DataPanelField.extend({
	
	initialize: function() {
		App.View.DataPanelField.prototype.initialize.apply(this, arguments);
		
		_.each(this.model.get('option'), function(fid) {
			var field = this.model.collection.get(fid);
			field.on('change:value', this.onSumChange, this);
		}, this);
	},
	
	onSumChange:function() {
		var sum = 0;
		_.each(this.model.get('option'), function(fid) {
			var field = this.model.collection.get(fid);
			sum += field.get('value');
		}, this);
		this.model.set('value', sum);
	},
	
	onFieldChange: function() { },
	onClick: function() { }
});