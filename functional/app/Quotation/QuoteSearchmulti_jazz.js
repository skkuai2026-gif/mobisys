$(document).ready(function(){

    $('#generateIllustrationButton').hide();
    $('#generatePdfButton').hide();
    $('#cancelButton').hide();
    $('.illustration-checkbox').hide();

    $('#showIllustrationPanel').click(function () {
        $('#generateIllustrationButton').show();
        $('#cancelButton').show();
        $('.icon-action').hide();
        $('.illustration-checkbox').show();
        $(this).hide();
        $('#showPdfPanel').hide();
    });

    $('#showPdfPanel').click(function () {
        $('#generatePdfButton').show();
        $('#cancelButton').show();
        $('.icon-action').hide();
        $('.illustration-checkbox').show();
        $(this).hide();
        $('#showIllustrationPanel').hide();
    });

    $('#cancelButton').click(function() {
        $('#generateIllustrationButton').hide();
        $('#generatePdfButton').hide();
        $('#cancelButton').hide();
        $('.illustrationCheckPanel').hide();
        $(this).hide();
        $('#showIllustrationPanel').show();
        $('#showPdfPanel').show();
        $("input:checkbox[name='illustrationCheck[]']:checked").prop("checked", false).checkboxradio('refresh');
        $('.illustration-checkbox').hide();
        $('.icon-action').show();
        
    });
    
    $('#generateIllustrationButton').click(function() {
        if($("input:checkbox[name='illustrationCheck[]']:checked").length > 0) {
            labelKeys = 'ok|cancel';
            generate_confirmation = 'GENERATE_CONFIRMATION';
            quotation = 'QUOTATION';
            var labelValues = getLabelValues(labelKeys);
            var yes = labelValues.Yes;
            var no = labelValues.No;
            var del_conf_msg = getLabelValue(generate_confirmation,quotation);

            $('<div>').simpledialog2({
                mode: 'button',
                style: "width: 629px",
                buttonPrompt: del_conf_msg,
                buttons : {
                    ok: {
                        click: function () {
                            document.Search.action = "getIllustrationOptions";
                            
                            document.Search.submit();
                        }
                    },
                    cancel: {
                        click: function () { 
                        },
                        icon: "delete",
                        theme: "c"
                    }
                }
            });
        }
    });
    $('#generatePdfButton').click(function() {
        if($("input:checkbox[name='illustrationCheck[]']:checked").length > 0) {
            labelKeys = 'ok|cancel';
            generate_confirmation = 'GENERATE_CONFIRMATION';
            var labelValues = getLabelValues(labelKeys);
            var yes = labelValues.Yes;
            var no = labelValues.No;
            var del_conf_msg = getLabelValue(generate_confirmation,"QUOTATION");

            $('<div>').simpledialog2({
                mode: 'button',
                style: "width: 629px",
                buttonPrompt: del_conf_msg,
                buttons : {
                    ok: {
                        click: function () {
                            document.Search.action = "generatePdfs";
                            document.Search.submit();
                        }
                    },
                    cancel: {
                        click: function () { 
                        },
                        icon: "delete",
                        theme: "c"
                    }
                }
            });
        }
    });


    $('input[type=text]').keypress(function (e) {
        if (e.which == 13) {
            $('#illustrationCheckForm').submit();
            return false;
        }
    });

    $('input[type=text]').change(function(){
        $('#illustrationCheckForm').submit();
    });

    $('select').change(function(){
        $('#illustrationCheckForm').submit();

    });

    $('#quotationDt').click(function(){
        captureDate('Enter date', 'quotationDt');
    });
    
});