console.log('cal.js');

var Cal = {
	Model: {},
	Collection: {}
};

_.extend(Cal, Backbone.Events);

/* Define Models and Collections */
Cal.Model.CalConfig = Backbone.Model.extend({
	defaults: {
		key		: null,
		data	: null
	}
});
Cal.Collection.CalConfigs = Backbone.Collection.extend({
	model: Cal.Model.CalConfig/*,
	url: './static/data/calconfig.json',
	initialize: function(){
		this.fetch({
			success: function(model, response, options){
				//console.log(response);
			},
			error: function(model, response, options){
				console.log(response);
			}
		});
	}*/
});
Cal.Model.AppSetting = Backbone.Model.extend({
	defaults: {
		language			: 'en',
		country_code		: 'hk',
		channel				: '',
		advisor_name_en		: '',
		advisor_name_zh		: '',
		show_recommendation	: 'false',
		customer_name		: '',
		customer_email		: ''
	}
});
Cal.Model.DemographicInfo = Backbone.Model.extend({
	defaults: {
		gender				: null,
		age					: null,
		marital_status		: null,
		num_of_children		: -1,
		num_of_dependents	: -1
	}
});
Cal.Model.AssetsInfo = Backbone.Model.extend({
	defaults: {
		monthly_income			: -1,
		liquid_assets			: {
			cash_deposit	: -1,
			time_deposit	: -1,
			stock			: -1,
			fund_bond		: -1,
			others			: -1
		},
		annual_return_rate		: -1,
		annual_inflation_rate	: -1,
		total_liquid_assets		: -1
	}
});
Cal.Model.ProtectionInfo = Backbone.Model.extend({
	defaults: {
		total_coverage_of_life_policies				: -1,
		num_of_years_for_supporting					: -1,
		total_coverage_of_critical_illness_policies	: -1,
		expected_years_of_loss_of_income			: -1,
		monthly_house_rental						: -1,
		other_monthly_expenses						: -1,
		total_cash_need								: -1,
		immediate_cash_needs						: {
			mortgage		: -1,
			education_funds	: -1,
			funeral_expense	: -1,
			others			: -1
		},
		monthly_expense								: -1,
		months_exp									: -1
	}
});
Cal.Model.RetirementInfo = Backbone.Model.extend({
	defaults: {
		target_retirement_age		: -1,
		ideal_retirement_lifestyle	: 'undefined',
		expected_retirement_expenses: -1,
		expect_years_of_retirement	: -1,
		mpf_monthly_contribution	: -1
	}
});
Cal.Model.EducationInfo = Backbone.Model.extend({
	defaults: {
		child_infos		: null,
		education_fund 	: -1
	}
});
Cal.Model.ChildInfo = Backbone.Model.extend({
	defaults: {
		children_age					: null,
		age_to_enter_university			: null,
		expected_years_of_studying		: null,
		country_for_studying			: null,
		manual_total_expense_per_year	: null
	}
});
Cal.Collection.ChildInfos = Backbone.Collection.extend({
	model: Cal.Model.ChildInfo
});
Cal.Model.ProtectionResult = Backbone.Model.extend({
	defaults: {
		total_need							: -1,
		total_gap							: -1,
		life_protection_result				: null,
		critical_illness_protection_result	: null,
		retirement_result					: null,
		education_result					: null
	}
});
Cal.Model.LifeProtectionResult = Backbone.Model.extend({
	defaults: {
		life_protection_need	: -1,
		liquid_assets 			: -1,
		current_life_protection	: -1,
		protection_gap 			: -1
	}
});
Cal.Model.CriticalIllnessProtectionResult = Backbone.Model.extend({
	defaults: {
		critical_illness_protection_need	: -1,
		current_critical_illness_protection	: -1,
		protection_gap						: -1,
		ci_protection_need					: -1,
		current_ci_protection				: -1
	}
});
Cal.Model.RetirementResult = Backbone.Model.extend({
	defaults: {
		required_fund			: -1,
		mpf						: -1,
		gap						: -1,
		required_monthly_saving	: 0,
		total_monthly_spending	: -1
	}
});
Cal.Model.EducationResult = Backbone.Model.extend({
	defaults: {
		child_results		: null,
		total_required_fund	: -1
	}
});
Cal.Model.ChildResult = Backbone.Model.extend({
	defaults: {
		required_fund			: -1,
		education_fund			: -1,
		gap						: -1,
		required_monthly_saving	: 0,
		year_of_saving			: -1,
		expected_years_of_studying : -1
	}
});
Cal.Collection.ChildResults = Backbone.Collection.extend({
	model: Cal.Model.ChildResult
});
Cal.Model.Logo = Backbone.Model.extend({
	defaults: {
		market_type					: 'undefined',
		distribution_channel_type	: 'undefined',
		distribution_channel_id		: 'undefined',
		distribution_channel_name	: 'undefined',
		fwd_logo_filename			: 'undefined',
		partner_logo_filename		: 'undefined'
	}
});
Cal.Collection.Logos = Backbone.Collection.extend({
	model: Cal.Model.Logo
});
Cal.Model.Product = Backbone.Model.extend({
	defaults: {
		market_type					: 'undefined',
		distribution_channel_type	: 'undefined',
		distribution_channel_id		: 'undefined',
		distribution_channel_name	: 'undefined',
		product_category_id			: 'undefined',
		product_category_en			: 'undefined',
		product_cateogry_zh			: 'undefined',
		product_id					: 'undefined',
		product_name_en				: 'undefined',
		product_name_zh				: 'undefined',
		product_link_en				: 'undefined',
		product_link_zh				: 'undefined'
	}
});
Cal.Collection.Products = Backbone.Collection.extend({
	model: Cal.Model.Product
});
Cal.Model.AssumptionNote = Backbone.Model.extend({
	defaults: {
		section		: 'undefined',
		info_url_en	: 'undefined',
		info_url_zh	: 'undefined'
	}
});
Cal.Collection.AssumptionNotes = Backbone.Collection.extend({
	model: Cal.Model.AssumptionNote
});

