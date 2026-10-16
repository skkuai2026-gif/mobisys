console.log("data/config.json.js");
Data = {};

Data.sections = [
		{
			"key" : "welcome",
			"name": "PageHome1",
			"background_image" : "FNA1.jpg",
			"fields" : [ {
				"key" : "get_ready_to_live",
				"field_type" : "image",
				"data_type" : "non_data",
				"option" : {
					"image" : "welcome.png",
					"text" : "welcome_text"
				},
				"skippable" : true
			} ]
		},
		{
			"key" : "information",
			"name": "Page-Information",
			"background_image" : "section_1a.jpg",
			"bottons" : [ {
				"type" : "reset",
				"link" : ""
			},{
				"type" : "next",
				"link" : ""
			}],
			"fields" : [ {
				"key" : "separator",
				"field_type" : "separator",
				"skippable" : true
			}, {
				"key" : "information_intro",
				"field_type" : "intro",
				"data_type" : "non_data",
				"skippable" : true,
				"option" : {
					"subject" : "information_subject"
				}
			}, {
				"key" : "gender",
				"field_type" : "select",
				"data_type" : "category",
				"option" : [ "male", "female" ],
				"validate" : "optionValidate"
			}, {
				"key" : "age",
				"field_type" : "slider",
				"data_type" : "numeric",
				"min" : 0,
				"max" : 100,
				"default_value" : 18,
				"validate" : "rangeValidate"
			}, {
				"key" : "marital_status",
				"field_type" : "select",
				"data_type" : "category",
				"option" : [ "single", "married", "cohabited", "divorced" ],
				"validate" : "optionValidate"
			}, {
				"key" : "num_of_children",
				"field_type" : "select",
				"data_type" : "numeric",
				"option" : [ 0, 1, 2, 3 ],
				"default_value" : 0,
				"validate" : "optionValidate",
				"related" : {
					"watch" : {
						"section" : "information",
						"field" : "marital_status"
					},
					"cond" : "value == 'married' || value == 'cohabited' || value == 'divorced'"
				}
			}, {
				"key" : "num_of_dependent",
				"field_type" : "select",
				"data_type" : "numeric",
				"option" : [ 0, 1, 2, 3, 4 ],
				"default_value" : 0,
				"validate" : "optionValidate"
			} ]
		},
		{
			"key" : "finance",
			"name": "Page-Finance",
			"background_image" : "section_2a.jpg",
			"prefill": true,
			"bottons" : [ {
				"type" : "reset",
				"link" : ""
			},{
				"type" : "next",
				"link" : ""
			},{
				"type" : "prev",
				"link" : ""
			} ],
			"fields" : [
					{
						"key" : "separator",
						"field_type" : "separator",
						"skippable" : true
					},
					{
						"key" : "finance_intro",
						"field_type" : "intro",
						"data_type" : "non_data",
						"skippable" : true,
						"option" : {
							"subject" : "finance_subject"
						}
					},
					{
						"key" : "monthly_income",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate"
					},
					{
						"key" : "liquid_assets",
						"field_type" : "sum",
						"option" : [ "cash_deposit", "time_deposit", "stock",
								"fund_bond", "others" ],
						"data_type" : "currency",
						"default_value" : 0
					}, {
						"key" : "cash_deposit",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"indent" : "true",
						"validate" : "rangeValidate"
					}, {
						"key" : "time_deposit",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"indent" : "true",
						"validate" : "rangeValidate"
					}, {
						"key" : "stock",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"indent" : "true",
						"validate" : "rangeValidate"
					}, {
						"key" : "fund_bond",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"indent" : "true",
						"validate" : "rangeValidate"
					}, {
						"key" : "others",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"indent" : "true",
						"validate" : "rangeValidate"
					}, {
						"key" : "annual_return_rate",
						"field_type" : "slider",
						"data_type" : "percentage",
						"min" : 0,
						"max" : 10,
						"default_value" : 3,
						"validate" : "rangeValidate"
					}, {
						"key" : "annual_inflation_rate",
						"field_type" : "slider",
						"data_type" : "percentage",
						"min" : 0,
						"max" : 10,
						"default_value" : 3,
						"validate" : "rangeValidate"
					} ]
		},
		{
			"key" : "protection",
			"name": "Page-Protection",
			"background_image" : "section_3a.jpg",
			"info" : "pages/{App.language}/life-protection-calculation.html",
			"prefill": true,
			"bottons" : [ {
				"type" : "reset",
				"link" : ""
			},{
				"type" : "next",
				"link" : ""
			},{
				"type" : "prev",
				"link" : ""
			}],
			"fields" : [
					{
						"key" : "separator",
						"field_type" : "separator",
						"skippable" : true
					},
					{
						"key" : "protection_intro",
						"field_type" : "intro",
						"data_type" : "non_data",
						"skippable" : true,
						"option" : {
							"subject" : "protection_subject",
							"body" : "protection_body"
						}
					},
					{
						"key" : "life_policies",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate"
					},
					{
						"key" : "years_for_supporting",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 50,
						"validate" : "rangeValidate"
					},
					{
						"key" : "critical_illness_policie",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate"
					},
					{
						"key" : "expected_years_of_loss_of_income",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 50,
						"default_value" : 0,
						"validate" : "rangeValidate"
					},
					{
						"key" : "monthly_house_rental",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate"
					},
					{
						"key" : "other_monthly_expenses",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 1,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate"
					},
					{
						"key" : "total_cash_need",
						"field_type" : "sum",
						"option" : [ "mortgage", "education_funds",
								"funeral_expenses", "others" ],
						"data_type" : "currency",
						"default_value" : 0
					}, {
						"key" : "mortgage",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"indent" : "true",
						"default_value" : 0,
						"validate" : "rangeValidate"
					}, {
						"key" : "education_funds",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"indent" : "true",
						"default_value" : 0,
						"validate" : "rangeValidate"
					}, {
						"key" : "funeral_expenses",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"indent" : "true",
						"default_value" : 0,
						"validate" : "rangeValidate"
					}, {
						"key" : "others",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"indent" : "true",
						"default_value" : 0,
						"validate" : "rangeValidate"
					} ]
		},
		{
			"key" : "retirement",
			"name": "Page-Retirement",
			"background_image" : "section_4a.jpg",
			"info": "pages/{App.language}/retirement-needs-calculation.html",
			"bottons" : [{
				"type" : "reset",
				"link" : ""
			},{
				"type" : "next",
				"link" : ""
			},{
				"type" : "prev",
				"link" : ""
			}],
			"fields" : [ {
				"key" : "separator",
				"field_type" : "separator",
				"skippable" : true
			}, {
				"key" : "retirement_intro",
				"field_type" : "intro",
				"data_type" : "non_data",
				"skippable" : true,
				"option" : {
					"subject" : "retirement_subject",
					"body" : "retirement_body"
				}
			}, {
				"key" : "retirement_now",
				"field_type" : "select",
				"data_type" : "category",
				"option" : [ "yes", "no" ],
				"validate" : "optionValidate"
			}, {
				"key" : "target_retirement_age",
				"field_type" : "slider",
				"data_type" : "numeric",
				"min" : 40,
				"max" : 100,
				"default_value" : 65,
				"validate" : "rangeValidate",
				"related" : {
					"watch" : {
						"section" : "retirement",
						"field" : "retirement_now"
					},
					"cond" : "value === 'yes'"
				}
			}, {
				"key" : "expected_retirement_expenses",
				"field_type" : "number_input",
				"data_type" : "currency",
				"min" : 0,
				"max" : 99999999,
				"default_value" : 0,
				"validate" : "rangeValidate",
				"related" : {
					"watch" : {
						"section" : "retirement",
						"field" : "retirement_now"
					},
					"cond" : "value === 'yes'"
				}
			}, {
				"key" : "expect_years_of_retirement",
				"field_type" : "slider",
				"data_type" : "numeric",
				"min" : 0,
				"max" : 100,
				"default_value" : 20,
				"validate" : "rangeValidate",
				"related" : {
					"watch" : {
						"section" : "retirement",
						"field" : "retirement_now"
					},
					"cond" : "value === 'yes'"
				}
			}, {
				"key" : "mpf_monthly_contribution",
				"field_type" : "number_input",
				"data_type" : "currency",
				"min" : 0,
				"max" : 99999999,
				"default_value" : 0,
				"validate" : "rangeValidate",
				"related" : {
					"watch" : {
						"section" : "retirement",
						"field" : "retirement_now"
					},
					"cond" : "value === 'yes'"
				}
			},
			{
				"key" : "retirement_end",
				"field_type" : "intro",
				"data_type" : "non_data",
				"skippable" : true,
				"noborder": true,
				"option" : {
					"subject" : "retirement_end_subject",
					"body" : "retirement_end_body"
				},
				"related" : {
					"watch" : {
						"section" : "information",
						"field" : "num_of_children"
					},
					"cond" : "value == 0"
				}
			}
			]
		},
		{
			"key" : "education",
			"name": "Page-Education",
			"background_image" : "section_5a.jpg",
			"info": "pages/{App.language}/education-needs-calculation.html",
			"bottons" : [ {
				"type" : "reset",
				"link" : ""
			},{
				"type" : "prev",
				"link" : ""
			}],
			"fields" : [
					{
						"key" : "separator",
						"field_type" : "separator",
						"skippable" : true
					},
					{
						"key" : "education_intro",
						"field_type" : "intro",
						"data_type" : "non_data",
						"skippable" : true,
						"option" : {
							"subject" : "education_subject",
							"body" : "education_body"
						}
					},
					{
						"key" : "child_consider_1",
						"field_type" : "select",
						"data_type" : "category",
						"option" : [ "yes", "no" ],
						"validate" : "optionValidate",
						"related" : {
							"watch" : {
								"section" : "information",
								"field" : "num_of_children"
							},
							"cond" : "value >= 1"
						}
					},
					{
						"key" : "child1",
						"field_type" : "non_field",
						"data_type" : "numeric",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value == 'yes'"
						}
					},
					{
						"key" : "child1_age",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 30,
						"default_value" : 0,
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "rangeValidate"
					},
					{
						"key" : "child1_age_to_enter_university",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 30,
						"default_value" : 17,
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "rangeValidate"
					},
					{
						"key" : "child1_expected_years_of_studying",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 10,
						"default_value" : 4,
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "rangeValidate"
					},
					{
						"key" : "child1_country_of_studying",
						"field_type" : "select",
						"data_type" : "category",
						"option" : [ "hong_kong", "uk", "usa", "canada",
								"australia", "new_zealand", "china" ],
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "optionValidate"
					},
					{
						"key" : "child1_manual_total_expense",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate",
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value == 'yes'"
						}
					},
					{
						"key" : "child_consider_2",
						"field_type" : "select",
						"data_type" : "category",
						"option" : [ "yes", "no" ],
						"validate" : "optionValidate",
						"related" : {
							"watch" : {
								"section" : "information",
								"field" : "num_of_children"
							},
							"cond" : "value >= 2"
						}
					},
							{
								"key" : "child2_age",
								"field_type" : "slider",
								"data_type" : "numeric",
								"min" : 0,
								"max" : 30,
								"default_value" : 0,
								"indent" : "true",
								"related" : {
									"watch" : {
										"section" : "education",
										"field" : "child_consider_2"
									},
									"cond" : "value == 'yes'"
								},
								"validate" : "rangeValidate"
							},
							{
								"key" : "child2_age_to_enter_university",
								"field_type" : "slider",
								"data_type" : "numeric",
								"min" : 0,
								"max" : 30,
								"default_value" : 17,
								"indent" : "true",
								"related" : {
									"watch" : {
										"section" : "education",
										"field" : "child_consider_2"
									},
									"cond" : "value == 'yes'"
								},
								"validate" : "rangeValidate"
							},
							{
								"key" : "child2_expected_years_of_studying",
								"field_type" : "slider",
								"data_type" : "numeric",
								"min" : 0,
								"max" : 10,
								"default_value" : 4,
								"indent" : "true",
								"related" : {
									"watch" : {
										"section" : "education",
										"field" : "child_consider_2"
									},
									"cond" : "value == 'yes'"
								},
								"validate" : "rangeValidate"
							},
							{
								"key" : "child2_country_of_studying",
								"field_type" : "select",
								"data_type" : "category",
								"option" : [ "hong_kong", "uk", "usa", "canada",
										"australia", "new_zealand", "china" ],
								"indent" : "true",
								"related" : {
									"watch" : {
										"section" : "education",
										"field" : "child_consider_2"
									},
									"cond" : "value == 'yes'"
								},
								"validate" : "optionValidate"
							},
							{
								"key" : "child2_manual_total_expense",
								"field_type" : "number_input",
								"data_type" : "currency",
								"min" : 0,
								"max" : 99999999,
								"default_value" : 0,
								"validate" : "rangeValidate",
								"indent" : "true",
								"related" : {
									"watch" : {
										"section" : "education",
										"field" : "child_consider_2"
									},
									"cond" : "value == 'yes'"
								}
							},
					{
						"key" : "child_consider_3",
						"field_type" : "select",
						"data_type" : "category",
						"option" : [ "yes", "no" ],
						"validate" : "optionValidate",
						"related" : {
							"watch" : {
								"section" : "information",
								"field" : "num_of_children"
							},
							"cond" : "value >= 3"
						}
					},
					{
						"key" : "child3_age",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 30,
						"default_value" : 0,
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_3"
							},
							"cond" : "value === 'yes'"
						},
						"validate" : "rangeValidate"
					},
					{
						"key" : "child3_age_to_enter_university",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 30,
						"default_value" : 17,
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_3"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "rangeValidate"
					},
					{
						"key" : "child3_expected_years_of_studying",
						"field_type" : "slider",
						"data_type" : "numeric",
						"min" : 0,
						"max" : 10,
						"default_value" : 4,
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_3"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "rangeValidate"
					},
					{
						"key" : "child3_country_of_studying",
						"field_type" : "select",
						"data_type" : "category",
						"option" : [ "hong_kong", "uk", "usa", "canada",
								"australia", "new_zealand", "china" ],
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_3"
							},
							"cond" : "value == 'yes'"
						},
						"validate" : "optionValidate"
					}, {
						"key" : "child3_manual_total_expense",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate",
						"indent" : "true",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_3"
							},
							"cond" : "value == 'yes'"
						}
					}, {
						"key" : "education_fund",
						"field_type" : "number_input",
						"data_type" : "currency",
						"min" : 0,
						"max" : 99999999,
						"default_value" : 0,
						"validate" : "rangeValidate",
						"related" : {
							"watch" : {
								"section" : "education",
								"field" : "child_consider_1"
							},
							"cond" : "value === 'yes'"
						}
					},
					{
						"key" : "education_end",
						"field_type" : "intro",
						"data_type" : "non_data",
						"noborder": true,
						"option" : {
							"subject" : "education_end_subject",
							"body" : "education_end_body"
						}
					}
					]
		}
		];
