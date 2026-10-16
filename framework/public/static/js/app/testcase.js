// Data from "Test Plan (FApp-FNA) 2014-07-24 (DC_DK_RI).xlsx"
console.log("testcase.js");

var Testcase = {
	setCase : function(id) {
		var data = Testcase.data[id];

		// auto input test values to fields
		_.each(data, function(s) {
			var section = App.Collection.sections.get(s.key);
			var fields = section.get('fields');
			_.each(s.fields, function(f) {
				var field = fields.get(f.key);
				// console.log(field, f.key);
				field.set('value', f.value);
			});
		});
		
		App.Result.getResult(App.Collection.sections);
	}
};

Testcase.data = [];

Testcase.data[0] = /* Marry Lee */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "female"
	}, {
		"key" : "age",
		"value" : "25"
	},  {
		"key" : "marital_status",
		"value" : "single"
	}, {
		"key" : "num_of_children",
		"value" : "0"
	}, {
		"key" : "num_of_dependent",
		"value" : "1"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "12000"
	}, {
		"key" : "cash_deposit",
		"value" : "5000"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : "15000"
	}, {
		"key" : "fund_bond",
		"value" : ""
	}, {
		"key" : "others",
		"value" : ""
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "0"
	}, {
		"key" : "years_for_supporting",
		"value" : "5"
	}, {
		"key" : "critical_illness_policie",
		"value" : "200000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "5"
	}, {
		"key" : "monthly_house_rental",
		"value" : "0"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "5000"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "0"
	}, {
		"key" : "funeral_expenses",
		"value" : "40000"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "60"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "1200"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	} ]

}

];


Testcase.data[1] = /* Susan Chan */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "female"
	}, {
		"key" : "age",
		"value" : "30"
	},  {
		"key" : "marital_status",
		"value" : "single"
	}, {
		"key" : "num_of_children",
		"value" : "0"
	}, {
		"key" : "num_of_dependent",
		"value" : "0"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "12000"
	}, {
		"key" : "cash_deposit",
		"value" : "10000"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : "30000"
	}, {
		"key" : "fund_bond",
		"value" : ""
	}, {
		"key" : "others",
		"value" : "5000"
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "0"
	}, {
		"key" : "years_for_supporting",
		"value" : "0"
	}, {
		"key" : "critical_illness_policie",
		"value" : "500000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "2"
	}, {
		"key" : "monthly_house_rental",
		"value" : "4000"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "3000"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "0"
	}, {
		"key" : "funeral_expenses",
		"value" : "35000"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "58"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "1200"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	}]
}

];


Testcase.data[2] = /* Johnny Tse */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "male"
	}, {
		"key" : "age",
		"value" : "35"
	},  {
		"key" : "marital_status",
		"value" : "married"
	}, {
		"key" : "num_of_children",
		"value" : "1"
	}, {
		"key" : "num_of_dependent",
		"value" : "1"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "11500"
	}, {
		"key" : "cash_deposit",
		"value" : "10000"
	}, {
		"key" : "time_deposit",
		"value" : "20000"
	}, {
		"key" : "stock",
		"value" : "28000"
	}, {
		"key" : "fund_bond",
		"value" : ""
	}, {
		"key" : "others",
		"value" : ""
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "200000"
	}, {
		"key" : "years_for_supporting",
		"value" : "12"
	}, {
		"key" : "critical_illness_policie",
		"value" : "200000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "3"
	}, {
		"key" : "monthly_house_rental",
		"value" : "6000"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "8000"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "20000"
	}, {
		"key" : "funeral_expenses",
		"value" : "50000"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "60"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "1150"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	}, {
		"key" : "child1_age",
		"value" : "5"
	},{
		"key" : "child1_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child1_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child1_country_of_studying",
		"value" : "hong_kong"
	},{
		"key" : "child1_manual_total_expense",
		"value" : "0"
	}]
}

];


Testcase.data[3] = /* Tom */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "male"
	}, {
		"key" : "age",
		"value" : "40"
	},  {
		"key" : "marital_status",
		"value" : "married"
	}, {
		"key" : "num_of_children",
		"value" : "1"
	}, {
		"key" : "num_of_dependent",
		"value" : "1"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "13000"
	}, {
		"key" : "cash_deposit",
		"value" : "25000"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : "35000"
	}, {
		"key" : "fund_bond",
		"value" : ""
	}, {
		"key" : "others",
		"value" : "22000"
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "80000"
	}, {
		"key" : "years_for_supporting",
		"value" : "13"
	}, {
		"key" : "critical_illness_policie",
		"value" : "300000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "2"
	}, {
		"key" : "monthly_house_rental",
		"value" : "6000"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "5000"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "20000"
	}, {
		"key" : "funeral_expenses",
		"value" : "50000"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "60"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "1300"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	}, {
		"key" : "child1_age",
		"value" : "3"
	},{
		"key" : "child1_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child1_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child1_country_of_studying",
		"value" : "hong_kong"
	},{
		"key" : "child1_manual_total_expense",
		"value" : "40000"
	}]
}

];


