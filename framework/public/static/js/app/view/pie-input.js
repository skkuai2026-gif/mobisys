console.log('view/pie-input.js');

/**
 * Use D3.js create pie style input box
 */

App.View.PieInput = Backbone.View.extend({
	
	initialize:function () {
		this.arc = null;
		this.render();
	},
	
	render: function() {

		this.$el.empty();
			
		var r = 200;
		var model = this.model; // App.Model.Field
		var data = _.map( model.get('option'), function(d) { return { value:d, model:model }; } );
		var lineGap = 0.1/data.length;
		
		d3.dispatch("load", "statechange");
		
		var vis = d3.select(this.el)
			.append("svg:svg")
			.data([data])
            .attr("width", r*2)
            .attr("height", r*2)
            .append("svg:g")
            .attr("transform", "translate(" + r + "," + r + ")");
		
		var backArc = d3.svg.arc()
        	.outerRadius(r)
        	.innerRadius(r/2);
		
		var lineArc = d3.svg.arc()
	    	.outerRadius(r-8)
			.innerRadius(r-13)
			.startAngle(function(d){ return d.startAngle + lineGap; } )
			.endAngle( function(d) { return d.endAngle - lineGap; } );
		
		var pie = d3.layout.pie()
        	.value(function() { return 1; })
        	.sort(null);
		
		this.arcs = vis.selectAll("g.slice")
	        .data(pie) 
	        .enter()
	        .append("svg:g")
	        .attr("class", "slice");
		
		
		// background
		this.arcs.append("svg:path")
			.attr("d", backArc)
			.attr("class", "background")
			.on(App.mousedown, function() {
				$('.slice', $(this).closest('svg')).attr('class', 'slice');
				d3.select(this.parentNode).classed('active', true);
			});
		
		// red line
		this.arcs.append("svg:path")
			.attr("class", "outline")
			.attr("d", lineArc);
		
		// label
		this.arcs.append("svg:text")
			.attr("class", "label")
        	.attr("transform", function(d) {
		        var c = backArc.centroid(d),
		            x = c[0],
		            y = c[1],
		            h = Math.sqrt(x*x + y*y);
		        return "translate(" + (x/h * 156) +  ',' +
		           (y/h * 156) +  ")"; 
		    })
        	.attr("text-anchor", "middle")
        	.text(function(d, i) { return App.i18n.prop(data[i].value); });
		
		
		
		// center circle
		var circle = vis.append('circle')
			.attr('fill', 'white')
			.attr('r', 125)
			.style("filter", "url(#shadow)");
		
		
	
		return this;
	}
	
});