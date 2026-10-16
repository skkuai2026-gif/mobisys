(function( $, undefined ) {

$.fn.dualfieldcontain = function( options ) {
  return this.addClass( "ui-dual-field-contain ui-body ui-br" );
};

//auto self-init widgets
$( document ).bind( "pagecreate create", function( e ){
  $( ":jqmData(role='dualfieldcontain')", e.target ).dualfieldcontain();
});

})( jQuery );
