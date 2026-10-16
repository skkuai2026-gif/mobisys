console.log("footer.js");

$(function() {
	
	console.log("footer init");
	
	// Footer code
	$('#footer-link').html('\
					<a class="shadowbox-link" href="'+App.i18n.prop('online_security_link')+'">'+App.i18n.prop('online_security')+'</a>\
					<a class="shadowbox-link" href="'+App.i18n.prop('disclaimer_link')+'">'+App.i18n.prop('disclaimer')+'</a>\
					');
	$('#footer-link a.shadowbox-link').on('click', function(event){
		
		// Doesn't create double scroll bars in popup iframe
		//if (navigator.userAgent.match(/(iPod|iPhone|iPad)/)) {
//	        $('#sb-body-inner').css({
//	            'overflow': 'scroll', 
//	            '-webkit-overflow-scrolling': 'touch' 
//	        }); 
	    //}
		Cal.openResource($(this).attr('href'), true);
		Tracking.trackEvent('FNA-'+App.language+'/'+$(this).text(), 'Click', $(this).text(), '');		
		event.preventDefault();
	});
					
	if(App.mainAppConfig['fwd_logo']!="undefined"){
		$('#footer-fwd-icon').html('<img src="'+App.mainAppConfig['fwd_logo']+'" />');
	}else{
		$('#footer-fwd-icon').html('<img src="/public/static/skin/images/share/logos/fwd.png" />');
	}
	if(App.mainAppConfig['partner_logo']!="undefined" && App.mainAppConfig['partner_logo']!=""){
		$('#footer-partner-icon').html('<img src="'+App.mainAppConfig['partner_logo']+'" />');
	}else{
		$('#footer-partner-icon').hide();
	}

});