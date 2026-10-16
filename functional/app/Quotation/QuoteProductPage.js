var leadid = "";
var rpqid = "";
var isUAT = false;
function filterProduct(productFamilyCd, productFamilyDesc){
    offlineApplicationEnvironment = $('#offline_application_environment').val();
    $.ajax({
        url: "/app/Quotation/filterProduct",
        data: {'productFamilyCd':productFamilyCd,'productFamilyDesc':productFamilyDesc, 'offlineApplicationEnvironment':offlineApplicationEnvironment},
        headers: {
            'Transition-Enabled': false
        },
        success: function(data){
            $(".product_list").html(data);
            $(".product_list").trigger('create');

            $(".product-name-wrapper input").on( "click",function(){
                $(".plan-option-wrapper .plan_list").css("display","none");
                $(".product-page-col-4 .version_list").css("display","none");

                $(".plan-option-wrapper .plan_list").empty();
                $(".product-page-col-4 .version_list").empty();

                if (isUAT)
                {
                    $( "#gobutton" ).off( "click", nextfunction );
                    $( "#gobutton" ).css( "opacity", 0.5 );
                    $(".plan-option-wrapper").animate({'left': '50%'},500);
                    setTimeout(function(){
                    $(".plan-option-wrapper .plan_list").css("display","block");},500)
                    $('.product_selection').change(function(){
                        filterProductVersion($(this).val(),$(this).attr('data-label'));
                    });
                }
                else
                {
                    $(".plan-option-wrapper").animate({'left': '66.66%'},500);
                    setTimeout(function(){
                    $(".plan-option-wrapper .plan_list").css("display","block");},500)
                    $('.product_selection').change(function(){
                        filterProductPlan($(this).val(),$(this).attr('data-label'));
                    });
                }
            });
        }
    });
}

function filterProductPlan (productId,productIdDesc) 
{
    productFamily = $("input[name='family_radio']:checked").val();
    $.ajax({
        url: "/app/Quotation/filterPlanOptionCodes",
        data: {
            'productId':productId, 
            'productFamily':productFamily,
            'productIdDesc':productIdDesc
        },
        headers: {
            'Transition-Enabled': false
        },
        success: function(data){
            data_values = data.split("-|-");
            productSeq = data_values[0].trim();
            $('input[name="productSeq"]').val(productSeq);
            $(".plan_list").html(data_values[1]);
            $(".plan_list").trigger('create');

            $( "#gobutton" ).off("click", nextfunction).on( "click", nextfunction );   // code to enable next button
            $( "#gobutton" ).css( "opacity", 1.0 );
        }
    });
}

function filterProductVersion(productId,productIdDesc)
{
    $.ajax({
        url: "/app/Quotation/filterProductVersion",
        data: {'productId':productId,'productIdDesc':productIdDesc},
        headers: {
            'Transition-Enabled': false
        },
        success: function(data){
            $(".plan_list").html(data);
            $(".plan_list").trigger('create');
            $(".plan-option-wrapper input").on( "click",function(){
                $(".product-page-col-4 .version_list").css("display","none");
                $(".product-page-col-4 .version_list").empty();

                $(".product-page-col-4").animate({'left': '75%'},500);
                setTimeout(function(){
                $(".product-page-col-4 .version_list").css("display","block");},500)
                $('.version_selection').change(function(){
                    filterPlanOptionOnProductVersionSelection($(this).val());
                });
            });
        }
    });
}

function filterPlanOptionOnProductVersionSelection(productVersion)
{
    productId = $("input[name='product_radio']:checked").val();
    productIdDesc = $("input[name='product_radio']:checked").attr('data-label');
    $.ajax({
        url: "/app/Quotation/filterPlanOptionOnProductVersionSelection",
        data: {'productId':productId,'productVersion':productVersion,'productIdDesc':productIdDesc},
        headers: {
            'Transition-Enabled': false
        },
        success: function(data){
            data_values = data.split("-|-");
            productSeq = data_values[0].trim();
            $('input[name="productSeq"]').val(productSeq);
            $(".version_list").html(data_values[1]);
            $(".version_list").trigger('create');

            $( "#gobutton" ).off("click", nextfunction).on( "click", nextfunction );   // code to enable next button
            $( "#gobutton" ).css( "opacity", 1.0 );
        }
    });
}