Testcase.data[4] = /* Kitty */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "female"
	}, {
		"key" : "age",
		"value" : "45"
	},  {
		"key" : "marital_status",
		"value" : "married"
	}, {
		"key" : "num_of_children",
		"value" : "3"
	}, {
		"key" : "num_of_dependent",
		"value" : "1"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "13000"
	}, {
		"key" : "cash_deposit",
		"value" : "22000"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : "35000"
	}, {
		"key" : "fund_bond",
		"value" : ""
	}, {
		"key" : "others",
		"value" : "18000"
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "150000"
	}, {
		"key" : "years_for_supporting",
		"value" : "13"
	}, {
		"key" : "critical_illness_policie",
		"value" : "300000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "2"
	}, {
		"key" : "monthly_house_rental",
		"value" : "5500"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "4000"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "40000"
	}, {
		"key" : "funeral_expenses",
		"value" : "50000"
	}, {
		"key" : "others",
		"value" : "10000"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "60"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "1300"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	}, {
		"key" : "child1_age",
		"value" : "3"
	},{
		"key" : "child1_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child1_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child1_country_of_studying",
		"value" : "hong_kong"
	},{
		"key" : "child1_manual_total_expense",
		"value" : "0"
	},{
		"key" : "child2_age",
		"value" : "2"
	},{
		"key" : "child2_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child2_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child2_country_of_studying",
		"value" : "hong_kong"
	},{
		"key" : "child2_manual_total_expense",
		"value" : "0"
	},{
		"key" : "child3_age",
		"value" : "1"
	},{
		"key" : "child3_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child3_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child3_country_of_studying",
		"value" : "hong_kong"
	},{
		"key" : "child3_manual_total_expense",
		"value" : "0"
	}]
}

];


Testcase.data[5] = /* Cathy */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "female"
	}, {
		"key" : "age",
		"value" : "28"
	},  {
		"key" : "marital_status",
		"value" : "single"
	}, {
		"key" : "num_of_children",
		"value" : "0"
	}, {
		"key" : "num_of_dependent",
		"value" : "1"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "12000"
	}, {
		"key" : "cash_deposit",
		"value" : "5000"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : ""
	}, {
		"key" : "fund_bond",
		"value" : "13000"
	}, {
		"key" : "others",
		"value" : ""
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "0"
	}, {
		"key" : "years_for_supporting",
		"value" : "5"
	}, {
		"key" : "critical_illness_policie",
		"value" : "200000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "3"
	}, {
		"key" : "monthly_house_rental",
		"value" : "0"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "6000"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "0"
	}, {
		"key" : "funeral_expenses",
		"value" : "50000"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "60"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "1200"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	}]
}

];


Testcase.data[6] = /* Tom Lee */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "male"
	}, {
		"key" : "age",
		"value" : "40"
	},  {
		"key" : "marital_status",
		"value" : "married"
	}, {
		"key" : "num_of_children",
		"value" : "3"
	}, {
		"key" : "num_of_dependent",
		"value" : "1"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "83000"
	}, {
		"key" : "cash_deposit",
		"value" : "25000"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : "535000"
	}, {
		"key" : "fund_bond",
		"value" : "20000"
	}, {
		"key" : "others",
		"value" : "22000"
	}, {
		"key" : "annual_return_rate",
		"value" : "7"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "180000"
	}, {
		"key" : "years_for_supporting",
		"value" : "13"
	}, {
		"key" : "critical_illness_policie",
		"value" : "300000"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "6"
	}, {
		"key" : "monthly_house_rental",
		"value" : "0"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "55000"
	}, {
		"key" : "mortgage",
		"value" : "4000000"
	}, {
		"key" : "education_funds",
		"value" : "60000"
	}, {
		"key" : "funeral_expenses",
		"value" : "50000"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}, {
	"key" : "retirement",
	"fields" : [ {
		"key" : "target_retirement_age",
		"value" : "60"
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : "20"
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : "3000"
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : "0"
	}, {
		"key" : "child1_age",
		"value" : "3"
	},{
		"key" : "child1_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child1_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child1_country_of_studying",
		"value" : "uk"
	},{
		"key" : "child1_manual_total_expense",
		"value" : "0"
	},{
		"key" : "child2_age",
		"value" : "4"
	},{
		"key" : "child2_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child2_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child2_country_of_studying",
		"value" : "usa"
	},{
		"key" : "child2_manual_total_expense",
		"value" : "0"
	},{
		"key" : "child3_age",
		"value" : "1"
	},{
		"key" : "child3_age_to_enter_university",
		"value" : "17"
	},{
		"key" : "child3_expected_years_of_studying",
		"value" : "4"
	},{
		"key" : "child3_country_of_studying",
		"value" : "canada"
	},{
		"key" : "child3_manual_total_expense",
		"value" : "0"
	}]
}

];


