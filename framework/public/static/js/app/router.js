// @codekit-prepend "i18n.js"
// @codekit-prepend "validator.js"
// @codekit-prepend "model.js"
// @codekit-prepend "collection.js"
// @codekit-prepend "result.js"
// @codekit-prepend "view/view.js"
// @codekit-prepend "view/alert.js"
// @codekit-prepend "view/pie-input.js"
// @codekit-prepend "view/chart.js"
// @codekit-prepend "view/input-panel.js"
// @codekit-prepend "view/data-panel.js"
// @codekit-prepend "view/scroller.js"

console.log("router.js");

App.Router = Backbone.Router.extend({
		
	initialize: function() {
		console.log("router.initialize");

		var View = App.View;
		var model = App.Collection.sections = new App.Collection.Sections();
		var state = App.Model.state = new App.Model.State();
		var alert = App.Model.alert = new App.Model.Alert();
		
		// Create sections collection
		_.each(Data.sections, function(section){
			
			// push section model to collection
			var section = new App.Model.Section(section);
			model.push(section);

		}, this);
		
		// When something need 'sections' created before start
		// Listen 'created' event. e.g. App.Collection.sections.on('created', doSomething);
		model.trigger('created', App.Collection.sections);
				
		View.background = new View.Background({
			el			: '#input-background>div',
			model		: model,
			appState	: state
		});
		
		View.section = new View.Section({
			el			: '#input-panel .scroller',
			model		: model,
			appState	: state
		});
		
		// center intro fields
		_.each($('.intro'), function(intro) {
			$(intro).parent().css('padding-top', (App.viewHeight - $(intro).outerHeight())/2);
		});
		
		View.dataPanelMenu = new View.DataPanelMenu({
			el			: '#data-panel .data-panel-menu>ul',
			model		: model,
			appState	: state
		});
		
		View.dataPanel = new View.DataPanel({
			el			: '#data-fields .scroller',
			model		: model,
			appState	: state
		});
		
		View.dataPanelBotton = new View.DataPanelBotton({
			el			: '#data-control',
			model		: model,
			appState	: state
		});
		
		// Data input panel scroller
		View.scroller = new View.Scroller({
			el			: '#input-panel',
			options		: {
				snap 	: '#input-panel .field',
				deceleration: 0.01
			},
			model		: model,
			appState	: state
		});
		
		// Alert
		View.alert = new View.Alert({
			el: '#alert',
			model: alert
		});
				
		// Degug view, can be remove will production
		/*
		View.debug = new View.Debug({
			el			: '#debug'
		});
		*/
		
		/*  ----------------------------------
		 *  Some special handle code below >:P
		 *  ----------------------------------
		 */
		
		// Estimate Annual Expense for <selected country>
		for (var i=1; i<=3; i++) {
			var field = model.getField('education', 'child'+i+'_country_of_studying');
			field.on('change:value', function(model, data) {
				this.estimateAnnualExpenseOfChild(model, data);
			}, this);
		}
		
	},
	
	/* 
	 * Estimate Annual Expense Of Child
	 * Collecting data and pass to Cal.calculateTotalExpensesPerYear( ) to cal the child_manual_total_expense
	 */
	estimateAnnualExpenseOfChild: function(model, data) {
		var collection = App.Collection.sections;
		var child = model.get('id').split('_')[0];
		var country_for_studying = data;
		var annual_inflation_rate = collection.getField('finance', 'annual_inflation_rate').get('value') / 100;
		var age_to_enter_university = collection.getField('education', child+'_age_to_enter_university').get('value');
		var current_age = collection.getField('education', child+'_age').get('value');
		var value = Cal.calculateTotalExpensesPerYear(country_for_studying, annual_inflation_rate, age_to_enter_university, current_age);
		collection.getField('education', child+'_manual_total_expense').set('value', value);
	}
	
});

/**
 * App start from here
 * 
 */
$(function() {
	
	// Init layout
	App.barHeight = $(".header.bar").height();
	App.viewHeight = $("#input-panel").height();
	App.viewWidth = $("#input-panel").width();
	App.dataPanelBottom = $('#data-control').position().top - 80;
	App.fieldSize = 400;
	App.fieldPaddingTop = (App.viewHeight - App.fieldSize) /2;
	
	// App config
	App.mainAppConfig = Cal.getConfigs();
	App.language = App.mainAppConfig.language;
	// App.language = 'zh'; // testing
	
	// Init backbone
	App.Router.router = new App.Router();
	Backbone.history.start();
	console.log("*** Backbone Router inited ***");
	
	// Go to Welcome section
	App.Model.state.set('section', 'welcome');
	$("#addRPQButton").hide();
	
	// Other 3th party plug-ins
	Shadowbox.init({
		overlayOpacity	: 0.4,
		displayCounter	: false,
		fadeDuration	: 0
	});
	
});