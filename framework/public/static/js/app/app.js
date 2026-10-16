console.log("app.js");

/**
 * Define App namespace and properties
 * Application start from router.js
 */
var App = {
	
	/* We're using backbone framework */
	Router: 		{}, // application start from here: router.js
	Model:			{}, // model.js
	Collection: 	{}, // collection.js
	View:			{}, // view/*.js
	Validator: 		{}, // validator.js
	i18n:			{}, // i18n.js
	Template:		{}, // template.js
	Result:			{}, // result.js
	
	/* App config data */
	mainAppConfig	: {},	// config file get from cal.js
	viewHeight		: 0, 	// viewable height of app
	viewWidth		: 0,	
	barHeight		: 0,	// top and bottom bars height
	dataPanelBottom	: 0,	// bottom position of data panel
	primaryColor	: '#ef6912', // should sync with _setting.scss
	secondaryColor	: '#de130b', // should sync with _setting.scss
	language		: '',	// app language
	imagePath		: '/public/static/skin/images/',
	click			: ('ontouchstart' in document.documentElement) ? 'touchend' : 'mouseup', // convert 'click' to 'touchstart' event in touch devices
	mousedown		: ('ontouchstart' in document.documentElement) ? 'touchstart' : 'mousedown'
};