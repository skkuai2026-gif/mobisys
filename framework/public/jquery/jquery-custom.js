( function( $ ) {
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
            list = $( "#" + selectmenu.attr( "id" ) + "-menu" ),
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
        if($("select[id='" + selectmenu.attr( "id" ) + "']").val() == ''){
            var defaultvalue = $( "ul[id='" + selectmenu.attr( "id" ) + "-menu'] li").eq(1).find('a').html();
            $( "a[id='" + selectmenu.attr( "id" ) + "-button'] span").html(defaultvalue).trigger('refresh');
        }
    });
    
})( jQuery );