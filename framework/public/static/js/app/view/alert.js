console.log('view/alert.js');

App.View.Alert = Backbone.View.extend({
	
	events: {
		'click' : 'close'
	},
	
	initialize: function() {
		this.model.on('change:message', this.render, this);
	},
	
	render: function() {
		
		var template = _.template(App.Template.alert);
		this.$el.empty();
		this.$el.append(template(this.model.toJSON()));
		if (this.model.get('message')) {
			this.$el.show();			
		} else {
			this.$el.hide();
		}
		return this;
		
	},
	
	close: function() {
		this.model.set('message', '');
	}
	
});