Cal.appInit = function() {
	var model, language, countryCode;

	/* Private Functions */
	var getURLParameter = function(sParam) {
		var sPageURL = window.location.search.substring(1),
			sURLVariables = sPageURL.split('&'),
			i, sParameterName;
		for (i = 0; i < sURLVariables.length; i++) {
			sParameterName = sURLVariables[i].split('=');
			if (sParameterName[0] == sParam) {
				console.log(sParameterName[0]+":"+sParameterName[1]);
				return sParameterName[1];
			}
		}
	}

	/* Initialize Instances */
	// Get data from calconfig.json
	/*Cal.Collection.calConfigs = new Cal.Collection.CalConfigs().once('sync', function(){
		Cal.trigger("ready");
	}, this);*/
	model = Cal.Collection.calConfigs = new Cal.Collection.CalConfigs();
	_.each(Data.calConfigs, function(item){
		model.push(new Cal.Model.CalConfig(item));
	}, this);
	model = Cal.Collection.logos = new Cal.Collection.Logos();
	_.each(Data.logos, function(item){
		model.push(new Cal.Model.Logo(item));
	}, this);
	model = Cal.Collection.products = new Cal.Collection.Products();
	_.each(Data.products, function(item){
		model.push(new Cal.Model.Product(item));
	}, this);
	model = Cal.Collection.assumptionNotes = new Cal.Collection.AssumptionNotes();
	_.each(Data.assumptionNotes, function(item){
		model.push(new Cal.Model.AssumptionNote(item));
	}, this);

	// Get data from query string
	language = getURLParameter('language');
	countryCode = getURLParameter('country-code');
	Cal.appSetting = new Cal.Model.AppSetting({
		language			: language ? language : 'en',
		country_code		: countryCode? countryCode : 'hk',
		channel				: getURLParameter('channel'),
		advisor_name_en		: getURLParameter('advisor-name-en'),
		advisor_name_zh		: getURLParameter('advisor-name-zh'),
		show_recommendation	: getURLParameter('show-recommendation')
	});
	Cal.demographicInfo	= new Cal.Model.DemographicInfo;
	Cal.assetsInfo = new Cal.Model.AssetsInfo;
	Cal.protectionInfo = new Cal.Model.ProtectionInfo;
	Cal.retirementInfo = new Cal.Model.RetirementInfo;
	Cal.educationInfo = new Cal.Model.EducationInfo;
	Cal.Collection.childInfos = new Cal.Collection.ChildInfos;
	Cal.protectionResult = new Cal.Model.ProtectionResult;
	Cal.lifeProtectionResult = new Cal.Model.LifeProtectionResult;
	Cal.criticalIllnessProtectionResult = new Cal.Model.CriticalIllnessProtectionResult;
	Cal.retirementResult = new Cal.Model.RetirementResult;
	Cal.educationResult = new Cal.Model.EducationResult;
	Cal.Collection.childResults = new Cal.Collection.ChildResults;

	/* Assets Info */
	// Functions
	Cal.assetsInfo.calculateTotalLiquidAssets = function(liquid_assets) {
		var temp = _.reduce(_.values(liquid_assets), function(memo, num){ return memo+num; }, 0);
		return temp
	};
	Cal.assetsInfo.calculateK = function(annual_inflation_rate, annual_return_rate) {
		return (1+annual_inflation_rate/12)/(1+annual_return_rate/12);
	};
	Cal.assetsInfo.calculateKAnnual = function(annual_inflation_rate, annual_return_rate) {
		return (1+annual_inflation_rate)/(1+annual_return_rate);
	};
	// Event Listeners
	Cal.assetsInfo.on({
		'change:liquid_assets': function(){
			var liquid_assets = this.get('liquid_assets');
			this.set({
				'total_liquid_assets': this.calculateTotalLiquidAssets(liquid_assets)
			});
		},
		'change:annual_return_rate change:annual_inflation_rate': function(){
			var annual_inflation_rate = this.get('annual_inflation_rate'),
				annual_return_rate = this.get('annual_return_rate');
			this.set({
				'k': this.calculateK(annual_inflation_rate, annual_return_rate),
				'k_annual': this.calculateKAnnual(annual_inflation_rate, annual_return_rate)
			})
		}
	});

	/* Protection Info */
	// Functions
	Cal.protectionInfo.calculateTotalCashNeed = function(immediate_cash_needs) {
		return _.reduce(_.values(immediate_cash_needs), function(memo, num){ return memo+num; }, 0);
	};
	Cal.protectionInfo.calculateMonthlyExp = function(monthly_house_rental, other_monthly_expenses) {
		return monthly_house_rental+other_monthly_expenses;
	};
	// Event Listeners
	Cal.protectionInfo.on({
		'change:immediate_cash_needs': function(){
			var immediate_cash_needs = this.get('immediate_cash_needs');
			this.set({
				'total_cash_need': this.calculateTotalCashNeed(immediate_cash_needs)
			});
		},
		'change:monthly_house_rental change:other_monthly_expenses': function(){
			var monthly_house_rental = this.get('monthly_house_rental'),
				other_monthly_expenses = this.get('other_monthly_expenses');
			this.set({
				'months_exp': this.calculateMonthlyExp(monthly_house_rental, other_monthly_expenses)
			});
		}
	});

	/* Life Protection Results */
	// Functions
	Cal.lifeProtectionResult.calculateLifeProtectionNeed = function(k, months_exp, exp_yrs, total_cash_need) {
		return (k==1?months_exp*exp_yrs*12+total_cash_need:months_exp*(Math.pow(k,exp_yrs*12)-1)/(k-1)+total_cash_need);
	};
	Cal.lifeProtectionResult.setLifeProtectionNeed = function() {
		var k = Cal.assetsInfo.get('k'),
			months_exp = Cal.protectionInfo.get('months_exp'),
			exp_yrs = Cal.protectionInfo.get('num_of_years_for_supporting'),
			total_cash_need = Cal.protectionInfo.get('total_cash_need');
		this.set({
			'life_protection_need': this.calculateLifeProtectionNeed(k, months_exp, exp_yrs, total_cash_need)
		});
	};
	Cal.lifeProtectionResult.calculateProtectionGap = function(life_protection_need, liquid_assets, current_life_protection) {
		var gap = life_protection_need-liquid_assets-current_life_protection;
		return gap>0?gap:0;
	};
	// Event Listeners
	Cal.lifeProtectionResult.listenTo(Cal.assetsInfo, 'change:k', function(){
		this.setLifeProtectionNeed();
	}).listenTo(Cal.protectionInfo, 'change:months_exp change:num_of_years_for_supporting change:total_cash_need', function(){
		this.setLifeProtectionNeed();
	}).listenTo(Cal.assetsInfo, 'change:total_liquid_assets', function(){
		this.set({
			'liquid_assets': Cal.assetsInfo.get('total_liquid_assets')
		});
	}).listenTo(Cal.protectionInfo, 'change:total_coverage_of_life_policies', function(){
		this.set({
			'current_life_protection': Cal.protectionInfo.get('total_coverage_of_life_policies')
		});
	}).on({
		'change:life_protection_need change:liquid_assets change:current_life_protection': function(){
			var life_protection_need = this.get('life_protection_need'),
				liquid_assets = this.get('liquid_assets'),
				current_life_protection = this.get('current_life_protection');
			this.set({
				'protection_gap': this.calculateProtectionGap(life_protection_need, liquid_assets, current_life_protection)
			})
		}
	});

	/* Critical Illness Protection Results */
	// Functions
	Cal.criticalIllnessProtectionResult.calculateIncomeReplacement = function(monthly_income, expected_years_of_loss_of_income) {
		return monthly_income*expected_years_of_loss_of_income*12;
	};
	Cal.criticalIllnessProtectionResult.setIncomeReplacement = function() {
		var monthly_income = Cal.assetsInfo.get('monthly_income'),
			expected_years_of_loss_of_income = Cal.protectionInfo.get('expected_years_of_loss_of_income');
		this.set({
			'income_replacement': this.calculateIncomeReplacement(monthly_income, expected_years_of_loss_of_income)
		});
	};
	Cal.criticalIllnessProtectionResult.calculateCIProtectionNeed = function(income_replacement, medical_expense, ltc) {
		return income_replacement+medical_expense+ltc;
	};
	Cal.criticalIllnessProtectionResult.calculateProtectionGap = function(ci_protection_need, current_ci_protection) {
		var gap = ci_protection_need-current_ci_protection;
		return gap>0?gap:0;
	};
	// Event Listeners
	Cal.criticalIllnessProtectionResult.listenTo(Cal.assetsInfo, 'change:monthly_income', function(){
		this.setIncomeReplacement();
	}).listenTo(Cal.protectionInfo, 'change:expected_years_of_loss_of_income', function(){
		this.setIncomeReplacement();
	}).listenTo(Cal.protectionInfo, 'change:total_coverage_of_critical_illness_policies', function(){
		this.set({
			'current_ci_protection': Cal.protectionInfo.get('total_coverage_of_critical_illness_policies')
		});
	}).on({
		'change:income_replacement change:medical_expense change:ltc': function(){
			var income_replacement = this.get('income_replacement'),
				protection_expenses = Cal.Collection.calConfigs.findWhere({key: 'protection_expenses'}).get('data');
				medical_expense = protection_expenses['medical_expense'],
				ltc = protection_expenses['long_term_care_expense'];
			this.set({
				'ci_protection_need': this.calculateCIProtectionNeed(income_replacement, medical_expense, ltc)
			});
		},
		'change:ci_protection_need change:current_ci_protection': function(){
			var ci_protection_need = this.get('ci_protection_need'),
				current_ci_protection = this.get('current_ci_protection');
			this.set({
				'protection_gap': this.calculateProtectionGap(ci_protection_need, current_ci_protection)
			});
		}
	});

	/* Retirement */
	// Functions
	Cal.retirementResult.calculateTotalMonthlySpending = function(detailed_expenses) {
		return _.reduce(_.values(detailed_expenses), function(memo, num){ return memo+num; }, 0);
	};
	Cal.retirementResult.calculateK = function(annual_inflation_rate, annual_return_rate) {
		return Math.pow((1+annual_inflation_rate)/(1+annual_return_rate),1/12);
	};
	Cal.retirementResult.calculateFVAnnuity = function(k, yr_retire) {
		return k==1?yr_retire*12:k*(Math.pow(k,yr_retire*12)-1)/(k-1);
	};
	Cal.retirementResult.setFVAnnuity = function() {
		var k = this.get('k'),
			yr_retire = Cal.retirementInfo.get('expect_years_of_retirement');
		this.set({
			'fv_annuity': this.calculateFVAnnuity(k, yr_retire)
		})
	};
	Cal.retirementResult.calculateRequiredFund = function(total_monthly_spending, inf, tar_age, age, fv_annuity) {
		return total_monthly_spending*Math.pow(1+inf,tar_age-age)*fv_annuity;
	};
	Cal.retirementResult.setRequiredFund = function() {
		var total_monthly_spending = this.get('total_monthly_spending'),
			inf = Cal.assetsInfo.get('annual_inflation_rate'),
			tar_age = Cal.retirementInfo.get('target_retirement_age'),
			age = Cal.demographicInfo.get('age'),
			fv_annuity = this.get('fv_annuity');
		this.set({
			'required_fund': this.calculateRequiredFund(total_monthly_spending, inf, tar_age, age, fv_annuity)
		});
	};
	Cal.retirementResult.calculateDiscountFactor = function(annual_return_rate, tar_age, age) {
		return annual_return_rate==0?12*(tar_age-age):(Math.pow(1+annual_return_rate/12,12*(tar_age-age))-1)/(annual_return_rate/12)
	};
	Cal.retirementResult.setDiscountFactor = function() {
		var annual_return_rate = Cal.assetsInfo.get('annual_return_rate'),
			tar_age = Cal.retirementInfo.get('target_retirement_age'),
			age = Cal.demographicInfo.get('age');
		this.set({
			'discount_factor': this.calculateDiscountFactor(annual_return_rate, tar_age, age)
		});
	};
	Cal.retirementResult.calculateMPF = function(mpf_monthly_contribution, discount_factor) {
		return mpf_monthly_contribution*discount_factor;
	};
	Cal.retirementResult.setMPF = function() {
		var mpf_monthly_contribution = Cal.retirementInfo.get('mpf_monthly_contribution'),
			discount_factor = this.get('discount_factor');
		this.set({
			'mpf': this.calculateMPF(mpf_monthly_contribution, discount_factor)
		});
	};
	Cal.retirementResult.calculateGap = function(required_fund, mpf) {
		var gap = required_fund-mpf;
		return gap>0?gap:0;
	};
	Cal.retirementResult.calculateMonthlySaving = function(gap, discount_factor) {
		return gap/discount_factor;
	};
	Cal.retirementResult.calculateRequiredMonthlySaving = function(monthly_saving) {
		return Math.max(monthly_saving, 0);
	};
	// Event Listeners
	Cal.retirementResult.listenTo(Cal.retirementInfo, 'change:ideal_retirement_lifestyle', function(){
		var ideal_retirement_lifestyle = Cal.retirementInfo.get('ideal_retirement_lifestyle'),
			total_monthly_spending = Cal.Collection.calConfigs.findWhere({key: 'retirement_expenses'}).get('data')[ideal_retirement_lifestyle];
		Cal.retirementResult.set({
			'total_monthly_spending': total_monthly_spending
		});
	}).listenTo(Cal.assetsInfo, 'change:annual_return_rate change:annual_inflation_rate', function(){
		var annual_inflation_rate = Cal.assetsInfo.get('annual_inflation_rate'),
			annual_return_rate = Cal.assetsInfo.get('annual_return_rate');
		this.set({
			'k': this.calculateK(annual_inflation_rate, annual_return_rate)
		});
	}).listenTo(Cal.retirementInfo, 'change:expected_retirement_expenses', function(){
		var total_monthly_spending = Cal.retirementInfo.get('expected_retirement_expenses')
		Cal.retirementResult.set({
			'total_monthly_spending': total_monthly_spending
		});
	}).listenTo(Cal.retirementInfo, 'change:expect_years_of_retirement', function(){
		this.setFVAnnuity();
	}).listenTo(Cal.assetsInfo, 'change:annual_inflation_rate', function(){
		this.setRequiredFund();
	}).listenTo(Cal.retirementInfo, 'change:target_retirement_age', function(){
		this.setRequiredFund();
		this.setDiscountFactor();
	}).listenTo(Cal.demographicInfo, 'change:age', function(){
		this.setRequiredFund();
		this.setDiscountFactor();
	}).on('change:total_monthly_spending change:fv_annuity', function(){
		this.setRequiredFund();
	}).listenTo(Cal.assetsInfo, 'change:annual_return_rate', function(){
		this.setDiscountFactor();
	}).listenTo(Cal.retirementInfo, 'change:mpf_monthly_contribution', function(){
		this.setMPF();
	}).on({
		'change:k': function(){
			this.setFVAnnuity();
		},
		'change:discount_factor': function(){
			this.setMPF();
		},
		'change:required_fund change:mpf': function(){
			var required_fund = this.get('required_fund'),
				mpf = this.get('mpf');
			this.set({
				'gap': this.calculateGap(required_fund, mpf)
			})
		},
		'change:gap change:discount_factor': function(){
			var gap = this.get('gap'),
				discount_factor = this.get('discount_factor');
			this.set({
				'monthly_saving': this.calculateMonthlySaving(gap, discount_factor)
			});
		},
		'change:monthly_saving': function(){
			var monthly_saving = this.get('monthly_saving');
			this.set({
				'required_monthly_saving': this.calculateRequiredMonthlySaving(monthly_saving)
			});
		}
	});

	/* Education */
	// Functions
	Cal.educationResult.calculateTotalExpensesPerYear = function(manual_total_expense_per_year, living_expense_per_year, education_expense_per_year, annual_inflation_rate, age_to_enter_university, current_age) {
		return manual_total_expense_per_year==0?(living_expense_per_year+education_expense_per_year)*Math.pow(1+annual_inflation_rate,age_to_enter_university-current_age):manual_total_expense_per_year*Math.pow(1+annual_inflation_rate,age_to_enter_university-current_age);
	};
	Cal.educationResult.calculateExpectedEducationSavings = function(annual_return_rate, annual_inflation_rate, expected_years_of_studying, total_expenses_per_year, k_annual) {
		return 1+annual_return_rate==1+annual_inflation_rate?expected_years_of_studying*total_expenses_per_year:total_expenses_per_year*k_annual*((Math.pow(k_annual,expected_years_of_studying)-1)/(k_annual-1))
	};
    
    
	Cal.calculateTotalExpensesPerYear = function (country_for_studying, annual_inflation_rate, age_to_enter_university, current_age) {
	    var education_expenses = Cal.Collection.calConfigs.findWhere({
	        key: 'education_expenses'
	    }).get('data');

	    var living_expense_per_year = 0;
	    var education_expense_per_year = 0;

	    _.each(education_expenses, function (education_expense) {
	        if (education_expense['country'] == country_for_studying) {
	            education_expense_per_year = education_expense['tuition'];
	            living_expense_per_year = education_expense['living_expense'];
	        }
	    });

	    //return Math.round((living_expense_per_year+education_expense_per_year)*Math.pow(1+annual_inflation_rate,age_to_enter_university-current_age));
		return living_expense_per_year+education_expense_per_year;
	};
    
	Cal.educationResult.calculateGap = function(expected_education_savings, total_savings) {
		var gap = expected_education_savings-total_savings;
		return gap>0?gap:0;
	};
	Cal.educationResult.calculateDiscountFactor = function(annual_return_rate, age_to_enter_university, children_age) {
		return annual_return_rate==0?(age_to_enter_university-children_age)*12:(Math.pow(1+annual_return_rate/12,12*(age_to_enter_university-children_age))-1)/(annual_return_rate/12);
	};
	Cal.educationResult.calculateRequiredMonthlySaving = function(required_fund, discount_factor) {
		return Math.max(required_fund/discount_factor,0);
	};
};

