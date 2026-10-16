console.log('view.js');

App.View.Background = Backbone.View.extend({

	scroller: null,
	
	initialize:function(arg) {
		
		function scrollBG(model, data) {
			var $bg = $("."+data, this.$el);
			if ($bg.length > 0) {
				var y = $bg.position().top;
				this.scroller.scrollTo(0, -y, 1200);
				if (data=="welcome" || data=="welcome2" || data=="welcome3" || data=="welcome4") {
					$(".image."+data).css("background-size", "contain");
					$(".image."+data).css("background-repeat", "no-repeat");
				}
			}
        }
		
		this.appModel = arg.appState;
		this.render();
		this.appModel.on('change:section', scrollBG, this);
    },
    
    render: function() {
    	this.$el.empty();
    	var template = _.template(App.Template.background);
    	_.each(this.model.models, function(model) {
    		this.$el.append(template(model.toJSON()));
    	}, this);
    	
    	this.scroller = new IScroll(this.$el.parent()[0], {
    		bounce: false,
    		momentum: false
    	});
    	this.scroller.disable(); // background only control by program
    	
    	return this;
    }
    
});

/**
 * Debug console view
 * Should be remove when production
 */
App.View.Debug = Backbone.View.extend({
	
	initialize:function () {
		this.render();
	},

	render: function() {
		this.$el.empty();
		this.$el.append('<i class="fa fa-bug"></i><div class="console"></div>');
		
		var $console = $('.console', this.$el);
		var $icon = $('.fa-bug', this.$el);
		
		// Echo main app data
		var $appData = $('<ul></ul>');
		for(var key in App.mainAppConfig) {
			$appData.append("<li>"+key + ": "+ App.mainAppConfig[key]+ "</li>");
		}

		
		if(App.mainAppConfig['fwd_logo']!="undefined"){
			$appData.append('<li><img src="'+App.mainAppConfig['fwd_logo']+'" /></li>');
		}else{
			
		}
		if(App.mainAppConfig['partner_logo']!="undefined"){
			$appData.append('<li><img src="'+App.mainAppConfig['partner_logo']+'" /></li>');
		}else{
			
		}
		// Append testing links
		var $testLinks = $('<ul></ul>');
		$testLinks.append('<li><a rel="shadowbox[Mixed]" href="testing/FWD_eLib_demo_singlefile_s1_1.html">Test Link 1</a></li>');
		$testLinks.append('<li><a rel="shadowbox[Mixed]" href="testing/FWD_eLib_demo_singlefile_s2_1.html">Test Link 2</a></li>');
		$testLinks.append('<li><a rel="shadowbox[Mixed]" href="testing/FWD_eLib_demo_singlefile_s5_2.html">Test Link 3</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'http://c2lbiz.com/zh-HK/cs/index.html\')">xyz</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/en/online-security.html\')">Online Security</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/en/disclaimer.html\')">Disclaimer</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'http://www.c2lbiz.com/en-US/home/pdo.html\', true)">Personal Data Protection Policy and Practices</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/zh/online-security.html\')">網上保安</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/zh/disclaimer.html\')">免責聲明</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'http://www.c2lbiz.com/zh-HK/home/pdo.html\', true)">個人資料保護政策及執行</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/en/life-protection-calculation.html\')">Life Protection Calculation</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/en/critical-illness-calculation.html\')">Critical Illness Calculation</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/en/retirement-needs-calculation.html\')">Retirement Needs Calculation</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/en/education-needs-calculation.html\')">Education Needs Calculation</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/zh/life-protection-calculation.html\')">計算所需人壽保障</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/zh/critical-illness-calculation.html\')">計算所需危疾保障</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/zh/retirement-needs-calculation.html\')">計算所需退休儲備金</a></li>');
		$testLinks.append('<li><a href="javascript:Cal.openResource(\'pages/zh/education-needs-calculation.html\')">計算所需教育基金</a></li>');
		
		// Test case
		var $testcase = $('<ul></ul>');
		
		$testcase.append('<li><a href="#" onclick="Cal.sendReport({\'customer_name\':\'Peter Wong\',\'customer_email\':\'\',\'advisor_name\':\'Sunny Lee\',\'date\':\'06/06/2014\',\'xxxxx\':\'$22123\',\'results\':App.Result.results,\'inputData\':App.Result.inputData})">GEN REPORT</a></li>');
		
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(0);">Test case: Marry Lee</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(1);">Test case: Susan Chan</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(2);">Test case: Johnny Tse</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(3);">Test case: Tom</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(4);">Test case: Kitty</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(5);">Test case: Cathy</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(6);">Test case: Tom Lee</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(7);">Test case: Gerry Ho</a></li>');
		$testcase.append('<li><a href="#" onclick="Testcase.setCase(8);">Test case: Peter</a></li>');
		//$testcase.append('<li><a href="#" onclick="Testcase.setCase(0);">Test case: Reset All Fields</a></li>');
		
		$console.append($appData);
		$console.append($testLinks);
		$console.append($testcase);
		
		$icon.click(function() {
			if ($console.is(":visible")) {
				$console.hide();
			} else {
				$console.show();
			}
		});
		this.$el.show();
	}
});