Testcase.data[7] = /* Gerry Ho */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "male"
	}, {
		"key" : "age",
		"value" : 40
	},  {
		"key" : "marital_status",
		"value" : "married"
	}, {
		"key" : "num_of_children",
		"value" : 3
	}, {
		"key" : "num_of_dependent",
		"value" : 1
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : 83000
	}, {
		"key" : "cash_deposit",
		"value" : 25000
	}, {
		"key" : "time_deposit",
		"value" : 0
	}, {
		"key" : "stock",
		"value" : 535000
	}, {
		"key" : "fund_bond",
		"value" : 20000
	}, {
		"key" : "others",
		"value" : 22000
	}, {
		"key" : "annual_return_rate",
		"value" : 7
	}, {
		"key" : "annual_inflation_rate",
		"value" : 3
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : 180000
	}, {
		"key" : "years_for_supporting",
		"value" : 13
	}, {
		"key" : "critical_illness_policie",
		"value" : 300000
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : 6
	}, {
		"key" : "monthly_house_rental",
		"value" : 0
	}, {
		"key" : "other_monthly_expenses",
		"value" : 55000
	}, {
		"key" : "mortgage",
		"value" : 4000000
	}, {
		"key" : "education_funds",
		"value" : 60000
	}, {
		"key" : "funeral_expenses",
		"value" : 50000
	}, {
		"key" : "others",
		"value" : 0
	} ]
}, {
	"key" : "retirement",
	"fields" : [ 
	{
		"key" : "retirement_now",
		"value" : "yes"
	},
	{
		"key" : "target_retirement_age",
		"value" : 60
	}, {
		"key" : "expected_retirement_expenses",
		"value" : 0
	}, {
		"key" : "expect_years_of_retirement",
		"value" : 20
	}, {
		"key" : "mpf_monthly_contribution",
		"value" : 3000
	} ]
}, {
	"key" : "education",
	"fields" : [ {
		"key" : "education_fund",
		"value" : 1000000
	},
	{
		"key" : "child_consider_1",
		"value" : "yes"
	},
	{
		"key" : "child1_age",
		"value" : 3
	},{
		"key" : "child1_age_to_enter_university",
		"value" : 17
	},{
		"key" : "child1_expected_years_of_studying",
		"value" : 4
	},{
		"key" : "child1_country_of_studying",
		"value" : "uk"
	},{
		"key" : "child1_manual_total_expense",
		"value" : 0
	},
	{
		"key" : "child_consider_2",
		"value" : "yes"
	},
	{
		"key" : "child2_age",
		"value" : 4
	},{
		"key" : "child2_age_to_enter_university",
		"value" : 17
	},{
		"key" : "child2_expected_years_of_studying",
		"value" : 4
	},{
		"key" : "child2_country_of_studying",
		"value" : "usa"
	},{
		"key" : "child2_manual_total_expense",
		"value" : 0
	},
	{
		"key" : "child_consider_3",
		"value" : "yes"
	},
	{
		"key" : "child3_age",
		"value" : 1
	},{
		"key" : "child3_age_to_enter_university",
		"value" : 17
	},{
		"key" : "child3_expected_years_of_studying",
		"value" : 4
	},{
		"key" : "child3_country_of_studying",
		"value" : "canada"
	},{
		"key" : "child3_manual_total_expense",
		"value" : 0
	}]
}

];


Testcase.data[8] = /* Peter Kwan */
[ {
	"key" : "information",
	"fields" : [ {
		"key" : "gender",
		"value" : "female"
	}, {
		"key" : "age",
		"value" : "30"
	},  {
		"key" : "marital_status",
		"value" : "single"
	}, {
		"key" : "num_of_children",
		"value" : "0"
	}, {
		"key" : "num_of_dependent",
		"value" : "0"
	}, ]
}, {
	"key" : "finance",
	"fields" : [ {
		"key" : "monthly_income",
		"value" : "0"
	}, {
		"key" : "cash_deposit",
		"value" : "0"
	}, {
		"key" : "time_deposit",
		"value" : "0"
	}, {
		"key" : "stock",
		"value" : "0"
	}, {
		"key" : "fund_bond",
		"value" : ""
	}, {
		"key" : "others",
		"value" : "0"
	}, {
		"key" : "annual_return_rate",
		"value" : "4"
	}, {
		"key" : "annual_inflation_rate",
		"value" : "3"
	} ]
}, {
	"key" : "protection",
	"fields" : [ {
		"key" : "life_policies",
		"value" : "0"
	}, {
		"key" : "years_for_supporting",
		"value" : "0"
	}, {
		"key" : "critical_illness_policie",
		"value" : "0"
	}, {
		"key" : "expected_years_of_loss_of_income",
		"value" : "0"
	}, {
		"key" : "monthly_house_rental",
		"value" : "0"
	}, {
		"key" : "other_monthly_expenses",
		"value" : "0"
	}, {
		"key" : "mortgage",
		"value" : "0"
	}, {
		"key" : "education_funds",
		"value" : "0"
	}, {
		"key" : "funeral_expenses",
		"value" : "0"
	}, {
		"key" : "others",
		"value" : "0"
	} ]
}

];