module namespace page = 'http://basex.org/examples/web-page';

declare namespace app = 'http://www.nCar.pt/appointment';
declare namespace expertise = 'http://www.nCar.pt/expertise';
declare default element namespace'http://www.nCar.pt/partner';
declare namespace ex = 'http://www.nCar.pt/expert';


(:________________________________________________REST API________________________________________________:)

(:Esta função vai receber o xml com uma marcação, de seguida irá chamar a função que faz a sua validação, 
caso o ficheiro seja válido vai verificar se já existe uma marcação com o mesmo codígo, se existir o  
Utilizador será avisado, através do Postman sobre a existência de um conflito, caso nao exista, será chamada
a função que adicionará o ficheiro á base de dados:)
declare
  %updating  
  %rest:path("appointments")
  %rest:POST("{$appointment}")
  %rest:consumes('application/xml')
function page:addAP($appointment as item())
{
  (:Função que valida o xml através do schema:)
  page:validateXML($appointment),
  (:Variavél que contará o numero de marcações com o mesmo código do ficheiro enviado:)
  let $exists := fn:count(db:get("nCardb")//appointment[Code = $appointment//app:Code])
   let $expert:= fn:count(db:get("nCardb")//expert[Code = $appointment//app:idExpert])
  return (
        if($exists = 0 and $expert = 1) then 
           page:addAppointment($appointment)
        else
           update:output(web:redirect('/app/409'))
  )
};



(:Esta é a função que adicionará um ficheiro xml á base de dados:)
declare 
%updating 
function page:addAppointment($appointment){
    let $newId := fn:count(db:get("nCardb")//appointment) + 1    
    let $newdocument := element appointment{                            
                            element Code{$appointment//app:Code/text()},
                            element idExpert{$appointment//app:idExpert/text()},
                            element Local{$appointment//app:Local},
                            element Vehicle{$appointment//app:Vehicle},
                            element date{$appointment//app:date/data()}
                          }
    return(
            (:Criação do ficheiro na base de dados com o nome "appointment" + nº do xml, isto é, se existirem 10 xml's,                ao adicionar mais um, este terá o nome "appointment11.xml":)
            db:add("nCardb", $newdocument, fn:concat("appointment", $newId , ".xml")),
            update:output(web:redirect(concat('/app/201/',$newId)))
          )
};
(:Função que validará o xml enviado pelo usuário:)
declare 
  %updating 
  function page:validateXML($appointment as node()){
  let $xsd:= "./xsd/appointment.xsd"
  return validate:xsd($appointment, $xsd)
};




declare
%rest:path("/appointment/find/expert/{$expertCode}")
%rest:GET
function page:findAppointmentByExpert($expertCode) {
    let $currentDate := format-date(current-date(), "[Y0001]-[M01]-[D01]")
    let $exists := db:get("nCardb")//appointment[idExpert = $expertCode][date = $currentDate]
    return
        (
        if ( $exists )
        then
            $exists
        else
            <rest:response>
                <http:response
                    status="404"></http:response>
            </rest:response>
        )
};





declare
  %updating  
  %rest:path("expertises")
  %rest:POST("{$expertise}")
  %rest:consumes('application/xml')
function page:addEx($expertise as item())
{
  page:validateExpertiseXML($expertise),
 

   
  let $nmbrofExpertises := fn:count($expertise//expertise:expertise)
  let $partnersexist := fn:count(db:get("nCardb")//partner[Code = $expertise//expertise:expertise/expertise:idPartner])
  let $appointmentexist := fn:count(db:get("nCardb")//partner[Code = $expertise//expertise:expertise/expertise:idPartner])
   let $expertsexist := fn:count(db:get("nCardb")//expert[Code = $expertise//expertise:expertise/expertise:idExpert])
   let $sameDate := fn:count($expertise//expertise:expertise[expertise:date = $expertise//expertise:expertise/expertise:date])
 
  
  
  let $duplicate := fn:count(db:get("nCardb")//expertise:expertise[expertise:Code = $expertise//expertise:Expertises/expertise:Code])
 

  return (
        if($expertsexist = $nmbrofExpertises and $partnersexist = $nmbrofExpertises and $appointmentexist = $nmbrofExpertises and $sameDate = $nmbrofExpertises and $duplicate = 0) then 
           page:addExpertise($expertise)
        else
           update:output(web:redirect('/app/409'))
  )
};

declare 
%updating 
function page:addExpertise($expertise){
  
    
    let $newdocument := element Expertises{                            
                    db:get("nCardb")//expertise:expertise[expertise:Code != $expertise//expertise:Code],
                    $expertise//expertise:expertise                            
      }
    return(
            db:put("nCardb", $newdocument, "Expertises.xml"),
            update:output(web:redirect(concat('/app/201/',1)))
          )
};

declare 
  %updating 
  function page:validateExpertiseXML($expertise as node()){
  let $xsd:= "./xsd/expertise.xsd"
  return validate:xsd($expertise, $xsd)
};









declare
%rest:path("/expertises/find/partner/{$PartnerCode}/{$state}")
%rest:query-param ("expertiseDate", "{$expertiseDate}")
%rest:GET
function page:findExpertiseByDate($PartnerCode , $expertiseDate, $state ) {
    let $exists := db:get("nCardb")//expertise:expertise[expertise:date = $expertiseDate ][expertise:idPartner = $PartnerCode ][expertise:State = $state]


    return
        (
        if ($exists)
        then
            $exists
        else
            <rest:response>
                <http:response
                    status="404"></http:response>
            </rest:response>
        )
};








declare
%rest:path("/expertises/show/{$expertiseCode}")
%rest:GET
function page:showExpertise($expertiseCode) {
    let $exists := db:get("nCardb")//expertise:expertise[expertise:Code = $expertiseCode]
    return
        (
        if ( $exists )
        then
            $exists
        else
            <rest:response>
                <http:response
                    status="404"></http:response>
            </rest:response>
        )
};


declare
  %updating  
  %rest:path("/expertises/replace")
  %rest:PUT("{$expertise}")
  %rest:consumes('application/xml')
function page:replaceEx($expertise as item())
{
  page:validateExpertiseXML($expertise),
  let $exists := fn:count(db:get("nCardb")//appointment[Code = $expertise//expertise:expertise/expertise:Code])
  let $partner := fn:count(db:get("nCardb")//partner[Code = $expertise//expertise:expertise/expertise:idPartner])
   let $expert := fn:count(db:get("nCardb")//expert[Code = $expertise//expertise:expertise/expertise:idExpert])
   let $equal := fn:count(db:get("nCardb")//expertise:expertise[expertise:Code = $expertise//expertise:expertise/expertise:Code])
   
  return (
        if($exists = 1 and $partner = 1 and $expert = 1 and $equal = 1) then 
           page:addExpertise($expertise)
        else
           update:output(web:redirect('/app/409'))
  )
};









(:ESTA FUNÇÃO, ENQUANTO NÃO IMPOSTA PELO ENUNCIADO FOI, POR ESCOLHA NOSSA, A MANEIRA COMO DECIDIMOS ADICIONAR PARCEIROS Á OFICINA :)
declare
  %updating  
  %rest:path("partners")
  %rest:POST("{$partner}")
  %rest:consumes('application/xml')
function page:addPart($partner as item())
{
  page:validatePartnerXML($partner),
  let $exists := fn:count(db:get("nCardb")//partner[Code = $partner//Code])
  return (
        if($exists = 0) then 
           page:addPartner($partner)
        else
           update:output(web:redirect('/app/409'))
  )
};

declare 
%updating 
function page:addPartner($partner){
    let $newId := fn:count(db:get("nCardb")//partner) + 1
    let $newdocument := element partner{                            
                            element Name{$partner//Name/text()},
                            element Code{$partner//Code/text()}
                          }
    return(
            db:add("nCardb", $newdocument, fn:concat("partner", $newId , ".xml")),
            update:output(web:redirect(concat('/app/201/',$newId)))
          )
};

declare 
  %updating 
  function page:validatePartnerXML($partner as node()){
  let $xsd:= "./xsd/partner.xsd"
  return validate:xsd($partner, $xsd)
};








(:ESTA FUNÇÕES, ENQUANTO NÃO IMPOSTA PELO ENUNCIADO FOI, POR ESCOLHA NOSSA, A MANEIRA COMO DECIDIMOS ADICIONAR PERITOS Á OFICINA :)
declare
  %updating  
  %rest:path("experts")
  %rest:POST("{$expert}")
  %rest:consumes('application/xml')
function page:addExp($expert as item())
{
  page:validateExpertXML($expert),
  let $exists := fn:count(db:get("nCardb")//expert[Code = $expert//ex:Code])
  return (
        if($exists = 0) then 
           page:addExpert($expert)
        else
           update:output(web:redirect('/app/409'))
  )
};

declare 
%updating 
function page:addExpert($expert){
    let $newId := fn:count(db:get("nCardb")//expert) + 1
    let $newdocument := element expert{                            
                            element Name{$expert//ex:Name/text()},
                            element Code{$expert//ex:Code/text()}
                          }
    return(
            db:add("nCardb", $newdocument, fn:concat("expert", $newId , ".xml")),
            update:output(web:redirect(concat('/app/201/',$newId)))
          )
};

declare 
  %updating 
  function page:validateExpertXML($expert as node()){
  let $xsd:= "./xsd/expert.xsd"
  return validate:xsd($expert, $xsd)
};





















declare 
    %rest:path('/app/409') 
    function page:conflict() {
        <rest:response>
             <http:response status="409"></http:response>
        </rest:response>
};
declare 
    %rest:path('/app/201/{$id}') 
    function page:created($id) {
        <rest:response>
              <http:response status="201">
                <http:header name="Location" value='{concat("/appointments/", $id)}'/>
              </http:response>
        </rest:response>
};
