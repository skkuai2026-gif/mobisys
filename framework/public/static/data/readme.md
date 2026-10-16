# Syntax of config.json.js file

Data.sections:
[							// array	group of sections
  {							// object	section object
    "id": 					// string	section id
    "background_image": 	// string	section background image (optional)
    "info":					// string	page string, show info icon in section title, open the page when click. 
    "prefill":				// boolean	when true, will auto prefill all fields to default values
    "buttons":[				// array	buttons show on section data panel
    	{
    		"type":			// string	type of botton: reset, modify, email, prev, next
    		"options":		// array/string options of bottom, e.g. URL
    	}
    ]						
    "fields": [				// array	fields of section
      {						// object	field object
        "id": 				// string	field id
		"field_type":		// string	select, slider, number-input, intro, separator, image, sum, calculateTotalExpensesPerYear, non_field
        "data_type": 		// string	category, numeric, currency, percentage, non_data
        "option": [] 		// array 	data options for 'select' & 'input' field_type
        "min":				// number	min value of 'input', 'slider' field_type
        "max":				// number	max value of 'input', 'slider' field_type
        "skippable":		// boolean	the field is skippable (optional)
        "validate":			// string	validate functions (optional)
        								- "rangeValidate" for min/max numeric data_type 
        								- "optionValidate" for category data_type
        "default_value":	// string/number	default value (optional)
        "related": {		// object	this field will show only if the condition of related field passed
			"watch": {		// object	the watching field
				"section":	// string	the section id of field
				"field":	// string	the id of field
			},
			"cond":			// string	the field will be show only if condition passed
										e.g. "value == 'married' || value == 'cohabited'"
        }
      }
    ]
  }
]