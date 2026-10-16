console.log("tracking.js");

Tracking = {};

Tracking.trackPageview = function(uri) {
	console.log('trackPageview', uri);
};

Tracking.trackEvent = function(category, action, label, value) {
	console.log('trackEvent', category, action, label, value);
};