Cal.getConfigs = function() {
	var language = Cal.appSetting.get('language'),
		country_code = Cal.appSetting.get('country_code'),
		channel = Cal.appSetting.get('channel').toLowerCase(),
		advisor_name_en = Cal.appSetting.get('advisor_name_en'),
		advisor_name_zh = Cal.appSetting.get('advisor_name_zh'),
		show_recommendation = Cal.appSetting.get('show_recommendation'),
		logo = Cal.Collection.logos.findWhere({
			market_type: country_code,
			distribution_channel_id: channel
		}),
		fwd_logo = logo != undefined ? logo.get('fwd_logo_filename') : 'undefined';
		partner_logo = logo != undefined ? logo.get('partner_logo_filename') : 'undefined',
		out = {
			language: language,
			country_code: country_code,
			channel: channel,
			advisor_name_en: advisor_name_en,
			advisor_name_zh: advisor_name_zh,
			show_recommendation: show_recommendation,
			fwd_logo: fwd_logo,
			partner_logo: partner_logo
		};

	return out;
};

Cal.getResults = function(data) {
	var language = Cal.appSetting.get('language'),
		country_code = Cal.appSetting.get('country_code'),
		channel = Cal.appSetting.get('channel').toLowerCase(),
		enableRetirement = data.expected_retirement_expenses > 0,//data.ideal_retirement_lifestyle && data.ideal_retirement_lifestyle.length > 0,
		enableEducation = data.num_of_children && data.num_of_children > 0 && data.children && data.children.length > 0 && ((data.children[0] && data.children[0]['country_for_studying']) || (data.children[1] && data.children[1]['country_for_studying']) || (data.children[2] && data.children[2]['country_for_studying'])),
		out = {},
		totalNeed = 0,
		totalGap = 0;




	// Set Demographic Info
	Cal.demographicInfo.set({
		gender				: data.gender,
		age					: data.age,
		marital_status		: data.marital_status,
		num_of_children		: data.num_of_children,
		num_of_dependents	: data.num_of_dependents
	});

	// Set Assets Info
	Cal.assetsInfo.set({
		monthly_income			: data.monthly_income,
		liquid_assets			: data.liquid_assets,
		annual_return_rate		: data.annual_return_rate,
		annual_inflation_rate	: data.annual_inflation_rate
	});

	// Set Protection Info
	Cal.protectionInfo.set({
		total_coverage_of_life_policies				: data.total_coverage_of_life_policies,
		num_of_years_for_supporting					: data.num_of_years_for_supporting,
		total_coverage_of_critical_illness_policies	: data.total_coverage_of_critical_illness_policies,
		expected_years_of_loss_of_income			: data.expected_years_of_loss_of_income,
		monthly_house_rental						: data.monthly_house_rental,
		other_monthly_expenses						: data.other_monthly_expenses,
		immediate_cash_needs						: data.immediate_cash_needs
	});
	
	// output JSON
	out = {
		life_protection: {
			life_protection_need		: Math.round(Cal.lifeProtectionResult.get('life_protection_need')),
			liquid_assets				: Cal.lifeProtectionResult.get('liquid_assets'),
			current_life_protection		: Cal.lifeProtectionResult.get('current_life_protection'),
			protection_gap				: Math.round(Cal.lifeProtectionResult.get('protection_gap'))
		},
		critical_illness_protection: {
			ci_protection_need			: Cal.criticalIllnessProtectionResult.get('ci_protection_need'),
			current_ci_protection		: Cal.criticalIllnessProtectionResult.get('current_ci_protection'),
			protection_gap				: Cal.criticalIllnessProtectionResult.get('protection_gap')
		}
	};
	totalNeed += Math.round(Cal.lifeProtectionResult.get('life_protection_need')) + Math.round(Cal.criticalIllnessProtectionResult.get('ci_protection_need'));
	totalGap += Math.round(Cal.lifeProtectionResult.get('protection_gap')) + Math.round(Cal.criticalIllnessProtectionResult.get('protection_gap'));

	// Set Retirement Info
	if (enableRetirement) {
		Cal.retirementInfo.set({
			target_retirement_age		: data.target_retirement_age,
			ideal_retirement_lifestyle	: data.ideal_retirement_lifestyle,
			expected_retirement_expenses: data.expected_retirement_expenses,
			expect_years_of_retirement	: data.expect_years_of_retirement,
			mpf_monthly_contribution	: data.mpf_monthly_contribution
		});
		
		out.retirement = {
			required_fund				: Math.round(Cal.retirementResult.get('required_fund')),
			mpf							: Math.round(Cal.retirementResult.get('mpf')),
			gap							: Math.round(Cal.retirementResult.get('gap')),
			required_monthly_saving		: Math.round(Cal.retirementResult.get('required_monthly_saving'))
		};
		totalNeed += Math.round(Cal.retirementResult.get('required_fund'));
		totalGap += Math.round(Cal.retirementResult.get('gap'));
	}

	// Set Education Info
	if (enableEducation) {
		Cal.Collection.childInfos.comparator = 'time_till_enter_uri';
		Cal.Collection.childInfos.reset();
		_.each(data.children, function(item){
			if(item.age_to_enter_university!=0 && item.country_for_studying!=''){
			
				var country_for_studying = item.country_for_studying,
					expected_years_of_studying = item.expected_years_of_studying,
					education_expenses,
					annual_inflation_rate,
					annual_return_rate,
					k_annual,
					time_till_enter_uri,
					education_expense_per_year,
					living_expense_per_year,
					total_expenses_per_year,
					expected_education_savings;
				if (country_for_studying != undefined){
					education_expenses = Cal.Collection.calConfigs.findWhere({key: 'education_expenses'}).get('data');
					annual_inflation_rate = Cal.assetsInfo.get('annual_inflation_rate');
					annual_return_rate = Cal.assetsInfo.get('annual_return_rate');
					k_annual = Cal.assetsInfo.get('k_annual');
					time_till_enter_uri = item.age_to_enter_university-item.children_age;
					_.each(education_expenses, function(education_expense){
						if (education_expense['country'] == item.country_for_studying) {
							education_expense_per_year = education_expense['tuition'];
							living_expense_per_year = education_expense['living_expense'];
						}
					});
					total_expenses_per_year = Cal.educationResult.calculateTotalExpensesPerYear(item.manual_total_expense_per_year, living_expense_per_year, education_expense_per_year, annual_inflation_rate, item.age_to_enter_university, item.children_age);
					expected_education_savings = Cal.educationResult.calculateExpectedEducationSavings(annual_return_rate, annual_inflation_rate, item.expected_years_of_studying, total_expenses_per_year, k_annual);
					Cal.Collection.childInfos.add(new Cal.Model.ChildInfo({
						children_age					: item.children_age,
						age_to_enter_university			: item.age_to_enter_university,
						country_for_studying			: item.country_for_studying,
						time_till_enter_uri				: time_till_enter_uri,
						expected_education_savings		: expected_education_savings,
						total_expenses_per_year			: total_expenses_per_year,
						expected_years_of_studying		: expected_years_of_studying
					}));
				}
			}
		});
		Cal.educationInfo.set({
			child_infos		: Cal.Collection.childInfos,
			education_fund	: data.education_fund
		});

		//console.log(Cal.educationInfo.hasChanged());
		//if (Cal.educationInfo.hasChanged()) { // not working
			//Cal.Collection.childResults.comparator = 'year_of_saving';
			Cal.Collection.childResults.reset();
			Cal.Collection.childInfos.each(function(item, index){
				var num_of_children = Cal.Collection.childInfos.length,
					education_fund = Cal.educationInfo.get('education_fund'),
					annual_return_rate = Cal.assetsInfo.get('annual_return_rate'),
					children_age = item.get('children_age'),
					expected_years_of_studying = item.get('expected_years_of_studying'),
					age_to_enter_university = item.get('age_to_enter_university'),
					time_till_enter_uri = item.get('time_till_enter_uri'),
					expected_education_savings = item.get('expected_education_savings'),
					total_expenses_per_year = item.get('total_expenses_per_year'),
					total_savings,
					gap,
					discount_factor,
					required_monthly_saving;
				if (index == 0) {
					//=IF(AND(C8=0,D8=0),B22*(1+int)^H4,MIN(B22*(1+int)^H4,H3))
					var h3 = expected_education_savings,
						h4 = time_till_enter_uri;
					total_savings = num_of_children==1?education_fund*Math.pow(1+annual_return_rate,h4):Math.min(education_fund*Math.pow(1+annual_return_rate,h4),h3);
				} else if (index == 1) {
					//=IF(D8=0,(B22*(1+int)^H4-H5)*(1+int)^(I4-(H4)),MIN(((B22*(1+int)^H4)-H5)*(1+int)^(I4-H4),I3))
					var h4 = Cal.Collection.childResults.at(0).get('year_of_saving'),
						h5 = Cal.Collection.childResults.at(0).get('education_fund'),
						i3 = expected_education_savings,
						i4 = time_till_enter_uri;
					total_savings = num_of_children==2?(education_fund*Math.pow(1+annual_return_rate,h4)-h5)*Math.pow(1+annual_return_rate,i4-h4):Math.min((education_fund*Math.pow(1+annual_return_rate,h4)-h5)*Math.pow(1+annual_return_rate,i4-h4),i3);
				} else if (index == 2) {
					//=MIN((((B22*(1+int)^(H4))-H5)*(1+int)^(I4-(H4))-I5)*(1+int)^(J4-(I4)),J3)
					var h4 = Cal.Collection.childResults.at(0).get('year_of_saving'),
						h5 = Cal.Collection.childResults.at(0).get('education_fund'),
						i4 = Cal.Collection.childResults.at(1).get('year_of_saving'),
						i5 = Cal.Collection.childResults.at(1).get('education_fund'),
						j3 = expected_education_savings,
						j4 = time_till_enter_uri;
					total_savings = Math.min((((education_fund*Math.pow(1+annual_return_rate,h4))-h5)*Math.pow(1+annual_return_rate,i4-h4)-i5)*Math.pow(1+annual_return_rate,j4-i4),j3);
				}
				gap = Cal.educationResult.calculateGap(expected_education_savings, total_savings);
				//console.log(annual_return_rate, age_to_enter_university, children_age);
				discount_factor = Cal.educationResult.calculateDiscountFactor(annual_return_rate, age_to_enter_university, children_age);
				//console.log(gap, discount_factor);
				required_monthly_saving = Cal.educationResult.calculateRequiredMonthlySaving(gap, discount_factor);
				Cal.Collection.childResults.add(new Cal.Model.ChildResult({
					required_fund					: expected_education_savings,
					total_expenses_per_year			: total_expenses_per_year,
					education_fund					: total_savings, //=total savings
					gap								: gap,
					required_monthly_saving			: required_monthly_saving,
					year_of_saving					: time_till_enter_uri,
					children_age					: children_age,
					age_to_enter_university			: age_to_enter_university,
					country_for_studying			: item.get('country_for_studying'),
					expected_years_of_studying		: item.get('expected_years_of_studying')
				}));
			});
			//console.log(Cal.Collection.childResults.at(0).get('education_fund'));
			//console.log(Cal.Collection.childResults.at(1).get('education_fund'));
			//console.log(Cal.Collection.childResults.at(2).get('education_fund'));
			Cal.educationResult.set({
				child_results		: Cal.Collection.childResults/*,
				total_required_fund	: 0*/
			});
		//}

		var child_results = [],
			total_required_fund = 0,
			total_existing_education_fund = 0,
			total_education_gap = 0;
		Cal.Collection.childResults.each(function(item){
			child_results.push({
				required_fund			: Math.round(item.get('required_fund')),
				education_fund			: Math.round(item.get('education_fund')),
				gap						: Math.round(item.get('gap')),
				required_monthly_saving	: Math.round(item.get('required_monthly_saving')),
				year_of_saving			: item.get('year_of_saving'),
				total_expenses_per_year : Math.round(item.get('total_expenses_per_year')),
				children_age			: item.get('children_age'),

				age_to_enter_university			: item.get('age_to_enter_university'),
				country_for_studying			: item.get('country_for_studying'),
				expected_years_of_studying		: item.get('expected_years_of_studying')
			});
			total_required_fund += Math.round(item.get('required_fund'));
			totalNeed += Math.round(item.get('required_fund'));
			totalGap += Math.round(item.get('gap'));
			total_existing_education_fund += Math.round(item.get('education_fund'));
			total_education_gap += Math.round(item.get('gap'));
			
		});
		out.education = {
			child_results: child_results,
			total_required_fund: Math.round(total_required_fund),
			total_education_fund: Math.round(total_existing_education_fund),
			total_gap: Math.round(total_education_gap)
		};
	}

	out.total_need = totalNeed;
	out.total_gap = totalGap;

	out.products = [];
	if(Cal.appSetting.get('show_recommendation').toLowerCase()!="false"){
		_.each(Cal.Collection.products.where({
			market_type: country_code,
			distribution_channel_id: channel
		}).filter(function(item){
			var product_category_id = item.get('product_category_id');
			return (product_category_id != 'retirement' && product_category_id != 'education') || (product_category_id == 'retirement' && enableRetirement) || (product_category_id == 'education' && enableEducation);
		}), function(item){
			out.products.push({
				//martet_type: item.get('market_type'),
				//distribution_channel_type: item.get('distribution_channel_type'),
				//distribution_channel_id: item.get('distribution_channel_id'),
				//distribution_channel_name: item.get('distribution_channel_name'),
				//product_category_id: item.get('product_category_id'),
				//product_category: item.get('product_category_' + language),
				product_id: item.get('product_id'),
				product_name: item.get('product_name_' + language),
				product_link: item.get('product_link_' + language)
			});
		});
	}

	// dedup products
	out.products = _.uniq(out.products, function(item){
		return item.product_id;
	});

	out.assumption_notes = {};
	_.each(Cal.Collection.assumptionNotes.filter(function(item){
		var section = item.get('section');
		return (section != 'retirement' && section != 'education') || (section == 'retirement' && enableRetirement) || (section == 'education' && enableEducation);
	}), function(item){
		out.assumption_notes[item.get('section')] = item.get('info_url_' + language)
	});

	//out.age = Cal.demographicInfo.get('age');
	//out.gender = Cal.demographicInfo.get('gender');
	//out.marital_status = Cal.demographicInfo.get('marital_status');
	//out.num_of_children = Cal.demographicInfo.get('num_of_children');
	//out.num_of_dependents = Cal.demographicInfo.get('num_of_dependents');
    //
	out.AssetsInfo = [];
	//out.AssetsInfo.monthly_income = Cal.assetsInfo.get('monthly_income');
	//out.AssetsInfo.annual_return_rate = Cal.assetsInfo.get('annual_return_rate');
	//out.AssetsInfo.annual_inflation_rate = Cal.assetsInfo.get('annual_inflation_rate');
	out.AssetsInfo.total_liquid_assets = Cal.assetsInfo.get('total_liquid_assets');
	//out.AssetsInfo.liquid_assets = [];
	//out.AssetsInfo.liquid_assets.cash_deposit = Cal.assetsInfo.get('liquid_assets').cash_deposit;
	//out.AssetsInfo.liquid_assets.time_deposit = Cal.assetsInfo.get('liquid_assets').time_deposit;
	//out.AssetsInfo.liquid_assets.stock = Cal.assetsInfo.get('liquid_assets').stock;
	//out.AssetsInfo.liquid_assets.fund_bond = Cal.assetsInfo.get('liquid_assets').fund_bond;
	//out.AssetsInfo.liquid_assets.others = Cal.assetsInfo.get('liquid_assets').others;
	out.total_cash_need = Cal.protectionInfo.get('total_cash_need');
	out.total_monthly_spending = Cal.retirementResult.get('total_monthly_spending');
	
	
	return out;
};

