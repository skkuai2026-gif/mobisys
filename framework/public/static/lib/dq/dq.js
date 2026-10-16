// DQ namespace
DQ = {};

//fix IE 'console is undefined' error
if (!window.console) { 
    window.console = {
        log: 	function(obj) { /* define own logging function here, or leave empty */ }
    };
}


// template loader
DQ.tpl = 
{
    // Hash of preloaded templates for the app
    templates:{},
    
    // load templates in single file
    loadTemplates: function(file, callback) {
    	
    	var that = this;
    	
		$.get(file, function (source) {
			var templates = source.split('<!---');
			_.each(templates, function(template) {
				if (template) {
					var name = template.split('--->')[0];
					var data = template.split('--->')[1];
					that.templates[name] = data;
					//console.log('template ' + name + ' loaded.');			
				}
			});
			callback();
		});
    },

    // Get template by name from hash of preloaded templates
    get:function (name) {
        return this.templates[name];
    }

};

// Number formater
// e.g. $1200.10 change to $1,200.00
DQ.addCommas = function(nStr)
{
	nStr += '';
	x = nStr.split('.');
	x1 = x[0];
	x2 = x.length > 1 ? '.' + x[1] : '';
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(x1)) {
		x1 = x1.replace(rgx, '$1' + ',' + '$2');
	}
	return x1 + x2;
}

// Replace line break to <br/>
DQ.replaceLineBreak = function(str)
{
	var str = str.replace(/\n/g, '<br />');
	return str;
}

// Return days of the month
// e.g. DQ.calDays(2012,2), return 29
DQ.calDays = function(year,month)
{
    var days=0;
    switch(Number(month)){
        case 1: case 3: case 5: case 7: case 8: case 10: case 12: days=31;break;
        case 4: case 6: case 9: case 11: days=30;break;
        case 2: if(DQ.isLeapYear(Number(year))) days=29;
        else days=28;
        break;
    }
    return days;
}
// Is leap year? (是潤年嗎？)
DQ.isLeapYear = function(year)
{
    if((year %4==0 && year %100!=0) || (year %400==0)) return true;
    else return false;
}
// convert form to json data (jQuery required)
// e.g. json_data = JSON.stringify($('#form').serializeObject();
$.fn.serializeObject = function()
{
    var o = {};
    var a = this.serializeArray();
    $.each(a, function() {
        if (o[this.name] !== undefined) {
            if (!o[this.name].push) {
                o[this.name] = [o[this.name]];
            }
            o[this.name].push(this.value || '');
        } else {
            o[this.name] = this.value || '';
        }
    });
    return o;
};


