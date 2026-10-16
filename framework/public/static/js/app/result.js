console.log("result.js");

$(function() {
	
	_.delay(function(){
		
		// append background
		$('#result-background').append(_.template(App.Template.background, 
			{ 
				id:'result', 
				background_image:'result_bg.jpg',
			}));
				
	}, 1000);
	
	// When menu icon click
	$('#result-panel nav').on(App.click, function(e){
		if (App.View.Chart.createStatus == 'creating') {
			return false;
		}
		
		App.loadSectionPanel(e);
	});

});

App.loadSectionPanel = function(e) {
	var section = $(e.target).parent().attr('data-section');
	if (typeof e.target == "string") {
		section = e.target;
	}
	// console.log('Gerry onclick ', section, e.target);
	
	var $resutControl = $('#result-control');
	var buttonTpl = template = _.template(App.Template.data_panel_botton);
	
	// highlight icon
	$('a', e.currentTarget).removeClass('active');
	$(e.target).addClass('active');
	
	// render buttons bar
	$resutControl.empty();
	$resutControl.append(buttonTpl({ type: 'email', link:'' }));	// Email button
	if (section != 'suggestions' && section != 'overview') {
		$resutControl.append(buttonTpl({ type: 'notes', link:'' }));	// Notes button		
	}
	$resutControl.append(buttonTpl({ type: 'modify', link:'' })); // Modify botton
	
	
	
	// Show Send Email frame
	$('.email', $resutControl).on(App.click, function(e) {
		
		Shadowbox.open({
			content: '../pages/'+App.language+'/send-email.html',
			type: "iframe",
			player: "iframe",
			width: 740,
			height: 368,
			options: { 
				onFinish : function(e) {
					
					function validateEmail(sEmail) {
						var filter = /^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$/;
					
						if (filter.test(sEmail)) {
							return true;
						}
						else {
							return false;
						}
					}
					
					$("iframe").on("load", function(e){
						
						$("#sb-wrapper").addClass('sb-wrapper-fixsize');
						$("#sb-wrapper-inner").addClass('sb-wrapper-inner-fixsize');
						
						$(this).contents().find("#send-email-btn").on('click', function(e){
							
							
							// Form check
							var formValid = true;
							if (!$(this).parent().find("#name-txt").val() != '') {
								alert(App.i18n.prop('name_valid'));
								formValid = false;
							}
							if (!validateEmail($(this).parent().find("#email-txt").val())) {
								alert(App.i18n.prop('email_valid'));
								formValid = false;
							}
							var finalReportHTML = "";
							console.log($(this));
							if(formValid){
								var formattedDate = "";
								var dateObj = new Date();
								formattedDate = dateObj.getDate()+"/"+(dateObj.getMonth()+1)+"/"+dateObj.getFullYear();
								
								var advisorString = "";
								if(Cal.appSetting.get('language')=="zh"){
									if(Cal.appSetting.get('advisor_name_zh')!=""){
										advisorString += decodeURIComponent(Cal.appSetting.get('advisor_name_zh'))+" ";
									}
									if(Cal.appSetting.get('advisor_name_en')!=""){
										advisorString += "("+decodeURIComponent(Cal.appSetting.get('advisor_name_en'))+")";
									}
								}else{
									if(Cal.appSetting.get('advisor_name_en')!=""){
										advisorString += decodeURIComponent(Cal.appSetting.get('advisor_name_en'))+" ";
									}
									if(Cal.appSetting.get('advisor_name_zh')!=""){
										advisorString += "("+decodeURIComponent(Cal.appSetting.get('advisor_name_zh'))+")";
									}
								}
								
								finalReportHTML = Cal.sendReport(
									{
										'customer_name'		: $(this).parent().find("#name-txt").val(),
										'customer_email'	: $(this).parent().find("#email-txt").val(),
										'advisor_name'		: advisorString,
										'date'				: formattedDate,
										'results'			: App.Result.results,
										'inputData'			: App.Result.inputData
									}
									// for preview only
									, $(this).parents().find("body")
									// for preview only end
								);
							}
							
							Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Email FNA Report Form', 'Click', 'Send', '');
						});
						
						
					});
				}
			}
		});
		
		Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Email FNA Report Form', 'Click', 'Email', '');
		return true;
		
	});
	
	
	
	// Show Notes
	$('.notes', $resutControl).on(App.click, function(e) {
		
		switch (section) {
			case 'critical_illness_protection':
				Cal.openResource('../pages/'+App.language+'/critical-illness-calculation.html', false);
				break;
			case 'life_protection':
				Cal.openResource('../pages/'+App.language+'/life-protection-calculation.html', false);
				break;
			case 'retirement':
				Cal.openResource('../pages/'+App.language+'/retirement-needs-calculation.html', false);
				break;
			case 'education':
				Cal.openResource('../pages/'+App.language+'/education-needs-calculation.html', false);
				break;
			default:
				console.log("section not found:", section);
				break;
		}
		
		App.Result.trackEvent(section, 'Click', 'Notes', '');
	});
	
	// Back to input panel, when modify
	$('.modify', $resutControl).on(App.click, function(e) {
		
		$('#result .result-menu ul li a.active').removeClass("active");
		$('#result .result-menu ul li').first().find('a').addClass('active');
		
		$('#input').show();
		$('#result').hide();
		
		// console.log('modify section : ', section, goSection);
		
		$('.'+section+' a').removeClass('filled');
		
		var goSection = section;
		if (section == 'critical_illness_protection' || section == 'life_protection') {
			goSection = 'protection';
		}
		if (section == 'suggestions' || section == 'overview') {
			goSection = 'information';
		}
		
		App.View.dataPanel.appState.set({
			'section': goSection,
			'field': App.Collection.sections.get(goSection).get('fields').at(1).id
		});
		
		App.Result.trackEvent(goSection, 'Click', 'Modify', '');
	});
	
	// show section panel
	$('#result-fields ul').addClass('inactive');
	$('.'+section).removeClass('inactive');
	
	// draw chart
	App.Result.drawChart(section);
	if (section == 'suggestions') {
		// Gerry Quick Hack : State chart is creating/finished
		// if creating, disable left panel menu click function
		App.View.Chart.createStatus = 'finished';
	};
	
	App.Result.trackEvent = function(id, action, label, value) {
		switch (section) {
		case 'critical_illness_protection':
			Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Critical Illness Protection', action, label, value);
			break;
		case 'life_protection':
			Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Life Protection', action, label, value);
			break;
		case 'retirement':
			Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Retirement', action, label, value);
			break;
		case 'education':
			Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Education', action, label, value);
			break;
		case 'overview':
			Tracking.trackEvent('FNA-'+ App.language +'/Page-Result-Overview', action, label, value);
			break;
		default:
			console.log("section not found:", section);
			break;
		}
	};
	
};

