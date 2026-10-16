// arrays for chart1
var lead = [1,2,3,4,5,6,7,8,9,10,11,12];
var FNA = [12,11,10,9,8,7,6,5,4,3,2,1];
var RPQ = [1,2,3,4,5,6,7,8,9,10,11,12];
var SI = [12,11,10,9,8,7,6,5,4,3,2,1];
var eApp = [1,2,3,4,5,6,7,8,9,10,11,12];
var chart1label = ["Lead", "FNA", "RPQ", "SI", "eApp"];


// arrays for chart2
var P1 = [12,11,10,9,8,7,6,5,4,3,2,1];
var P2 = [1,2,3,4,5,6,7,8,9,10,11,12];
var P3 = [1,2,3,4,5,6,7,8,9,10,11,12];
var P4 = [1,2,3,4,5,6,7,8,9,10,11,12];
var P5 = [12,11,10,9,8,7,6,5,4,3,2,1];
var chart2label = ["P1", "P2", "P3", "P4", "P5"];


// arrays for chart1
var eApp1 = [1,2,3,4,5,6,7,8,9,10,11,12];
var eApp2 = [12,11,10,9,8,7,6,5,4,3,2,1];
var eApp3 = [12,11,10,9,8,7,6,5,4,3,2,1];
var eApp4 = [12,11,10,9,8,7,6,5,4,3,2,1];
var eApp5 = [1,2,3,4,5,6,7,8,9,10,11,12];
var chart3label = ["P1", "P2", "P3", "P4", "P5"];


// default canvas and chart
id = "cvs1";
array1 = lead;
array2 = FNA;
array3 = RPQ;
array4 = SI;
array5 = eApp;
labels_array = chart1label;


$(document).ready(function() {
    if($('#leadStage').val() == "") {
        $('#newlead').addClass('active');
    }
    else {
        $('#'+ $('#leadStage').val()).addClass('active');
    }

    if($('#leadStage').val() == "searchLead"){
        $(".advance-search-btn").show();
        $(".ui-input-search").parents(".search-top-bg").show();
    }
    else {
        $(".ui-input-search").parents(".search-top-bg").hide();
        $(".advance-search-field").hide();
        $(".advance-search-btn").hide();
    }

    rangeChange();
    $("input[name='searchcriteria']").keypress(function(event) {
        if(event.which==13){
            event.preventDefault();
            document.landingSubmit.submit();
        }
    });

    $('tr td b p[id="SearchTrackLeadDO_fnaId_lbl"]').each(function () {
        var innerHtml = $(this).parents('td').html();
        innerHtml = innerHtml.replace(innerHtml.substring(innerHtml.indexOf('<b'), innerHtml.indexOf('</b>')+37),"");
        if(innerHtml==""){
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="showFNA"]').parent().hide();
        }
    });

    $('tr td b p[id="SearchTrackLeadDO_quotationRefNum_lbl"]').each(function () {
        var innerHtml = $(this).parents('td').html();
        innerHtml = innerHtml.replace(innerHtml.substring(innerHtml.indexOf('<b'), innerHtml.indexOf('</b>')+37),"");
        if(innerHtml==""){
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="showQuotation"]').parent().hide();
        }
    });

    $('tr td b p[id="SearchTrackLeadDO_proposalNum_lbl"]').each(function () {
        var innerHtml = $(this).parents('td').html();
        innerHtml = innerHtml.replace(innerHtml.substring(innerHtml.indexOf('<b'), innerHtml.indexOf('</b>')+37),"");
        if(innerHtml==""){
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="showProposal"]').parent().hide();
        }
    });

    $('tr td b p[id="SearchTrackLeadDO_quotationRefNum_lbl"]').each(function () {
        $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="addProposal"]').parent().hide();
        var innerHtml = $(this).parents('td').html();
        innerHtml = innerHtml.replace(innerHtml.substring(innerHtml.indexOf('<b'), innerHtml.indexOf('</b>')+37),"");

        var innerHtmlStatusCd = $(this).parents('tr').find('b p[id="SearchTrackLeadDO_statusCd_lbl"]').parents('td').html();
        innerHtmlStatusCd = innerHtmlStatusCd.replace(innerHtmlStatusCd.substring(innerHtmlStatusCd.indexOf('<b'), innerHtmlStatusCd.indexOf('</b>')+37),"");

        if(innerHtml!="" && innerHtmlStatusCd == getLabel('ACCEPTED',locale)){
            $(this).parents('tr').find('.action-toggle-bg .action-status-show a[href*="addProposal"]').parent().show();
        }
    });

});


function rangeChange()
{
    leftend = parseInt($('input[name="slider-1"]').val());
    rightend = parseInt($('input[name="slider-2"]').val());
    sum1 = 0;
    sum2 = 0;
    sum3 = 0;
    sum4 = 0;
    sum5 = 0;
    for(i = leftend; i <= rightend; i++)
    {
        sum1 = sum1 + array1[i];
        sum2 = sum2 + array2[i];
        sum3 = sum3 + array3[i];
        sum4 = sum4 + array4[i];
        sum5 = sum5 + array5[i];
    }
    array_to_pass = [sum1,sum2,sum3,sum4,sum5];
    drawgraph(id,array_to_pass,labels_array);
}


function tabChange(canvasname) {
    $("#chart1").hide();
    $("#chart2").hide();
    $("#chart3").hide();
    id = canvasname;
    if (canvasname == "cvs1") {
        array1 = lead;
        array2 = FNA;
        array3 = RPQ;
        array4 = SI;
        array5 = eApp;
        labels_array = chart1label;
        $("#chart1").show();

    }
    else if (canvasname == "cvs2") {
        array1 = P1;
        array2 = P2;
        array3 = P3;
        array4 = P4;
        array5 = P5;
        labels_array = chart2label;
        $("#chart2").show();
    }
    else if (canvasname == "cvs3") {
        array1 = eApp1;
        array2 = eApp2;
        array3 = eApp3;
        array4 = eApp4;
        array5 = eApp5;
        labels_array = chart3label;
        $("#chart3").show();
    }
    rangeChange();
}


function drawgraph(id, array, labels_array) {
    RGraph.ObjectRegistry.Clear('cvs1');
    RGraph.ObjectRegistry.Clear('cvs2');
    RGraph.ObjectRegistry.Clear('cvs3');
    RGraph.Redraw();
    var bar = new RGraph.Bar(id, array)
    bar.Set('chart.colors.sequential', true);
    bar.Set('chart.colors', ["#4286f4", "#efef67", "#e06dd3", "#926df2", "#92fc92"]);
    bar.Set('chart.xaxis.labels', labels_array);
    bar.Set('chart.axes.color', '#542314');
    bar.Set('chart.text.color', '#542314');
    bar.Set('chart.background.grid', false);
    bar.Set('chart.hmargin', 10);
    // bar.Set('units.post', 5);
    bar.Draw();
}

function setStageAndSubmit(stage)
{   var currentTab;
    switch(stage){
        case 'newlead':
            currentTab = "NEWLEAD";
            break;
        case 'fna':
            currentTab = "LEADATFNASTAGE";
            break;
        case 'si':
            currentTab = "LEADATSISTAGE";
            break;
        case 'eapp':
            currentTab = "LEADATEAPPSTAGE";
            break;
        case 'searchLead':
            currentTab = "LEADSEARCH";
            break;
    }
    $("#currentTab").val(currentTab);
    $('#leadStage').val(stage);
    document.landingSubmit.submit();
}

$("#searchcriteria").on("keyup", function() {
    var value = $(this).val().toLowerCase();
    $("#searchTable tr").filter(function() {
        $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
    });
});

