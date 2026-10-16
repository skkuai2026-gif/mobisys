console.log('view/chart.js');

App.View.Chart = {};

App.View.Chart.createChart = function(data) {

    /* Sample
    data = {
        "currency": currency,
        "label": main_label,
        "value": main_value,
        "chart_data": chart_data,
        "el": "#chart"
    }
     */
    var self = App.View.Chart;

    // add index to data
    for (var i = 0; i < data.chart_data.length; i++) {
        data.chart_data[i] = _.extend(data.chart_data[i], {
            index: i
        });
    }
    
    var labelAngle = []; // store labels' location in angle, use it to adjust the labels overlap issue

    var w = App.viewWidth,
        h = App.viewHeight,
        r = 150,
        label_r = 230,
        deg = 1 / (180 / Math.PI);
    var center_circle_rate = 0.8,
        center_trans = "translate(" + w / 2 + "," + h / 2 + ")";
    var donut = d3.layout.pie(),
        arc = d3.svg.arc().innerRadius(r * center_circle_rate).outerRadius(r),
        d3_format = d3.format("0,000"),
        color = ["#9CBC59", "#637839", "#73868A", "#002123", "#25484D"],
        gapColor = "#38c",
        viewBox = Number(w / 2 - 317) + "," + Number(h / 2 - 306) + ", 634, 612"; // base on 1024 x 768 screen

    //Disable sort by value
    donut.sort(null);

    d3.select(data.el + ' svg').remove();

    var svg = d3.select(data.el)
        .append("svg:svg")
        .data([data.chart_data])
        .attr("width", w)
        .attr("height", h)
        .attr("viewBox", viewBox);

    /*
     * Arcs
     */
    var arcs = svg.selectAll("g.arc")
        .data(donut.value(function(d) {
            return d.value
        }))
        .enter().append("svg:g")
        .attr("class", "arc")
        .attr("transform", center_trans);

    arcs.append("svg:path")
        .attr("fill", function(d, i) {
            if (data.chart_data.length == i + 1) {
                return gapColor;
            };
            return color[i];
        })
        .attr("class",function(d){
            //return 'highlight-' + d.data.class;
        })
        .transition()
        .duration(1000)
        .attrTween("d", drawPie);

    /*
     * polyline
     */
    arcs.append("svg:polyline")
            .attr("style", "stroke:white; stroke-width:0.8; fill:none;")
            .attr("points", function(d) {
                var labelPos = getLabelPosition(d);
                var arcPos = arc.centroid(d);
                var p1 = labelPos[0] + "," + labelPos[1];
                var p2 = arcPos[1] > labelPos[1] ? arcPos[0] + "," + labelPos[1] : labelPos[0] + "," + arcPos[1];
                var p3 = arcPos[0] + "," + arcPos[1];
                var lines = p1 + "," + p2 + "," + p3;
                if (d.value == 0) {
                    lines = "";
                }
                return lines;
            });
    
    /*
     * Labels
     */
    var fontSize = (App.language=="zh") ? 14 : 13;
    var labels = arcs.append("svg:g")
        .attr("transform", function(d) {
            // L polyline
            var p = getLabelPosition(d);
            var x = p[0] > 0 ? p[0] + 5 : p[0] - 5;
            var y = p[1];
            return "translate(" + x + "," + y + ")";
        })
        .attr("style","display:block")
        .attr("text-anchor", function(d) {
            return (d.endAngle + d.startAngle) / 2 > Math.PI && (d.startAngle < Math.PI) ? "end" : "start";
        });
    
    // Label
    labels.append("svg:text")
        .attr("transform", "translate(0,-10)")
        .attr("font-size", fontSize)
        .text(function(d, i) {
            var label = data.chart_data[i].label;
            return label;
        });
    
    // Value
    labels.append("svg:text")
        .attr("transform", "translate(0,10)")
        .attr("font-size", 20)
        .text(function(d, i) {
            var label = data.currency + d3_format(data.chart_data[i].value);
            return label;
        });


    /*
     * Center circle
     */
    var centerContainer = svg.append('g').attr("class", "center-circle");
    centerContainer.append('circle')
        .attr("transform", center_trans)
        .attr('fill', '#FFF')
        .attr('r', r * center_circle_rate);

    centerContainer.append("svg:text")
        .attr("transform", "translate(" + w / 2 + ',' + Number(h / 2 - 10) + ")")
        .attr("text-anchor", "middle")
        .text(function() {
            var label = data.label;
            return label;
        });

    centerContainer.append("svg:text")
        .attr("transform", "translate(" + w / 2 + ',' + Number(h / 2 + 30) + ")")
        .attr("text-anchor", "middle")
        .attr("fill", "#38c")
        .attr("font-size", 40)
        .text(function() {
            var value = data.value;
            value = d3_format(value);
            return data.currency + value;
        });

    _.each($('#result-chart svg .arc'), function(arc) {
        $(arc).prependTo('#result-chart svg');
    });

    function getLabelPosition(d) {
        var minDeg = 35 * deg; // minimum angle two labels 
        var center = (d.startAngle + d.endAngle) / 2;
        if (d.data.index > 0) {
        	var lastCenter = labelAngle[d.data.index -1];
        	if (center < lastCenter + minDeg) { // label overlap, move the label to minDeg
        		center = lastCenter + minDeg;
        	}        	
        }
        labelAngle[d.data.index] = center;
        
        center -= 90 * deg; // shift 90 deg
        var x = label_r * Math.cos(center) - Math.cos(center) *30;
        var y = label_r * Math.sin(center);
        y = y - (y - label_r) / label_r * 20; // shift top and bottom y
                
        return [x, y];
    }

    function drawPie(b) {
        var i = d3.interpolate({
            startAngle: 0 * Math.PI,
            endAngle: 0 * Math.PI
        }, b);
        return function(t) {
            if (t == 1) {
                onDrawComplete();
            };
            return arc(i(t));
        };
    }

    function onDrawComplete() {

        var gap = $('.arc path.gap', data.el);
        if (gap.length == 0) {
            // clone gap arc
            gap = $('.arc path', data.el).first();
            var default_class = '';
            if (gap.attr('class')) {
                default_class = gap.attr('class');
            };
            if (gap.length == 1) {
                var clone_gap = gap.clone();
                gap.after(clone_gap);
                clone_gap.attr('class', default_class+' gap');
            };
            _.delay(function() {
                $('.gap').attr('class', default_class+' gap zoom');
            }, 1);

        }

        // Gerry Quick Hack : State chart is creating/finished
        // if creating, disable left panel menu click function
        App.View.Chart.createStatus = 'finished';

    }
};