$(document).ready(function(){
  $( "#gobutton" ).off( "click", nextfunction );
  $( "#gobutton" ).css( "opacity", 0.5 );

  leadid = getURLParameter("leadid");
  rpqid = getURLParameter("rpqid");

  if ($("#offline_application_environment").val() == "UAT")
  {
    isUAT = true;
  }

    $(".product-family-wrapper input").on( "click",function(){
      $( "#gobutton" ).off( "click", nextfunction );
      $( "#gobutton" ).css( "opacity", 0.5 );

      $(".plan-option-wrapper .plan_list").css("display","none");
      $(".product-name-wrapper .product_list").css("display","none");
      $(".product-page-col-4 .version_list").css("display","none");

      $(".plan-option-wrapper .plan_list").empty();
      $(".product-name-wrapper .product_list").empty();
      $(".product-page-col-4 .version_list").empty();
    
      if (isUAT)
      {
        $(".product-name-wrapper").animate({'left': '25%'},500);
      }
      else
      {
        $(".product-name-wrapper").animate({'left': '33.33%'},500);
      }
      setTimeout(function(){
      $(".product-name-wrapper .product_list").css("display","block");
        },500)
    });

    $('.family_selection').change(function(){
        filterProduct($(this).val(), $(this).attr('data-label'));
    });
});

function getURLParameter(name) {
  return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [null, ''])[1].replace(/\+/g, '%20')) || "";
}

function nextfunction()
{
    productFamily = $("input[name='family_radio']:checked").val();
    productId = $("input[name='product_radio']:checked").val();
    productSeq = $("input[name='productSeq']").val();
    productPlanOptionCd = $("input[name='plan_radio']:checked").val();
    options = $("input[id='plan_name']").length;
    productVersion = ""
    if (isUAT)
    {
        productVersion = $("input[name='version_radio']:checked").val();
    }

    if ((productId) && (productFamily))
    {
        if ((options > 0) && (productPlanOptionCd))
        {
            if (isUAT)
            {
                if (productVersion)
                {
                    location.href='/app/Quotation/newCaptureIllustration?productFamily='+productFamily+'&productId='+productId+'&productSeq='+productSeq+'&productVersion='+productVersion+'&productPlanOptionCd='+productPlanOptionCd+'&leadid='+leadid+'&rpqid='+rpqid; 
                }
                else
                {
                    // alert("Please select Product Version");
                    raiseAlert("ERR_PLZSELECT",[],locale);
                }
            }
            else
            {
                location.href='/app/Quotation/newCaptureIllustration?productFamily='+productFamily+'&productId='+productId+'&productSeq='+productSeq+'&productPlanOptionCd='+productPlanOptionCd+'&leadid='+leadid+'&rpqid='+rpqid;
            }
        }
        else if (options <= 0)
        {
            productPlanOptionCd = "";
            if (isUAT)
            {
                if (productVersion)
                {
                    location.href='/app/Quotation/newCaptureIllustration?productFamily='+productFamily+'&productId='+productId+'&productSeq='+productSeq+'&productVersion='+productVersion+'&productPlanOptionCd='+productPlanOptionCd+'&leadid='+leadid+'&rpqid='+rpqid; 
                }
                else
                {
                    // alert("Please select Product Version");
                    raiseAlert("ERR_PLZSELECT",[],locale);
                }
            }
            else
            {
                location.href='/app/Quotation/newCaptureIllustration?productFamily='+productFamily+'&productId='+productId+'&productSeq='+productSeq+'&productPlanOptionCd='+productPlanOptionCd+'&leadid='+leadid+'&rpqid='+rpqid;
            }
        }
        else
        {
            // alert("Please select Plan Option");
            raiseAlert("ERR_PLZSELECT",[getLabel("planOptionCd",locale)],locale);
        }
    }
    else if (productFamily)
    {
        // alert("Please select Product");
        raiseAlert("PLEASE_SELECT_PRODUCT",[],locale);
    }
    else  
    {
        // alert("Please select Product Family");
        raiseAlert("PLEASE_SELECT_PRODUCT_FAMILY",[],locale);
    }
}