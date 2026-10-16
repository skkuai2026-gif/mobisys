/**
 * iScroll of input-panel
 */
App.View.Scroller = Backbone.View.extend({
	
	iScroll:{}, /* iScroll */
	bounceBack: false, // bounce back to prev field when scrollEnd
	
	initialize:function (arg) {
		this.appState = arg.appState;
		this.iScroll = null;
		
		this.iScroll = new IScroll(arg.el, _.extend(arg.options, { view: this }));
		
		this.iScroll.on('scrollStart', function() {
			//console.log('iScroll event: scrollStart');
			var view = this.options.view;
			var state = view.appState;			
			var field = view.model.getField(state.get('section'), state.get('field'));
			
			// Handle bounce back for field valid fail
			if (field) {
				if (!field.isValid()) {
					view.bounceBack = true;
					// console.log("iScroll will be bounce back");
				}
			}
			
			// Going to next section
			var $field = $(this.options.snap[this.currentPage.pageY]);
			var $lastField = $('.field:not(".related-fail")', $field.parent()).last();
						
			if ($field[0] === $lastField[0]) {
				if (this.distY <= 0) {
					// console.log('Going to next section');
					
					var section = state.get('section');
					var children = view.model.getField('information', 'num_of_children').get('value');
					
					// got to result page, if last field of education or last field of retirement and there is not children
					if (section === 'education' || (section === 'retirement' && !children > 0)) {
						console.log('Last section completed, goto result');
						App.Result.getResult(view.model);
					}
					
				}
			}
		});
								
		this.iScroll.on('scrollEnd', function() {
			//console.log('iScroll event: scrollEnd');
						
			var view = this.options.view;
			// find current DOM field
			var $field = $(this.options.snap[this.currentPage.pageY]);
			var $section = $($field.parent());
			var sid = $section.attr('id');
			var fid = $field.attr('data-fid');
			
			if (view.appState.get('section') === sid && view.appState.get('field') === fid) {
				// didn't scroll to new page, do noting
				// console.log('Gerry', 'didn\'t scroll to new page, do noting');
			} else {
				// handle bounce back
				if (view.bounceBack && this.distY <= 0 ) {
					view.bounceBack = false;
					this.prev();
					var currentField = view.appState.getCurrentField();
					currentField.trigger('change:active', currentField, true);
					console.log('bounce back to prev field');
					return;
				}
				
				// handle 'related-fail' field
				if ($field.hasClass('related-fail')) {
					_.delay( function(iScroll) {
						var nextField;
						var back = iScroll.distY > 0;
						if (back) {
							nextField = view.model.getNextField(true);			
						} else {
							nextField = view.model.getNextField();
						}
						
						if (nextField) {
							console.log('Is related-fail field:' + $field.attr('data-fid'), "auto scroll to next field:", nextField.get('id'));
							view.appState.set('field', nextField.get('id'));							
						} else {
							var sid = view.model.getNextSection(back).get('id');
							view.appState.set({
								'section': sid,
								'field' : 'separator' });
							console.log('Is related-fail field:' + $field.attr('data-fid'), " and it is last field of section, auto scroll to next section.", sid);
						}
					}, 10, this);
				}
				
				// update appState model
				
				// Spacial handling
				// Protection: Years for Supporting
				var section = view.appState.getCurrentSection();
				if (sid == 'retirement' && fid == 'separator') {
					if (section.get('fields').get('years_for_supporting').get('value') == 0 || section.get('fields').get('other_monthly_expenses').get('value') == 0) {
						App.Model.alert.set('message', App.i18n.prop('other_monthly_expenses_error'));
						console.log('Special change the field scroll to :', sid, fid);
						sid = 'protection';
						fid = 'years_for_supporting';
					}
				}
				
				// console.log('scroller update appState section:', sid, 'field:', fid);
				view.appState.set({ 
					'section': sid,
					'field'	: fid
				});
						
			}
			
			// reset bounceBack flag
			view.bounceBack = false;
			
			//console.log('Current field:', fid);				
		});
		

		this.appState.on('change:field', function(model, data) {
			
			 // If the field is 'separator',
			 // delay 1 sec. auto scroll to next/prev field
			if (data === 'separator') {
				var delay = (this.iScroll.distY <= 0) ? 500 : 0;
				_.delay(function(e) {
					if (e.iScroll.distY <= 0) {
						e.iScroll.next();
					} else {
						e.iScroll.prev();
					}
					//console.log('Separator auto scroll to next field');
				}, delay, this);
			}			
		}, this);
		
		this.appState.on('change', function() {
			this.scrollToPage();
		}, this);
	},
	
	scrollToPage: function() {
		var q = this.appState.get('section') ? '#'+this.appState.get('section') : '';
		q += this.appState.get('field') ? ' .'+this.appState.get('field') : '';
		var el = q ? $(q)[0] : null;
		if (el) {
			var index = $(this.iScroll.options.snap).index(el);
			if (index >= 0) {
				// console.log("Scroll to page:", index);
				this.iScroll.goToPage(0, index);				
			}
		}
	}
	
});
