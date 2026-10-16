console.log("collection.js");

/**
 * Sections Collection
 */

App.Collection.Sections = Backbone.Collection.extend({
	model: App.Model.Section,
		
	/**
	 * Get field model by section key and field Key under collection of section models
	 * 
	 *	@param sid 			string		section id
	 *	@param fid			string		field id
	 *	@param collection	collection	for recursive, no need input
	 * 
	 **/
	getField: function(sid, fid) {
		
		var field = null;
		var section = this.get(sid);
		
		if (section) {
			field = section.get('fields').get(fid);
			if (!field) {
				console.log("Field:" + fid + " not found in Section:" + sid);
			}
		} else { 
			console.log('Section:', sid, 'not found');
		}
		return field;
	},
	
	/**
	 * get field value by section id and field id
	 */
	getValue: function(sid, fid) {
		return this.getField(sid, fid).get('value');
	},
	
	/**
	 * Reset input fields of the section
	 * If section is null, reset all fields
	 */ 
	resetFields: function(sid) {
		var section = this.get(sid);
		//console.log('reset section',section);
		_.each(section.get('fields').models, function(f) {
			// console.log(f.get('id'));
			f.setDefaultValue(true);
		}, this);
	},
	
	/**
	 * Get next field, related-fail not included
	 * 
	 * set prev to true, to get prev field. 
	 */
	getNextField: function(prev) {
		
		var sid = App.Model.state.get('section');
		var fid = App.Model.state.get('field');
		var section = this.get(sid);
		var fields = section.get('fields').models;
		var index = -1;
		var nextField = false;
		
		// find index of field
		if (!fid) {
			index = 0;
		} else {
			for (var i=0; i<fields.length; i++) {
				if (fields[i].get('id') === fid) {
					index = i;
					break;
				}
			}			
		}
		
		// find next / prev passed field
		if (index > -1) {
			if (prev) {
				for (var i=index-1; i>=0; i--) {
					if (fields[i].get('related')) {
						if (fields[i].get('related').get('pass')) {
							nextField = fields[i];
							break;
						}
					} else {
						nextField = fields[i];
						break;
					}
				}
			} else {
				for (var i=index+1; i<fields.length; i++) {
					if (fields[i].get('related')) {
						if (fields[i].get('related').get('pass')) {
							nextField = fields[i];
							break;
						}
					} else {
						nextField = fields[i];
					}
				}
			}
		}
		return nextField;	
	},
	
	getNextSection:function(prev) {
		var sid = App.Model.state.get('section');
		var index = this.indexOf(this.get(sid));
		index = (prev) ? index-1 : index+1;
		index = (index<0) ? 0: index;
		index = (index>this.models.length-1) ? this.models.length-1 : index;
		return this.models[index];
	}
		
});


App.Collection.Fields = App.Collection.Sections.extend({
	model: App.Model.Field
});