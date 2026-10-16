function sendemail() {
    //if( checkForm() && checkNetwork()){
    if( checkForm() ){
        document.emailForm.submit();                    
        $("a[name='email']").attr('onclick', 'return false;');
        $("a[name='print']").attr('onclick', 'return false;');
        loading('show');
    }        
}
function sendview() {
    document.viewForm.submit();                    
    $("a[name='view']").attr('onclick', 'return false;');        
    loading('show');
}
function checkNetwork(){
    returnValue = false;        
    $.ajax({
        url: "/app/Quotation/checkNetwork",
        success: function(data) {
            data = data.replace("<div>","");
            data = data.replace("</div>","");
            try{
                if (data == "NETWORK")
                {
                    returnValue = true;
                }
                else
                {
                    returnValue = false;
                }
            }catch(e){raiseAlert(e);}
        },
        async: false                    
    });          

    if(!returnValue){
        // showDialog("", "<%= getLabelValue('CHECKNETWORK')%>", 'error', 0, 'email');
        raiseAlert("REQUIRENETWORK","",locale);
        // alert("Please enable network connection");
    }
    return returnValue;
}

function checkForm(){
    var returnValue = true;

    toField = $("input[name='EmailRequest[toEmail]']").val();

    shortChecked = $("input[name='EmailRequest[shortIllustration]']").is(':checked');

    longChecked = $("input[name='EmailRequest[longIllustration]']").is(':checked');


    errors = "";

    if (toField == "")
    {
        // errors += "<%= getLabelValue('TOEMAILMANDATORY')%>\n";
        errors += getLabel('TOEMAILMANDATORY',locale);
        returnValue = false;
    }

    if(!returnValue){      
        // showDialog("", errors, 'error', 0, 'email');
        // alert(errors);
        raiseAlert(errors,[],locale);
    }
    return returnValue
}

function testEmail(value)
{
    emails = value.replace(" ","").replace(",",";");
    emailList = emails.split(";"); 
    returnValue = true;
    for(i=0; i < emailList.length; i++)
    {    
        if (emailList[i] != "")
        {
            emailPattern=new RegExp("[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}");
            returnValue = emailPattern.test(emailList[i]);
            if(!returnValue)
            { 
                break;        
            }
        }
    }

    return returnValue;
}

function EMAIL_toEmail_func(object) {
    if(!testEmail(object.value))
    {
       raiseAlert('ERR_INVALID',[getLabel("Email",locale)],locale);
        $(object).val('');
    }
}

function EMAIL_ccEmail_func(object) {
    if(!testEmail(object.value))
    {
        $(object).val('');
    }
}