App.Result = {
		
		results: {},
		inputData: {},

		drawChart: function(section) {
			
			var currency = '';
		    var main_label = "";
		    var main_value = "";
		    var chart_data,
		    	subburst_chart_data,
		    	education_chart_data;
		    $("#addRPQButton").show();
			switch (section) {
			
				case 'suggestions':
					Tracking.trackPageview('FNA-'+ App.language +'/Page-Result-Suggestions');
					break;
					
				case 'overview':
					chart_data = [{
				        label: App.i18n.prop('liquid_assets'),
						class: 'liquid_assets',
				        value: this.results.life_protection.liquid_assets
				    }, {
				        label: App.i18n.prop('current_life_protection'),
						class: 'current_life_protection',
				        value: this.results.life_protection.current_life_protection
				    }, {
				        label: App.i18n.prop('current_ci_protection'),
						class: 'current_critical_illness_protection',
				        value: this.results.critical_illness_protection.current_ci_protection
				    }];
					if (this.results.retirement) {
						chart_data.push({
					        label: App.i18n.prop('mpf'),
							class: 'mpf',
					        value: this.results.retirement.mpf
					    });
					}
					if (this.results.education) {
						chart_data.push({
					        label: App.i18n.prop('education_fund'),
							class: 'education_fund',
					        value: this.results.education.total_education_fund
					    });
					}
					
					chart_data.push({
				        label: App.i18n.prop('gap'),
						class: 'protection_gap',
				        value: this.results.total_gap
				    });
					
					main_label = App.i18n.prop('total_financial_need');
					main_value = this.results.total_need;
					
					Tracking.trackPageview('FNA-'+ App.language +'/Page-Result-Overview');
					break;
					
				case 'life_protection':
					chart_data = [{
				        label: App.i18n.prop('liquid_assets'),
						class: 'liquid_assets',
				        value: this.results.life_protection.liquid_assets
				    }, {
				        label: App.i18n.prop('current_life_protection'),
						class: 'current_life_protection',
				        value: this.results.life_protection.current_life_protection
				    }, {
				        label: App.i18n.prop('protection_gap'),
						class: 'protection_gap',
				        value: this.results.life_protection.protection_gap
				    } ];
					main_label = App.i18n.prop('life_protection_need');
					main_value = this.results.life_protection.life_protection_need;
					
					Tracking.trackPageview('FNA-'+ App.language +'/Page-Result-Life Protection');
					break;
					
				case 'critical_illness_protection':
					chart_data = [{
				        label: App.i18n.prop('current_ci_protection'),
						class: 'current_ci_protection',
				        value: this.results.critical_illness_protection.current_ci_protection
				    }, {
				        label: App.i18n.prop('protection_gap'),
						class: 'protection_gap',
				        value: this.results.critical_illness_protection.protection_gap
				    } ];
					main_label = App.i18n.prop('ci_protection_need');
					main_value = this.results.critical_illness_protection.ci_protection_need;
					
					Tracking.trackPageview('FNA-'+ App.language +'/Page-Result-Critical Illness Protection');
					break;
					
				case 'retirement':
					chart_data = [{
				        label: App.i18n.prop('mpf'),
						class: 'mpf',
				        value: this.results.retirement.mpf
				    }, {
				        label: App.i18n.prop('gap'),
						class: 'gap',
				        value: this.results.retirement.gap
				    } ];
					main_label = App.i18n.prop('required_fund');
					main_value = this.results.retirement.required_fund;
					
					Tracking.trackPageview('FNA-'+ App.language +'/Page-Result-Retirement');
					break;
					
				case 'education':
					var children = this.results.education.child_results;
					
					main_label = App.i18n.prop("required_education_fund");
					main_value = this.results.education.total_required_fund;
					
					
					var childrenTempData = [];
					var total_gap = 0;
					if(children[0]){
						childrenTempData.push({
				            // label: "Child #1",
							label: App.i18n.prop("child_with_age", {'%s1':this.results.education.child_results[0].children_age}),
							class: "child1_gap",
				            currency : "",
				            value: children[0].gap,
				            label_rect: 0
					    });
					    total_gap += children[0].gap;
					}
					if(children[1]){
						childrenTempData.push({
				            label: App.i18n.prop("child_with_age", {'%s1':this.results.education.child_results[1].children_age}),
							class: "child2_gap",
				            currency : "",
				            value: children[1].gap,
				            label_rect: 0
					    });
					    total_gap += children[1].gap;
					}
					if(children[2]){
						childrenTempData.push({
				            label: App.i18n.prop("child_with_age", {'%s1':this.results.education.child_results[2].children_age}),
							class: "child3_gap",
				            currency : "",
				            value: children[2].gap,
				            label_rect: 0
					    });
					    total_gap += children[2].gap;
					}
					education_chart_data = {
							currency: currency,
						    label: App.i18n.prop("required_education_fund"),
						    value: main_value,
						    chart_data: [{
						        label: App.i18n.prop("current_education_fund"),
								class: 'current_education',
						        value: this.results.education.total_education_fund
						    },{
						        label: App.i18n.prop("total_gap"),
								class: 'total_gap',
						        value: total_gap
						    }],
						    el: "#result-chart",
						};
					
					Tracking.trackPageview('FNA-'+ App.language +'/Page-Result-Education');
					break;
					
				default:
					console.log('No section found:', section);
					break;
			}
		    
			// Normal charts
			if (chart_data) {
				var data = {
						"currency": currency,
						"label": main_label,
						"value": main_value,
						"chart_data": chart_data,
						"el": "#result-chart"
				}; 				
				App.View.Chart.createChart(data);
			}
			
			// Education chart
			if (education_chart_data) {
				App.View.Chart.createChart(education_chart_data);
			}

			var scroller = new IScroll('#result-fields');
			
			// State chart is creating/finished
			// if creating, disable left panel menu click function
			App.View.Chart.createStatus = 'creating';
			
		},
			
		/**
		 * Submit field to Cal.getResult to get result
		 */
		getResult: function(sections) {
								
			// phase fields data
			var data = {
				/* information */
				gender : sections.getValue('information', 'gender'),
				age : Number(sections.getValue('information', 'age')),
				marital_status : sections.getValue('information', 'marital_status'),
				num_of_children : Number(sections.getValue('information', 'num_of_children')),
				num_of_dependents : Number(sections.getValue('information', 'num_of_dependent')),
				
				/* finance */
				monthly_income : Number(sections.getValue('finance', 'monthly_income')),
				liquid_assets : {
					cash_deposit : Number(sections.getValue('finance', 'cash_deposit')),
					time_deposit : Number(sections.getValue('finance', 'time_deposit')),
					stock : Number(sections.getValue('finance', 'stock')),
					fund_bond : Number(sections.getValue('finance', 'fund_bond')),
					others : Number(sections.getValue('finance', 'others'))
				},
				annual_return_rate : Number(sections.getValue('finance', 'annual_return_rate')) / 100,
				annual_inflation_rate : Number(sections.getValue('finance', 'annual_inflation_rate')) / 100,
				
				/* protection */
				total_coverage_of_life_policies : Number(sections.getValue('protection', 'life_policies')),
				num_of_years_for_supporting : Number(sections.getValue('protection', 'years_for_supporting')),
				total_coverage_of_critical_illness_policies : Number(sections.getValue('protection', 'critical_illness_policie')),
				expected_years_of_loss_of_income : Number(sections.getValue('protection', 'expected_years_of_loss_of_income')),
				monthly_house_rental : Number(sections.getValue('protection', 'monthly_house_rental')),
				other_monthly_expenses : Number(sections.getValue('protection', 'other_monthly_expenses')),
				immediate_cash_needs : {
					mortgage : Number(sections.getValue('protection', 'mortgage')),
					education_funds : Number(sections.getValue('protection', 'education_funds')),
					funeral_expense : Number(sections.getValue('protection', 'funeral_expenses')),
					others : Number(sections.getValue('protection', 'others'))
				},
				
				/* retirement */
				target_retirement_age : Number(sections.getValue('retirement', 'target_retirement_age')),
				//ideal_retirement_lifestyle : sections.getValue('retirement', 'ideal_retirement_lifestyle') ? sections.getValue('retirement', 'ideal_retirement_lifestyle') : '',
				expected_retirement_expenses : Number(sections.getValue('retirement', 'expected_retirement_expenses')),
				expect_years_of_retirement : Number(sections.getValue('retirement', 'expect_years_of_retirement')),
				mpf_monthly_contribution : Number(sections.getValue('retirement', 'mpf_monthly_contribution')),
			};
			
			/* education */
			var num_of_children = sections.getValue('information', 'num_of_children');
			if (num_of_children > 0) {
				var children = [];
				for (var i=1; i<=num_of_children; i++) {
					children.push({
						children_age: Number(sections.getValue('education', 'child'+i+'_age')),
						age_to_enter_university: Number(sections.getValue('education', 'child'+i+'_age_to_enter_university')),
						expected_years_of_studying: Number(sections.getValue('education', 'child'+i+'_expected_years_of_studying')),
						country_for_studying: sections.getValue('education', 'child'+i+'_country_of_studying') ? sections.getValue('education', 'child'+i+'_country_of_studying') : '',
						manual_total_expense_per_year: sections.getValue('education', 'child'+i+'_manual_total_expense') || 0
					});
				}
				data.children = children;
				data.education_fund = sections.getValue('education', 'education_fund') || 0;
			}
			
			
			// get result from Cal.js
			console.log("Cal.getResult() Input", data);
			this.inputData = data;
			this.results = Cal.getResults(data);
			console.log("Cal.getResult() Output", this.results);
			
			// switch result / input views
			$('#input').hide();
			$('#result').show();
									
			// render result
			var $fields = $('#result-fields > .scroller');
			$fields.empty();
			
			function appendSection(section, fields) {
				$fields.append(_.template(App.Template.result_panel_section, section));
				var $el = $('>:last-child', $fields);
				if (section.id === 'suggestions') {
					_.each(fields, function(field){
						$el.append(_.template(App.Template.result_panel_suggestion, field));
					}, this);
				} else {
					var count_child = 1;
					_.each(fields, function(field){
						field.css = field.css ? field.css : '';
						field.unit = field.unit ? field.unit : 'hkd';
						field.options = field.options ? field.options : '';
						if (field.value != null) {
							field.value = App.i18n.prop(field.unit) + DQ.addCommas(field.value);
							if (section.id == 'education' && field.key == 'gap') {
								field.key = 'child' + (count_child++) + '_' + field.key;
							}
							$el.append(_.template(App.Template.result_panel_field, field));
						}
					}, this);
					$el.append(_.template(App.Template.result_panel_field_margin));
				}
			}
			var tempData = [];
			
			if (this.results.total_need != undefined) {
				tempData.push({
					'key':'total_financial_need',
					'value': this.results.total_need
				});
			}
			if (this.results.total_gap != undefined) {
				tempData.push({
					'key':'gap',
					'value': this.results.total_gap,
					css: 'indent'
				});
			}
			if (this.results.life_protection && this.results.life_protection.liquid_assets != undefined) {
				tempData.push({
					'key':'liquid_assets',
					'value': this.results.life_protection.liquid_assets,
					'css':'indent'
				});
			}
			if (this.results.life_protection && this.results.life_protection.current_life_protection != undefined) {
				tempData.push({
					'key':'current_life_protection',
					'value': this.results.life_protection.current_life_protection,
					'css':'indent'
				});
			}
			if (this.results.critical_illness_protection && this.results.critical_illness_protection.current_ci_protection != undefined) {
				tempData.push({
					'key':'current_critical_illness_protection',
					'value': this.results.critical_illness_protection.current_ci_protection,
					'css':'indent'
				});
			}
			if (this.results.retirement && this.results.retirement.mpf != undefined) {
				tempData.push({
					'key':'mpf',
					'value': this.results.retirement.mpf,
					'css':'indent'
				});
			}
			if (this.results.education && this.results.education.total_education_fund != undefined) {
				tempData.push({
					'key': 'education_fund',
					'value': this.results.education.total_education_fund,
					'css': 'indent'
				});
			}
			
			// tempData = 
			// 		[ {
			// 			'key':'total_financial_need',
			// 			'value': this.results.total_need
			// 		}, {
			// 			"key" : "protection_gap",
			// 			'value': this.results.total_gap,
			// 			'css':'indent'
			// 		}, {
			// 			'key':'liquid_assets',
			// 			'value': this.results.life_protection.liquid_assets,
			// 			'css':'indent'
			// 		}, {
			// 			"key" : "current_life_protection",
			// 			'value': this.results.life_protection.current_life_protection,
			// 			'css':'indent'
			// 		}, {
			// 			"key" : "current_critical_illness_protection",
			// 			'value': this.results.critical_illness_protection.current_ci_protection,
			// 			'css':'indent'
			// 		}, {
			// 			"key" : "mpf",
			// 			'value': this.results.retirement.mpf,
			// 			'css':'indent'
			// 		} ];
					
			appendSection({ id:'overview' }, tempData);
			
			appendSection({ id:'life_protection' }, 
				[
					{
						'key':'life_protection_need',
						'value': this.results.life_protection.life_protection_need
					},
					{
						'key':'liquid_assets',
						'value': this.results.life_protection.liquid_assets,
						'css':'indent'
					},
					{
						"key" : "current_life_protection",
						'value': this.results.life_protection.current_life_protection,
						'css':'indent'
					},
					{
						"key" : "protection_gap",
						'value': this.results.life_protection.protection_gap,
						'css':'indent'
					}
				]
			);
			
			appendSection({ id:'critical_illness_protection' }, 
					[ {
						'key':'ci_protection_need',
						'value': this.results.critical_illness_protection.ci_protection_need
					},{
						'key':'current_ci_protection',
						'value': this.results.critical_illness_protection.current_ci_protection,
						'css':'indent'
					}, {
						"key" : "protection_gap",
						'value': this.results.critical_illness_protection.protection_gap,
						'css':'indent'
					} ] );
			
			if (this.results.retirement) {
				appendSection({ id:'retirement' }, 
						[ {
							'key':'required_fund',
							'value': this.results.retirement.required_fund
						},{
							'key':'mpf',
							'value': this.results.retirement.mpf,
							'css':'indent'
						}, {
							"key" : "gap",
							'value': this.results.retirement.gap,
							'css':'indent'
						}, {
							"key" : "required_monthly_saving",
							'value': this.results.retirement.required_monthly_saving,
							'css':'indent'
						} ] );
				$('nav.result-menu .retirement').show();
			} else {
				$('nav.result-menu .retirement').hide();
			}
			
			if (this.results.education) {
				tempData = [];
				tempData = 
					[ {
						'key':'required_education_fund',
						'value': this.results.education.total_required_fund
					}, {
						'key':'current_education',
						'value': this.results.education.total_education_fund
					}, {
						'key':'total_gap',
						'value': this.results.education.total_gap
					} ];
					
				if(this.results.education.child_results[0]){
					tempData.push({
				        key: 'child_with_age',
				        value: '',
						unit: 'unit_empty',
						options: {
							'%s1':this.results.education.child_results[0].children_age
						}
				    });
					tempData.push({
				        key: 'required_education_fund',
				        value: this.results.education.child_results[0].required_fund,
						css: 'indent'
				    });
					tempData.push({
				        key: 'current_education_fund',
				        value: this.results.education.child_results[0].education_fund,
						css: 'indent'
				    });
					tempData.push({
				        key: 'gap',
				        value: this.results.education.child_results[0].gap,
						css: 'indent'
				    });
					tempData.push({
				        key: 'required_monthly_saving',
				        value: this.results.education.child_results[0].required_monthly_saving,
						css: 'indent'
				    });
					tempData.push({
				        key: 'year_of_saving',
				        value: this.results.education.child_results[0].year_of_saving,
						css: 'indent',
						unit: 'unit_empty'
				    });
				}
				if(this.results.education.child_results[1]){
					tempData.push({
				        key: 'child_with_age',
				        value: '',
						unit: 'unit_empty',
						options: {
							'%s1':this.results.education.child_results[1].children_age
						}
				    });
					tempData.push({
				        key: 'required_education_fund',
				        value: this.results.education.child_results[1].required_fund,
						css: 'indent'
				    });
					tempData.push({
				        key: 'current_education_fund',
				        value: this.results.education.child_results[1].education_fund,
						css: 'indent'
				    });
					tempData.push({
				        key: 'gap',
				        value: this.results.education.child_results[1].gap,
						css: 'indent'
				    });
					tempData.push({
				        key: 'required_monthly_saving',
				        value: this.results.education.child_results[1].required_monthly_saving,
						css: 'indent'
				    });
					tempData.push({
				        key: 'year_of_saving',
				        value: this.results.education.child_results[1].year_of_saving,
						css: 'indent',
						unit: 'unit_empty'
				    });
				}
				if(this.results.education.child_results[2]){
					tempData.push({
				        key: 'child_with_age',
				        value: '',
						unit: 'unit_empty',
						options: {
							'%s1':this.results.education.child_results[2].children_age
						}
				    });
					tempData.push({
				        key: 'required_education_fund',
				        value: this.results.education.child_results[2].required_fund,
						css: 'indent'
				    });
					tempData.push({
				        key: 'current_education_fund',
				        value: this.results.education.child_results[2].education_fund,
						css: 'indent'
				    });
					tempData.push({
				        key: 'gap',
				        value: this.results.education.child_results[2].gap,
						css: 'indent'
				    });
					tempData.push({
				        key: 'required_monthly_saving',
				        value: this.results.education.child_results[2].required_monthly_saving,
						css: 'indent'
				    });
					tempData.push({
				        key: 'year_of_saving',
				        value: this.results.education.child_results[2].year_of_saving,
						css: 'indent',
						unit: 'unit_empty'
				    });
				}
				appendSection({ id:'education' }, tempData);
				$('nav.result-menu .education').show();
			} else {
				$('nav.result-menu .education').hide();
			}
			
			if (this.results.products.length > 0) {
				appendSection({ id:'suggestions' }, this.results.products, true );
				$('nav.result-menu .suggestions').show();
			} else {
				$('nav.result-menu .suggestions').hide();
			}
			
			// default show overview after render
			$('#result-fields .life_protection').removeClass('inactive');
			
			e = {target: 'life_protection', currentTarget: 'life_protection'};
			App.loadSectionPanel(e);
			
			
			
			// Click/touech events
			$('.suggestions .basic a').on('touchend click', function(e) {
				var link = $(e.currentTarget).attr('href');
				if (link) {
					console.log("link:"+link);
					$.get('/app/Policy/open_url?url='+this.href);					
					e.preventDefault();
				}
			});
			
			$('#result-fields li').on('touchend click', function(){
				var target_class = $(this).attr("data-fid");
				if(target_class){
					if ($(".highlight-"+target_class).length)
					{
						if (!$("path.highlight-"+target_class).attr("data-default-fill")) {
							$("path.highlight-"+target_class).attr("data-default-fill",$("path.highlight-"+target_class).attr("fill"));
						}
						var current_fill = $("path.highlight-"+target_class).attr("fill");
						$("[class^=highlight-]" ).hide();
						
						$(".highlight-"+target_class).show();
						$.each($("path[class^=highlight-]"),function(){
							var current_fill = $(this).attr("fill");
							var click_fill = false;
							//
							if (current_fill == "#F3705D") {
								click_fill = "#ED1B2F";
							}
							//
							if (current_fill == "#FECA66") {
								click_fill = "#FDB713";
							}
							//
							if (current_fill == "#F59B40") {
								click_fill = "#F68B1F";
							}
							//
							if (current_fill == "#86999C") {
								click_fill = "#73868A";
							}
							//
							if (current_fill == "#003F43") {
								click_fill = "#002123";
							}
							//
							if (current_fill == "#315F66") {
								click_fill = "#25484D";
							}
							if (click_fill) {
								$(this).attr("fill",click_fill);
								$(".highlight-"+target_class).hide();
							}
						});
						var click_fill = false;
						if (current_fill == "#ED1B2F") {
							click_fill = "#F3705D";
						}
						//
						if (current_fill == "#FDB713") {
							click_fill = "#FECA66";
						}
						//
						if (current_fill == "#F68B1F") {
							click_fill = "#F59B40";
						}
						//
						if (current_fill == "#73868A") {
							click_fill = "#86999C";
						}
						//
						if (current_fill == "#002123") {
							click_fill = "#003F43";
						}
						//
						if (current_fill == "#25484D") {
							click_fill = "#315F66";
						}
						if (click_fill) {
							$("path.highlight-"+target_class).attr("fill",click_fill);
							$(".highlight-"+target_class).show();
						}
						$("path[class^=highlight-]").show();
					}
				}
			});
		}
	
	
	
};