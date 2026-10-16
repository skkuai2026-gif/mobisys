console.log("template.js");

/*jshint multistr: true */
App.Template = {

	background: '\
		<div class="image <%= id %>" style="\
			background-image: url(\'<%= App.imagePath %>share/<%= background_image %>\');\
			height: <%= App.viewHeight %>">\
		</div>',
		
	footer_link: '\
		<a href="<%= App.i18n.prop(\'online_security_link\') %>"><%= App.i18n.prop("online_security") %></a>\
		<a href="<%= App.i18n.prop(\'disclaimer_link\') %>"><%= App.i18n.prop("disclaimer") %></a>\
		<a href="<%= App.i18n.prop(\'privacy_ordinance_link\') %>"><%= App.i18n.prop("privacy_ordinance") %></a>',
		
	section: '\
		<section id="section_<%= id %>"></section>',
	
	field_image: '\
		<div class="field image <%= id %>" data-fid="<%= id %>">\
			<div>\
				<img src="<%= App.imagePath + App.language + \'/\' + option.image %>" alt="<%= id %>"/>\
			</div>\
		</div>',
		
	field_select: '\
		<div class="field <%= field_type %> <%= id %>" data-fid="<%= id %>">\
			<div class="question_knob circle">\
				<a class="title"><%= App.i18n.prop(id) %></a>\
				<div class="t-bg"></div>\
				<div class="pie-input"></div>\
				<div class="value"></div>\
			</div>\
		</div>',
	
	field_number_input: '\
		<div class="field <%= field_type %> <%= id %>" data-fid="<%= id %>">\
		<div class="question_knob circle">\
			<a class="title"><%= App.i18n.prop(id) %></a>\
			<div class="t-bg"></div>\
			<div class="pie-input"></div>\
			<div class="value"></div>\
		</div>\
	</div>',
		
	field_slider: '\
		<div class="field <%= field_type %> <%= id %>" data-fid="<%= id %>">\
			<div class="question_knob circle slider">\
			    <a class="title"><%= App.i18n.prop(id) %></a>\
			    <div class="t-bg"></div>\
			    <div class="w-bg"></div>\
			    <input class="knob" name="<%= id %>" \
			    	data-width="<%= App.fieldSize %>" data-height="<%= App.fieldSize %>" data-pColor="#00F" data-fgColor="#4E7FBB" data-thickness=".025" data-displayPrevious=true\
			    	data-min="<%= min %>" data-max="<%= max %>" value="0" data-inputcolor="#9CBC59">\
			</div>\
		</div>',
		
	field_intro: '\
		<div class="field <%= id %>" data-fid="<%= id %>">\
			<div class="intro">\
	        	<h4><%= App.i18n.prop(option.subject) %></h4>\
				<% if (option.body) { %>\
	        		<p><%= App.i18n.prop(option.body) %></p>\
				<% } %>\
			</div>\
		</div>',
	
	field_separator: '\
		<div class="field separator" data-fid="separator"></div>',
		
	data_panel_menu: '\
		<% if (id != "welcome" && id != "welcome2" && id != "welcome3" && id != "welcome4") { %>\
		<li class="<%= id %> menu<%= i %>" data-fid="<%= id %>">\
			<a></a>\
		</li>\
		<% } %>',
		
	data_panel_section: '\
		<li class="header <%= id %>"><%= App.i18n.prop(id) %>\
		<% if (info !== "") { %>\
			<i class="fa-info-circle">\
				<a href="<%= info %>" class="info"><img src="/public/static/skin/images/share/icon-i.png" /></a>\
			</i>\
		<% } %>\
		</li>',
		
	data_panel_field: '\
		<li data-fid="<%= key %>" class="<%= key %> <%= data_type %>">\
			<%= App.i18n.prop(key) %>\
			<span class="data"><%= f_value %></span><span class="arrow"></span>\
		</li>',
		
	data_panel_footer_field: '\
		<li class="footer"></li>',
		
	data_panel_botton: '\
		<a class="button float-right <%= type %>" <% if (link) { %>href="<%= link %>"<% } %>><%= App.i18n.prop(type) %></a>',
		
	result_panel_section: '\
		<ul class="<%= id %> inactive">\
			<li class="header <%= id %>">\
				<%= App.i18n.prop(\'result\') %><br />\
				<%= App.i18n.prop(id) %>\
			</li>\
		</ul>',
	
	result_panel_field: '\
		<li data-fid="<%= key %>" class="<%= css %>">\
			<%= App.i18n.prop(key, options) %>\
			<span class="data"><%= value %></span><span class="arrow"></span>\
		</li>',
		
	result_panel_suggestion: '\
		<li class="basic"><a href="<%= product_link %>"><%= product_name %></a></li>',

	result_panel_field_margin: '\
		<div style="height:55px"></div>',
		
		
	report_education_summary_header: '\
		<div class="section-sep"></div>\
		<div class="half-width table-wrapper margin-right">\
			<h3><%= App.i18n.prop("report_education") %></h3>\
			<table class="all-border">\
				<tr>\
					<td class="title"><%= App.i18n.prop("child_education_fund") %></td>\
					<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.education.total_education_fund) %></td>\
				</tr>\
			</table>\
		</div>\
		',
		
	report_education_summary_old: '\
	<div class="section-sep"></div>\
	<div class="half-width table-wrapper margin-right">\
		<h4><%= App.i18n.prop("child_with_age", {"%s1":children_age}) %></h4>\
		<table class="all-border">\
			<tr>\
				<td class="title"><%= App.i18n.prop("child_age_to_enter_university") %></td>\
				<td class="value"><%= age_to_enter_university %></td>\
			</tr>\
			<tr>\
				<td class="title"><%= App.i18n.prop("child_country_of_studying") %></td>\
				<td class="value"><%= App.i18n.prop(country_for_studying) %></td>\
			</tr>\
		</table>\
	</div>\
	<div class="half-width table-wrapper">\
		<h4>&nbsp;</h4>\
		<table class=" all-border">\
			<tr>\
				<td class="title"><%= App.i18n.prop("child_expected_years_of_studying") %></td>\
				<td class="value"><%= expected_years_of_studying %></td>\
			</tr>\
			<tr>\
				<td class="title"><%= App.i18n.prop("child_expenses_per_year") %></td>\
				<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(total_expenses_per_year) %></td>\
			</tr>\
		</table>\
	</div>\
	',
	
	report_education_summary: '\
	<div class="section-sep" style="margin-top:30px;"></div>\
	<div class="full-width table-wrapper">\
		<table class="all-border">\
			<tr id="education_summary_row_1">\
				<td> </td>\
			</tr>\
			<tr id="education_summary_row_2">\
				<td><%= App.i18n.prop("child_age_to_enter_university") %></td>\
			</tr>\
			<tr id="education_summary_row_3">\
				<td><%= App.i18n.prop("child_expected_years_of_studying") %></td>\
			</tr>\
			<tr id="education_summary_row_4">\
				<td><%= App.i18n.prop("child_country_of_studying") %></td>\
			</tr>\
			<tr id="education_summary_row_5">\
				<td><%= App.i18n.prop("child_expenses_per_year") %></td>\
			</tr>\
		</table>\
	</div>\
	',
	
	report_education_summary_row_1: '\
	<td class="value"><%= App.i18n.prop("child_with_age", {"%s1":children_age}) %></td>\
	',
	report_education_summary_row_2: '\
	<td class="value"><%= age_to_enter_university %></td>\
	',
	report_education_summary_row_3: '\
	<td class="value"><%= expected_years_of_studying %></td>\
	',
	report_education_summary_row_4: '\
	<td class="value"><%= App.i18n.prop(country_for_studying) %></td>\
	',
	report_education_summary_row_5: '\
	<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(total_expenses_per_year) %></td>\
	',
	
	report_education_result: '\
	<div class="full-width table-wrapper">\
		<h3><%= App.i18n.prop("report_education") %></h3>\
		<table class="all-border">\
			<tr id="education_result_row_1">\
				<td class="result-box-2"> </td>\
			</tr>\
			<tr id="education_result_row_2">\
				<td><%= App.i18n.prop("report_required_education_fund") %></td>\
			</tr>\
			<tr id="education_result_row_3">\
				<td><%= App.i18n.prop("report_current_education") %></td>\
			</tr>\
			<tr id="education_result_row_4">\
				<td class="result-box-1"><%= App.i18n.prop("report_education_protection_gap") %></td>\
			</tr>\
			<tr id="education_result_row_5">\
				<td><%= App.i18n.prop("required_monthly_saving") %></td>\
			</tr>\
			<tr id="education_result_row_6">\
				<td><%= App.i18n.prop("year_of_saving") %></td>\
			</tr>\
		</table>\
	</div>\
	',
	
	report_education_result_row_1: '\
	<td class="value result-box-2"><%= App.i18n.prop("child_with_age", {"%s1":children_age}) %></td>\
	',
	report_education_result_row_2: '\
	<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(required_fund) %></td>\
	',
	report_education_result_row_3: '\
	<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(education_fund) %></td>\
	',
	report_education_result_row_4: '\
	<td class="value result-box-1"><%= App.i18n.prop("hkd") + DQ.addCommas(gap) %></td>\
	',
	report_education_result_row_5: '\
	<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(required_monthly_saving) %></td>\
	',
	report_education_result_row_6: '\
	<td class="value"><%= year_of_saving %></td>\
	',
	
	report_education_total: '\
		<td><%= App.i18n.prop("report_total_education_fund", {"%s1":education_letter}) %></td>\
		<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.education.total_education_fund) %></td>\
		',
	
	report_retirement_summary: '\
		<div class="half-width table-wrapper margin-right">\
			<h3><%= App.i18n.prop("report_retirement") %></h3>\
			<table class="all-border">\
				<tr>\
					<td class="title"><%= App.i18n.prop("target_retirement_age") %></td>\
					<td class="value"><%= inputData.target_retirement_age %></td>\
				</tr>\
				<tr>\
					<td class="title"><%= App.i18n.prop("expected_retirement_expenses") %></td>\
					<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.expected_retirement_expenses) %></td>\
				</tr>\
			</table>\
		</div>\
		<div class="half-width table-wrapper">\
			<h3>&nbsp;</h3>\
			<table class="all-border">\
				<tr>\
					<td class="title"><%= App.i18n.prop("expected_years_of_retirement") %></td>\
					<td class="value"><%= inputData.expect_years_of_retirement %></td>\
				</tr>\
				<tr>\
					<td class="title"><%= App.i18n.prop("mpf_monthly_contribution") %></td>\
					<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(inputData.mpf_monthly_contribution) %></td>\
				</tr>\
			</table>\
		</div>\
		',
		
	
	report_retirement_result: '\
		<div class="section-sep"></div>\
		<div class="half-width table-wrapper margin-right">\
			<h3><%= App.i18n.prop("report_retirement") %></h3>\
			<table class="all-border">\
				<tr>\
					<td class="title"><%= App.i18n.prop("report_required_retirement") %></td>\
					<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.retirement.required_fund) %></td>\
				</tr>\
				<tr>\
					<td class="title"><%= App.i18n.prop("report_mpf") %></td>\
					<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.retirement.mpf) %></td>\
				</tr>\
				<tr>\
					<td class="title result-box-1"><%= App.i18n.prop("report_retirement_protection_gap") %></td>\
					<td class="value result-box-1"><%= App.i18n.prop("hkd") + DQ.addCommas(results.retirement.gap) %></td>\
				</tr>\
				<tr>\
					<td class="title"><%= App.i18n.prop("required_monthly_saving") %></td>\
					<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.retirement.required_monthly_saving) %></td>\
				</tr>\
			</table>\
		</div>\
		',
		
	report_retirement_total: '\
		<td><%= App.i18n.prop("report_total_mpf") %></td>\
		<td class="value"><%= App.i18n.prop("hkd") + DQ.addCommas(results.retirement.mpf) %></td>\
		',
	report_product_section: '\
		<div class="section-sep"></div>\
		<h1 class="page-header"><%= App.i18n.prop("our_recommended_products") %></h1>\
		<div class="content-wrapper">\
			<ul id="report-product-list"></ul>\
		</div>\
		',
		
	welcome_page_panel: ''/*'\
		<div><img src="/public/static/skin/images/<%= App.language %>/welcome.png" alt="get_ready_to_live"></div>\
		<div class="welcome_arrow"><img src="/public/static/skin/images/share/welcome_arrow.png" alt="get_ready_to_live"></div>\
		'*/,
		
	alert: '\
		<div class="background">\
		</div>\
		<div class="message">\
			<p><%= message %></p>\
			<a class="button ok">OK</a>\
		</div>\
		'

};