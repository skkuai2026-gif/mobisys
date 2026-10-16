(function( $, undefined ) {

$.fn.dualfieldcontain = function( options ) {
  return this.addClass( "ui-dual-field-contain ui-body ui-br" );
};

//auto self-init widgets
$( document ).bind( "pagecreate create", function( e ){
  $( ":jqmData(role='dualfieldcontain')", e.target ).dualfieldcontain();
});

function pageIsSelectmenuDialog( page ) {
    var isDialog = false,
        id = page && page.attr( "id" );
    $( ".filterable-select" ).each( function() {
        if ( $( this ).attr( "id" ) + "-dialog" === id ) {
            isDialog = true;
            return false;
        }
    });
    return isDialog;
}
$.mobile.document
    
    .on( "selectmenucreate", ".filterable-select", function( event ) {
        var input,
            selectmenu = $( event.target ),
            list = $( "[id='" + selectmenu.attr( "id" ) + "-menu']"),
            form = list.jqmData( "filter-form" );
        
        if ( !form ) {
            input = $( "<input data-type='search'></input>" );
            form = $( "<form></form>" ).append( input );
            input.textinput();
            list
                .before( form )
                .jqmData( "filter-form", form ) ;
            form.jqmData( "listview", list );
        }
        
        selectmenu
            .filterable({
                input: input,
                children: "> option[value]"
            })
            .on( "filterablefilter", function() {
                selectmenu.selectmenu( "refresh" );
            });
        $( "ul[id='" + selectmenu.attr( "id" ) + "-menu'] li").eq(1).removeClass('ui-first-child');
        $( "ul[id='" + selectmenu.attr( "id" ) + "-menu'] li").eq(-1).removeClass('ui-last-child');
    });

})( jQuery );