Cal.openResource = function(url, needInternet) {
/* 	console.log('Cal.openResource: '+url); */
	
	if(needInternet){
/* 		console.log('need check internet'); */
		
		var keyword = "google";
		$.ajax({
			url:'http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=' + encodeURIComponent(keyword),
			dataType : 'jsonp',
			cache: false,
			timeout: 1000,
			success: function(json){
				Shadowbox.open({
					content: url,
					type: "iframe",
					player: "iframe"
				});
		        if (navigator.userAgent.match(/(iPod|iPhone|iPad)/)) {
		          $('#sb-body-inner').css({
		              'overflow': 'scroll', 
		              '-webkit-overflow-scrolling': 'touch' 
		          }); 
		        }
				return true;
			},error: function(){
				return false;
			}
		});
		
		
	}else{
		
		Shadowbox.open({
			content: url,
			type: "iframe",
			player: "iframe",
			width: 737,
			height: 566
		});
        if (navigator.userAgent.match(/(iPod|iPhone|iPad)/)) {
          $('#sb-body-inner').css({
              'overflow': 'scroll', 
              '-webkit-overflow-scrolling': 'touch' 
          }); 
        }
		return true;
	}
};

Cal.sendReport = function(data, targetObjHTMLPreview) {
	var fna_summary_results = "";
	var reportTemplate;
var htmlData = '<style>#report-wrapper {width: auto;padding: 0;margin: 0;}#report-wrapper *{color: #636466;font-size: 10pt;}#report-wrapper h1{color: #4E7FBB;font-weight: normal;font-size: 18pt;margin: 0 0 12px 0;height: 25px;display: inline-block;}#report-wrapper h3{color: #4E7FBB;font-weight: bold;font-size: 10pt;margin: 0 0 12px 0;height: 19px;}#report-wrapper h4{font-weight: normal;font-size: 10pt;margin: 0 0 12px 0;height: 19px;}#report-wrapper li{padding-left: 8px;}#report-wrapper #report-product-list{margin-left: 25px;}#report-wrapper ul#report-product-list li{line-height: 25px;list-style: disc;}#report-wrapper .clear{width: 100%;clear: both;display: block;}#report-wrapper #logo {float: right;margin: 33px 33px 40px 0;}#report-wrapper .page-header {margin: 58px 0 40px 33px;}#report-wrapper .page-header1 {margin: 58px 0 12px 33px;}#report-wrapper #kv {width: 100%;clear: both;display: block;margin-bottom: 55px;}#report-wrapper .content-wrapper{padding: 0 30px;overflow: auto;}#report-wrapper .section-sep{display: inline-block;width: 100%;margin: 59px 0 0 0;clear:both;}#report-wrapper div.table-wrapper{float: left;display: block;}#report-wrapper div.table-wrapper.half-width{width: 47%;}#report-wrapper div.table-wrapper.full-width{width: 100%;}#report-wrapper div.table-wrapper.margin-right{margin-right: 6%;}/* table style */#report-wrapper table{border-collapse: collapse;width: 100%;}#report-wrapper table td{padding: 5px;margin: 0;vertical-align: top;}#report-wrapper table.top-border{border-top:1px solid #231f20;}#report-wrapper table.all-border{border:1px solid #231f20;}#report-wrapper table.all-border td{border:1px solid #231f20;}#report-wrapper table td.header{padding-bottom: 48px;}#report-wrapper table td.title{width: 62%;}#report-wrapper table td.main-value{font-size: 16pt;padding-bottom: 40px;}#report-wrapper table td.value{text-align: right;}#report-wrapper table td.result-box-1{background-color: #9CBC59 !important;font-weight: bold;}#report-wrapper table td.result-box-2{background-color: #9CBC59 !important;font-weight: bold;color: white;}#report-wrapper table td.result-box-3{background-color: #9CBC59 !important;font-weight: normal;font-size: 16pt;}#report-wrapper .print-footer{display:none;}#report-wrapper .page-break {clear: both;page-break-after: always;}#report-wrapper  {-webkit-print-color-adjust: exact;width: 100%;}#report-wrapper .print-footer {display: none;width: 100%;text-align: right;position: fixed;bottom: 10px;}.clear {clear:both;}@page { margin: 0;}* {font-family: "Arial", "LHei", "Open Sans", sans-serif!important;}</style><div id="report-wrapper"><!--page 1--><div><img src="/public/static/FWDLOGO.png" id="logo" style="float:left;"><h1 class="page-header" style="float:right;"><%= App.i18n.prop("fna_report") %></h1></div><img src="/public/static/HAPPYFAMILY.jpg" id="kv" /><div class="content-wrapper"><div class="full-width table-wrapper margin-right"><table class="full-width top-border margin-right"><tr><td class="header"><%= App.i18n.prop("confidential") %></td></tr><tr><td><%= App.i18n.prop("customer") %>:</td></tr><tr><td class="main-value"><%= customer_name %></td></tr><tr><td><%= App.i18n.prop("advisor") %>:</td></tr><tr><td class="main-value"><%= advisor_name %></td></tr><tr><td><%= App.i18n.prop("date") %>:</td></tr><tr><td class="main-value"><%= date %></td></tr></table></div></div><div class="print-footer"><%= App.i18n.prop("copyright") %></div><div class="page-break"></div><!--page 2--><h1 class="page-header"><%= App.i18n.prop("financial_needs_analysis_summary") %></h1><div class="content-wrapper"><div class="half-width table-wrapper margin-right"><h3><%= App.i18n.prop("report_information") %></h3><table class=" all-border"><tr><td class="title"><%= App.i18n.prop("gender") %></td><td class="value"><%= App.i18n.prop(inputData.gender) %></td></tr><tr><td class="title"><%= App.i18n.prop("age") %></td><td class="value"><%= inputData.age %></td></tr><tr><td class="title"><%= App.i18n.prop("marital_status") %></td><td class="value"><%= App.i18n.prop(inputData.marital_status) %></td></tr></table></div><div class="half-width table-wrapper"><h3>&nbsp;</h3><table class=" all-border"><tr><td class="title"><%= App.i18n.prop("num_of_children") %></td><td class="value"><%= inputData.num_of_children %></td></tr><tr><td class="title"><%= App.i18n.prop("num_of_dependent") %></td><td class="value"><%= inputData.num_of_dependents %></td></tr></table></div><div class="section-sep"></div><div class="half-width table-wrapper margin-right"><h3><%= App.i18n.prop("report_finance") %></h3><table class="all-border"><tr><td class="title"><%= App.i18n.prop("monthly_income") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.monthly_income) %></td></tr><tr><td class="title"><%= App.i18n.prop("annual_return_rate") %></td><td class="value"><%= Math.round(inputData.annual_return_rate*100)+"%" %></td></tr><tr><td class="title"><%= App.i18n.prop("annual_inflation_rate") %></td><td class="value"><%= Math.round(inputData.annual_inflation_rate*100)+"%" %></td></tr></table></div><div class="half-width table-wrapper"><h3>&nbsp;</h3><table class=" all-border"><tr><td class="title"><%= App.i18n.prop("liquid_assets") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.AssetsInfo.total_liquid_assets) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("cash_deposit") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.liquid_assets.cash_deposit) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("time_deposit") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.liquid_assets.time_deposit) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("stock") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.liquid_assets.stock) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("fund_bond") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.liquid_assets.fund_bond) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("others") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.liquid_assets.others) %></td></tr></table></div><div class="section-sep"></div><div class="half-width table-wrapper margin-right"><h3><%= App.i18n.prop("report_protection") %></h3><table class="all-border"><tr><td class="title"><%= App.i18n.prop("life_policies") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.total_coverage_of_life_policies) %></td></tr><tr><td class="title"><%= App.i18n.prop("years_for_supporting") %></td><td class="value"><%= inputData.num_of_years_for_supporting %></td></tr><tr><td class="title"><%= App.i18n.prop("critical_illness_policie") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.total_coverage_of_critical_illness_policies) %></td></tr><tr><td class="title"><%= App.i18n.prop("expected_years_of_loss_of_income") %></td><td class="value"><%= inputData.expected_years_of_loss_of_income %></td></tr></table></div><div class="half-width table-wrapper"><h3>&nbsp;</h3><table class=" all-border"><tr><td class="title"><%= App.i18n.prop("monthly_house_rental") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.monthly_house_rental) %></td></tr><tr><td class="title"><%= App.i18n.prop("other_monthly_expenses") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.other_monthly_expenses) %></td></tr><tr><td class="title"><%= App.i18n.prop("total_cash_need") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.total_cash_need) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("mortgage") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.immediate_cash_needs.mortgage) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("education_funds") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.immediate_cash_needs.education_funds) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("funeral_expenses") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.immediate_cash_needs.funeral_expense) %></td></tr><tr><td class="title"><ul><li><%= App.i18n.prop("others") %></li></ul></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.immediate_cash_needs.others) %></td></tr></table></div></div><div class=" print-footer">Page 2</div><div class="page-break"></div><!--page 3--><div id="page3"><h1 class="page-header"><%= App.i18n.prop("financial_needs_analysis_summary") %></h1><div class="content-wrapper"><div id="retirement-summary"></div><div id="education-summary"></div></div></div><div class=" print-footer">Page 3</div><div class="page-break"></div><!--page 4--><h1 class="page-header"><%= App.i18n.prop("financial_needs_analysis_result") %></h1><div class="content-wrapper"><div class="half-width table-wrapper margin-right"><h3><%= App.i18n.prop("report_life_protection") %></h3><table class="all-border"><tr><td class="title"><%= App.i18n.prop("report_life_protection_need") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.life_protection.life_protection_need) %></td></tr><tr><td class="title"><%= App.i18n.prop("report_liquid_assets") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.life_protection.liquid_assets) %></td></tr><tr><td class="title"><%= App.i18n.prop("report_current_life_protection") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.life_protection.current_life_protection) %></td></tr><tr><td class="title result-box-1"><%= App.i18n.prop("report_protection_gap") %></td><td class="value result-box-1"><%= App.i18n.prop("hkd") + DQ.addCommas(results.life_protection.protection_gap) %></td></tr></table></div><div class="half-width table-wrapper"><h3><%= App.i18n.prop("report_critical_illness_protection") %></h3><table class=" all-border"><tr><td class="title"><%= App.i18n.prop("report_critical_illness_protection_need") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.critical_illness_protection.ci_protection_need) %></td></tr><tr><td class="title"><%= App.i18n.prop("report_current_critical_illness_protection") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.critical_illness_protection.current_ci_protection) %></td></tr><tr><td class="title result-box-1"><%= App.i18n.prop("report_ci_protection_gap") %></td><td class="value result-box-1"><%= App.i18n.prop("hkd") + DQ.addCommas(results.critical_illness_protection.protection_gap) %></td></tr></table></div><div class="clear"></div><div id="retirement-result" style="display:none; full-width; table-wrapper;"></div><div class="clear"></div><div id="education-result" style="display:none; full-width; table-wrapper;"><div class="section-sep"></div></div></div><div class="print-footer">Page 4</div><div class="page-break"></div><!--page 5--><h1 class="page-header"><%= App.i18n.prop("your_total_financial_needs") %></h1><div class="content-wrapper"><div class="full-width table-wrapper"><table class="all-border"><tr><td><%= App.i18n.prop("report_total_financial_needs") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.total_need) %></td></tr><tr><td><%= App.i18n.prop("report_total_liquid_assets") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.AssetsInfo.total_liquid_assets) %></td></tr><tr><td><%= App.i18n.prop("report_total_current_life_protection") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.life_protection.current_life_protection) %></td></tr><tr><td><%= App.i18n.prop("report_total_current_critical_illness_protection") %></td><td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.critical_illness_protection.current_ci_protection) %></td></tr><tr id="retirement-total" style="display: none;"></tr><tr id="education-total" style="display: none;"></tr><tr><td class="result-box-1" id="report_total_gap"></td><td class="result-box-3 value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.total_gap) %></td></tr></table></div></div><div id="report-product-section"></div><div class="print-footer">Page 5</div></div>';

			reportTemplate = _.template(htmlData, data);
			
			
			var $body = $("<body />");
			$body.html(reportTemplate);
			
			
			
			var product_list = "";
			
			if(data.results.products && data.results.products.length>0){

				$body.find("#report-product-section").html(_.template(App.Template.report_product_section, data));
				_.each(data.results.products, function(item){
					product_list += "<li>"+item.product_name+"</li>";
				});
			
				$body.find("#report-product-list").html(product_list);
			}
			
			
			
			
			if(data.results.retirement){
				var retirement_summary = "";
				var report_retirement_result = "";
				var retirement_total = "";
				retirement_summary += $('<div />').html(_.template(App.Template.report_retirement_summary, data)).html();
				$body.find("#retirement-summary").html(retirement_summary);
				
				
				report_retirement_result += $('<div />').html(_.template(App.Template.report_retirement_result, data)).html();
				$body.find("#retirement-result").append(report_retirement_result).show();
			
				retirement_total = $('<div />').append(_.template(App.Template.report_retirement_total, data)).html();
				$body.find("#retirement-total").html(retirement_total).show();
			}
			
			if(data.results.education){
				if(data.results.retirement){
					data.education_letter = "(F)";
				}else{
					data.education_letter = "(E)";
				}
				var education_summary = "";
				var report_education_summary_row_1 = "";
				var report_education_summary_row_2 = "";
				var report_education_summary_row_3 = "";
				var report_education_summary_row_4 = "";
				var report_education_summary_row_5 = "";
				var education_total = "";
				var report_education_result = "";
				var report_education_result_row_1 = "";
				var report_education_result_row_2 = "";
				var report_education_result_row_3 = "";
				var report_education_result_row_4 = "";
				var report_education_result_row_5 = "";
				var report_education_result_row_6 = "";
				
				education_summary += $('<div />').html(_.template(App.Template.report_education_summary_header, data)).html();
				education_summary += $('<div />').html(_.template(App.Template.report_education_summary, data)).html();
				report_education_result += $('<div />').html(_.template(App.Template.report_education_result, data)).html();
				
				_.each(data.results.education.child_results, function(childResult){
					// education_summary += $('<div />').html(_.template(App.Template.report_education_summary, childResult)).html();
					
					report_education_summary_row_1 += $('<div />').html(_.template(App.Template.report_education_summary_row_1, childResult)).html();
					report_education_summary_row_2 += $('<div />').html(_.template(App.Template.report_education_summary_row_2, childResult)).html();
					report_education_summary_row_3 += $('<div />').html(_.template(App.Template.report_education_summary_row_3, childResult)).html();
					report_education_summary_row_4 += $('<div />').html(_.template(App.Template.report_education_summary_row_4, childResult)).html();
					report_education_summary_row_5 += $('<div />').html(_.template(App.Template.report_education_summary_row_5, childResult)).html();
					
					
					report_education_result_row_1 += $('<div />').html(_.template(App.Template.report_education_result_row_1, childResult)).html();
					report_education_result_row_2 += $('<div />').html(_.template(App.Template.report_education_result_row_2, childResult)).html();
					report_education_result_row_3 += $('<div />').html(_.template(App.Template.report_education_result_row_3, childResult)).html();
					report_education_result_row_4 += $('<div />').html(_.template(App.Template.report_education_result_row_4, childResult)).html();
					report_education_result_row_5 += $('<div />').html(_.template(App.Template.report_education_result_row_5, childResult)).html();
					report_education_result_row_6 += $('<div />').html(_.template(App.Template.report_education_result_row_6, childResult)).html();
					
				});
				// $body.find("#education-summary").html(education_summary);


				$body.find("#education-summary").append(education_summary).show();
				$body.find("#education_summary_row_1").append(report_education_summary_row_1);
				$body.find("#education_summary_row_2").append(report_education_summary_row_2);
				$body.find("#education_summary_row_3").append(report_education_summary_row_3);
				$body.find("#education_summary_row_4").append(report_education_summary_row_4);
				$body.find("#education_summary_row_5").append(report_education_summary_row_5);
				

				$body.find("#education-result").append(report_education_result).show();
				$body.find("#education_result_row_1").append(report_education_result_row_1);
				$body.find("#education_result_row_2").append(report_education_result_row_2);
				$body.find("#education_result_row_3").append(report_education_result_row_3);
				$body.find("#education_result_row_4").append(report_education_result_row_4);
				$body.find("#education_result_row_5").append(report_education_result_row_5);
				$body.find("#education_result_row_6").append(report_education_result_row_6);
				
			
				education_total = $('<div />').append(_.template(App.Template.report_education_total, data)).html();
				$body.find("#education-total").html(education_total).show();
				
			}
			
			

			if(!data.results.education && !data.results.retirement){
				$body.find("#page3").hide();
				$body.find("#report_total_gap").html(App.i18n.prop("report_total_gap", {"%s1":""}));
			}else if(data.results.education && data.results.retirement){
				$body.find("#report_total_gap").html(App.i18n.prop("report_total_gap", {"%s1":"-E-F"}));
			}else{
				$body.find("#report_total_gap").html(App.i18n.prop("report_total_gap", {"%s1":"-E"}));
			}
			
			//$('body').html($body.html());
			fna_summary_results = $body.html();
			if(targetObjHTMLPreview){
				targetObjHTMLPreview.html(fna_summary_results);
			}
			content = {};
			content['FNAWarmUp[emailAddress]'] = data.customer_email;
			content['FNAWarmUp[htmlString]'] = fna_summary_results;
	        $.post("/app/LeadFNA/submitFNAWarmUp", content, function(data){})
			return fna_summary_results;
};

Cal.appInit();