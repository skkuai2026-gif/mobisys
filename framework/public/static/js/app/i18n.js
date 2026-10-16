console.log('i18n.js');

App.i18n = {
		
	en:0, 
	zh:1,
		
	prop : function(arg, options) {
		var s = this.languages[arg];
		if (s) {
			s = s[this[App.language]];
		} else {
			s = isNaN(arg) ? "["+arg+"]" : arg;
		}
		
		if (options) {
			_.each(options, function(v,k) {
				s = s.replace(k, v);
			});
		}
		
		return s;
	},

	languages: {
		/* Welcome 0 */
		welcome : ['WELCOME','歡迎'],
		welcome_text: ['<p>How to plan for a financial secured future to meet the needs in different life stages?</p>\
						<p>During the next few minutes, our advisers will walk you through a comprehensive financial analysis. This journey will help you identify your financial goals in life, critical illness protection, retirement and children education. We hope to enable you to be financially well-prepared for yourself and  family.</p>\
						',
						'<p>如何為未來進行財務規劃，以滿足人生在不同階段的需要？</p>\
		               <p>在接下來的幾分鐘裡，我們的顧問將協助您完成一個全面的財務分析。這旅程將幫助您清晰您的財務需要，包括人壽、危疾保障、退休計劃及子女教育，確保您和家人獲得妥善的財務保障。</p>\
		               '],
		start : ['START','開始'],
		welcome_tagline : ['Get ready to live','敢 至係人生'],
		welcome_sub_tagline_1 : ['Take your opportunity today, we will take care of your worry!','將未來放心交託，呢一刻，盡情吧！'],
		//welcome_remark : ['All financial amount are presented in HKD.','所有財務金額將以港幣表示。'],
		
		/* Section 1 */
		information : ['INFORMATION','個人資料'],
		information_subject : ['Please let us know about you more.','請讓我們認識您多一點。'],
		gender : ['Gender','性別'],
		male : ['Male','男'],
		female : ['Female','女'],
		age : ['Age','年齡'],
		marital_status : ['Marital Status','婚姻狀況'],
		single : ['Single','單身'],
		married : ['Married','已婚'],
		cohabited : ['Cohabited','同居'],
		divorced : ['Divorced','離婚'],
		num_of_children : ['No. of Children','子女數目'],
		num_of_dependent : ['No. of Dependents (exclude children)','供養人士數目(不包括子女)'],

		/* Section 2 */
		finance : ['FINANCE','財務狀況'],
		finance_subject : ['More understanding of yourself, closer to your ideal life.','多一點了解自已，早一步實踐理想人生。'],
		monthly_income : ['Monthly Income','每月收入'],
		liquid_assets : ['Liquid Assets','流動資產'],
		cash_deposit : ['Cash / Deposit','現金 / 存款'],
		time_deposit : ['Time Deposit','定期存款'],
		stock : ['Stock','股票'],
		fund_bond : ['Fund / Bond','基金 / 債券'],
		section3_others : ['Others','其它'],
		annual_return_rate : ['Annual Return Rate (%)','年度回報率 (%)'],
		annual_inflation_rate : ['Annual Inflation Rate (%)','每年通貨膨脹率 (%)'],
		//section3_remark : ['All financial amount are presented in HKD.','所有財務金額將以港幣表示。'],

		/* Section 3 */
		protection : ['PROTECTION','保障'],
		protection_subject : ['ARE YOU WELL PROTECTED?',
		                  '您有足夠的保障嗎？'],
		protection_body : ['It is unexpected that always happens, unexpected events such as<br>injury, disability or even critical illness can lead to heavy financial<br>burden. So it is very important to ensure yourself and your loved ones<br>being safe guarded with enough protection and savings.',
		                   '世事難料，突發事件如意外受傷，殘疾甚至<br>危疾有可能令您承擔沉重的財政壓力。因此，確保自己<br>及摯愛有足夠的保障及儲蓄計劃是非常重要的。'], //Changed
		life_policies : ['Total Coverage of Life Policies','現有總人壽保額'],
		years_for_supporting : ['Dependents: Years for Supporting','受供養人：所需供養年期'],
		critical_illness_policie : ['Total Coverage of CI Policies','現有總危疾保額'], 
		expected_years_of_loss_of_income : ['Expected Years of Income Loss','治療期間：預計損失收入年期'],
		monthly_house_rental : ['Monthly House Rental','每月住屋開支'],
		other_monthly_expenses : ['Other Monthly Expenses','每月的其他開支'],
		total_cash_need : ['Total Cash Need','總現金需要'],
		mortgage : ['Mortgage','樓宇按揭'],
		education_funds : ['Education Funds','教育基金'],
		funeral_expenses : ['Funeral expense','善終開支'],
		section4_others : ['Others','其它'],
		//section4_remark : ['All financial amount are presented in HKD.','所有財務金額將以港幣表示。'],
		other_monthly_expenses_error : ["To discover your life protection needs, please input 'Dependents: Years for Supporting' and 'Other Monthly Expenses'.",'為方便推算閣下之人壽保障需要，請輸入‘受供養人: 所需供養年期’ 及’每月的其他開支’ 之資料。'],

		/* Section 4 */
		retirement : ['RETIREMENT','退休'],
		retirement_subject:['RETIRE EARLY WITHOUT COMPROMISING YOUR STANDARD OF LIVING?','想提早退休但仍可享受現有的生活質素?'],
		retirement_body:['MPF alone may not provide you with sufficient fund to maintain your<br>current living standard during retirement. It is very important to plan<br>for a worry-free retirement where you can enjoy the fruits of your<br>hard work.',
		                 '期望退休後亦可享受現有的生活質素，單靠強積金<br>作退休儲備並不足夠。所以退休計劃最重要是可助您<br>實現無憂的退休生活。'],
		
		retirement_end:['',''],
		retirement_end_subject:['',''],
		retirement_end_body:['Thank you for the information, please swipe to view your Financial Needs Analysis Report.','感謝您的資料，請向上滑動來參閱您的財務需要分析報告。'],
		
		
		
		retirement_now:['Need to consider Retirement for now?','需要考慮退休計劃？'], //Changed
		target_retirement_age : ['Target Retirement Age','目標退休年齡'],
		ideal_retirement_style : ['Ideal Retirement Lifestyle','理想退休生活模式'],
		expected_retirement_expenses : ['Expected Retirement Expenses','預計退休開支'],
		economy : ['Ordinary','經濟型'],
		ordinary : ['Ordinary','經濟型'],
		indulgent : ['Superior','無憂型'],
		superior : ['Superior','無憂型'],
		luxurious : ['Luxurious','豐盛型'],
		expected_years_of_retirement : ['Expected Years of Retirement','預計退休年期'],
		expect_years_of_retirement : ['Expected Years of Retirement','預計退休年期'],
		mpf_monthly_contribution : ['MPF Monthly Contribution','每月強積金供款'],
		//section5_remark : ['All financial amount are presented in HKD.','所有財務金額將以港幣表示。'],
		
		/* Section 5 */
		education : ['EDUCATION','教育'],
		education_subject: ['CONSIDER FUNDING FOR YOUR KIDS\' EDUCATION?','想為子女成立教育基金?'],
		education_body : ['Let children have a bright and successful future is always the dream of<br>parents. However, children education and living expenses keep<br>increasing year by year, do you ensure you can still take care of those<br>expenses in the future?',
		                 '讓子女擁有一個光明和成功的未來永遠是父母的夢想。<br>然而，孩子的學費及生活費用每年增加，您是否<br>仍然確保可以應付這些未來開支？'],
		
		education_end:['',''],
		education_end_subject: ['',''],
		education_end_body : ['Thank you for the information, please swipe to view your Financial Needs Analysis Report.','感謝您的資料，請向上滑動來參閱您的財務需要分析報告。'],
		education_now : ['Need to consider Education for now?','需要考慮子女的教育基金？'], //Added
		/* Child */
		child_age : ['Children Age','子女年齡'],
		child_age_to_enter_university : ['Children at University Entry Age','子女升讀大學年齡'],
		child_expected_years_of_studying : ['Expected Years of Study','預計升學年期'],
		child_country_of_studying : ['Country for Studying','升學地區'],
		child_expenses_per_year : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'],
		manual_total_expense_per_year : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'], //Added
		
		child1 : ['The first child','第一位子女'],
		child1_age : ['Children Age','子女年齡'],
		child1_age_to_enter_university : ['Children Age at University Entry','子女升讀大學年齡'],
		child1_expected_years_of_studying : ['Expected Years of Study','預計升學年期'],
		child1_country_of_studying : ['Country for Studying','升學地區'],
		child1_expenses_per_year : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'],
		child1_manual_total_expense : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'], //Added
		child1_gap : ['Gap','差距'],
		
		child2 : ['The second child','第二位子女'],
		child2_age : ['Children Age','子女年齡'],
		child2_age_to_enter_university : ['Children at University Entry Age','子女升讀大學年齡'],
		child2_expected_years_of_studying : ['Expected Years of Study','預計升學年期'],
		child2_country_of_studying : ['Country for Studying','升學地區'],
		child2_expenses_per_year : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'],
		child2_manual_total_expense : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'], //Added
		child2_gap : ['Gap','差距'],
		
		child3 : ['The third child','第三位子女'],
		child3_age : ['Children Age','子女年齡'],
		child3_age_to_enter_university : ['Children at University Entry Age','子女升讀大學年齡'],
		child3_expected_years_of_studying : ['Expected Years of Study','預計升學年期'],
		child3_country_of_studying : ['Country for Studying','升學地區'],
		child3_expenses_per_year : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'],
		child3_manual_total_expense : ['Annual Education & Living Expenses (PV)','預期每年學費及生活費 (以現值計)'], //Added
		child3_gap : ['Gap','差距'],
		
		child_have_better_guess : ['Est. Annual Expenses for Selected Country','估計升學國家的每年總開支'],
		child_education_fund : ['Existing Education Fund','現有教育基金'],
		education_fund : ['Existing Education Fund','現有教育基金'],
		child_consider_1 : ['Need to consider for the first child?','需要考慮第一位子女的教育基金？'], //Added
		child_consider_2 : ['Need to consider for the second child?','需要考慮第二位子女的教育基金？'], //Added
		child_consider_3 : ['Need to consider for the third child?','需要考慮第三位子女的教育基金？'], //Added
		//section6_remark : ['All financial amount are presented in HKD.','所有財務金額將以港幣表示。'],
		
		/* Section 8 */
		result : ['RESULT','結果'],
		overview : ['OVERVIEW','概覽'],
		total_financial_needs : ['Total Financial Needs','總財務需要'],
		total_financial_need : ['Total Financial Needs','總財務需要'],
		// liquid_assets : ['Liquid assets','流動資產'], //Changed // Duplicate key
		current_critical_illness_protection : ['Current CI Protection', '現時危疾保障'],
		mpf : ['MPF','強積金'],
		current_education : ['Current Education Fund','現有教育基金'], //Changed
		
		life_protection : ['LIFE PROTECTION','人壽保障'],
		life_protection_need : ['Life Protection Need','人壽保障需要'],
		// liquid_assets : ['Liquid assets','流動資產'], //Changed // Duplicate key
		current_life_protection : ['Current Life Protection','現時人壽保障'],
		current_life_ci_protection : ['Current Life Protection','現時人壽保障'],
		// protection_gap : ['Protection Gap','保障差距'], // Duplicate key
		critical_illness_protection_need : ['Critical Illness Protection Need', '危疾保障需要'],
		critical_illness_protection : ['Critical Illness Protection', '危疾保障'],
		ci_protection_need : ['Critical Illness Protection Need', '危疾保障需要'],
		// current_critical_illness_protection : ['Current Critical Illness Protection', '現時危疾保障'], //Changed // Duplicate key
		current_ci_protection : ['Current CI Protection', '現時危疾保障'], //Changed
		protection_gap : ['Protection Gap','保障差距'], //Changed
		
		// retirement : ['RETIREMENT','退休'], //Changed // Duplicate key
		required_retirement : ['Required Retirement Fund','所需退休基金'],
		required_fund : ['Required Retirement Fund','所需退休基金'],
		// mpf : ['MPF','強積金'], //Changed // Duplicate key
		gap : ['Gap','差距'],
		required_monthly_saving : ['Required Monthly Saving','所需每月儲蓄'],
		total_monthly_spending : ['Total Monthly Spending','每月總開支'],
	
		// education : ['EDUCATION','教育'], //Changed // Duplicate key
		child : ['Child','子女'],
		child_with_age : ['Child (Age %s1)','子女 (年齡 %s1)'],
		// age : ['Age','年齡'], //Changed // Duplicate key
		required_education_fund : ['Required Education Fund','所需教育基金'],
		current_education_fund : ['Current Education Fund','現有教育基金'],
		// gap : ['Gap','差距'], //Changed // Duplicate key
		// required_monthly_saving : ['Required Monthly Saving','所需每月儲蓄'], //Changed // Duplicate key
		year_of_saving : ['Year of Saving','儲蓄年期'],
		suggestions : ['SUGGESTIONS','建議'],
		basic_plus: ['Basic Plus', '好息簡理財壽險計劃'],
		easy_defender_critical_illness_insurance_series: ['Easy Defender Critical Illness Insurance Series', '好安守危疾保障系列'],

		total_required_education_fund: ['Total Required Education Fund', '所需教育基金'],
		total_gap: ['Total Gap', '差距'],
		
		total_required_fund : ['Total Required Fund','合計所需基金'],
		//section8_remark : ['All financial amount are presented in HKD.','所有財務金額將以港幣表示。'],
		
		/* 8.1 Email FNA Report Form */
		send_you_result : ['WE\'LL SEND YOU THE RESULT','我們會將結果電郵給您'],
		section81_intro : ['If you want to receive your financial analysis result via email. Please enter your email address below.','如果您希望透過電子郵件收取您的財務分析結果。請在此輸入您的電子郵件地址。'],
		name : ['Name','姓名'],
		email_address : ['Email Address','電郵地址'],
		send : ['Send','寄出'],
		
		/* 8.2 FNA Report */ //Added
		fna_report : ['Financial Needs Analysis Report','財務需要分析報告'],
		report_overview : ['OVERVIEW','概覽'],
		customer : ['Customer','客戶'],
		advisor : ['Advisor','顧問'],
		date : ['Date','日期'],
		confidential : ['CONFIDENTIAL','保密文件'],
		report_disclaimer : ['Disclaimer','免責聲明'],
		report_disclaimer_text : ['Disclaimer text','Disclaimer text'],
		copyright : [''],
		financial_needs_analysis_summary : ['Financial Needs Analysis Summary','財務需要分析概要'],
		financial_needs_analysis_result : ['Financial Needs Analysis Result','財務需要分析結果'],
		page : ['Page #','第＃頁'],
		your_total_financial_needs : ['Your Total Financial Need','總財務需要'],
		our_recommended_products : ['Our Recommended Products','產品建議'],
		
		report_information : ['Information','個人資料'],
		report_finance : ['Finance','財務狀況'],
		report_protection : ['Protection','保障'],
		report_life_protection : ['Life Protection','人壽保障'],
		report_critical_illness_protection : ['Critical Illness Protection', '危疾保障'],
		report_retirement : ['Retirement','退休'],
		report_education : ['Education','教育'],

		report_life_protection_need : ['Life Protection Need (A)','人壽保障需要 (A)'],
		report_liquid_assets : ['Liquid Assets (B)','流動資產 (B)'],
		report_current_life_protection : ['Current Life Protection (C)','現時人壽保障 (C)'],
		report_protection_gap : ['Protection Gap (A-B-C)','保障差距 (A-B-C)'],
		report_critical_illness_protection_need : ['Critical Illness Protection Need (A)', '危疾保障需要 (A)'],
		report_current_critical_illness_protection : ['Current CI Protection (B)', '現時危疾保障 (B)'],
		report_ci_protection_gap : ['Protection Gap (A-B)','保障差距 (A-B)'],
		report_required_retirement : ['Required Retirement Fund (A)','所需退休基金 (A)'],
		report_mpf : ['MPF (B)','強積金 (B)'],
		report_retirement_protection_gap : ['Gap (A-B)','差距 (A-B)'],

		report_required_education_fund : ['Required Education Fund (A)','所需教育基金 (A)'],
		report_current_education : ['Current Education Fund (B)','現有教育基金 (B)'],
		report_education_protection_gap : ['Gap (A-B)','差距 (A-B)'],
		

		report_total_financial_needs : ['Total Financial Needs (A)','總財務需要 (A)'],
		report_total_liquid_assets : ['Liquid Assets (B)','流動資產 (B)'],
		report_total_current_life_protection : ['Current Life Protection (C)','現時人壽保障 (C)'],
		report_total_current_critical_illness_protection : ['Current CI Protection (D)', '現時危疾保障 (D)'],
		report_total_mpf : ['MPF (E)','強積金 (E)'],
		report_total_education_fund : ['Education Fund %s1','教育基金 %s1'],
		report_total_gap : ['Gap (A-B-C-D%s1)','差距 (A-B-C-D%s1)'],
		
		/* Disclaimer */
		disclaimer : ['Disclaimer','免責聲明'],
		disclaimer_link : ['../pages/en/disclaimer.html','../pages/zh/disclaimer.html'],
		
		/* Privacy Ordinance */
		privacy_ordinance : ['Personal Data Protection Policy and Practices', '個人資料保護政策及執行'], //Changed
		privacy_ordinance_link : ['http://www.c2lbiz.com/en-US/home/pdo.html','http://www.c2lbiz.com/zh-HK/home/pdo.html'],
		
		/* Online Security */
		online_security : ['Online Security', '網上保安'],
		online_security_link : ['../pages/en/online-security.html','../pages/zh/online-security.html'],
		
		/* Share */
		next : ['NEXT','下一頁'],
		prev : ['PREV','上一頁'],
		reset : ['RESET','重設'],
		modify : ['MODIFY','修改'],
		submit : ['SUBMIT','提交'],
		ok : ['OK','確定'],
		yes : ['YES','是'],
		no : ['NO', '否'],
		cancel : ['CANCEL','取消'],
		notes : ['NOTES','提示'],
		hkd : [' ',''],
		email : ['EMAIL','電郵'],
		
		hong_kong : ['HKG', '香港'],
		uk : ['UK', '英國'],
		usa : ['USA', '美國'],
		canada : ['CAN', '加拿大'],
		australia : ['AUS', '澳洲'],
		new_zealand : ['NZL', '新西蘭'],
		switzerland : ['SWZ', 'SWZ'],
		china : ['CHN', '中國'],
		other : ['Others','其它'],
		others : ['Others','其它'],
		unit_empty:['',''],

		/* Validator */
		selected_value_not_in_range : ['Selected value not in range', 'Selected value not in range'],
		selected_value_not_in_list : ['Selected value not in list', 'Selected value not in range'],
		all_fields_must_be_filled : ['All fields must be filled.', '所有空格必須填寫。'],
			
		/* Number Input Field */
		number_input_ok : ['OK', 'OK'],
		number_input_back : ['x', 'x'],
				
		/* Error Message */ //Added

		reset_section1 : ['Do you want to reset the data for Information section?','重設個人資料的資料?'],
		reset_section2 : ['Do you want to reset the data for Finance section?','重設財務狀況的資料?'],
		reset_section3 : ['Do you want to reset the data for Protection section?','重設保障的資料?'],
		reset_section4 : ['Do you want to reset the data for Retirement section?','重設退休的資料?'],
		reset_section5 : ['Do you want to reset the data for Education section?','重設教育的資料?'],
		
		no_internet_connection : ['No Internet connection. Please check the Internet connection and retry.','沒有互聯網連接。請檢查網絡連接及重試。'],
		
		/* Email form Message */
		name_valid : ["Please enter your name", "請輸入您的姓名"],
		email_valid : ["Please enter a valid email", "請輸入一個有效的電子郵件"],
		agree_tnc : ["Please agree Terms and Conditions", "請同意條款及細則"],
		
		
	}
};