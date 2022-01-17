#Include "Protheus.ch"
 
/*/{Protheus.doc} SATCOM53

Tela de Grid com opção de alteração da quantidade de etiquetas

@author Mistral Tecnologia
@since 21/12/2020
@see SATCOM52
@type Function
/*/
 
User Function SATCOM53()
Private lMarker     := .T.
Private aDespes := {}
 
//Alimenta o array
GetItensNf()
  
DEFINE MsDIALOG o3Dlg TITLE 'Documento' From 0, 4 To 650, 1180 Pixel
     
    oPnMaster := tPanel():New(0,0,,o3Dlg,,,,,,0,0)
    oPnMaster:Align := CONTROL_ALIGN_ALLCLIENT
 
    oDespesBrw := fwBrowse():New()
    oDespesBrw:setOwner( oPnMaster )
 
    oDespesBrw:setDataArray()
    oDespesBrw:setArray( aDespes )
    oDespesBrw:disableConfig()
    oDespesBrw:disableReport()
 
    oDespesBrw:SetLocate() // Habilita a Localização de registros
 
    //Create Mark Column
    oDespesBrw:AddMarkColumns({|| IIf(aDespes[oDespesBrw:nAt,01], "LBOK", "LBNO")},; //Code-Block image
        {|| SelectOne(oDespesBrw, aDespes)},; //Code-Block Double Click
        {|| SelectAll(oDespesBrw, 01, aDespes) }) //Code-Block Header Click
 
    oDespesBrw:addColumn({"Item"             , {||aDespes[oDespesBrw:nAt,02]}, "C", "@!"    , 1, 10    ,                            , .T. , , .F.,, "aDespes[oDespesBrw:nAt,02]",, .F., .T.,                                    , "ETDESPES1"    })
    oDespesBrw:addColumn({"Codigo"           , {||aDespes[oDespesBrw:nAt,03]}, "C", "@!"    , 1, 20    ,                            , .T. , , .F.,, "aDespes[oDespesBrw:nAt,03]",, .F., .T.,                                    , "ETDESPES2"    })
    oDespesBrw:addColumn({"Descrição"        , {||aDespes[oDespesBrw:nAt,04]}, "C", "@!"    , 1, 20    ,                            , .T. , , .F.,, "aDespes[oDespesBrw:nAt,04]",, .F., .T.,                                    , "ETDESPES3"    })
    oDespesBrw:addColumn({"Cod.Barras"       , {||aDespes[oDespesBrw:nAt,05]}, "C", "@!"    , 1, 20    ,                            , .T. , , .F.,, "aDespes[oDespesBrw:nAt,05]",, .F., .T.,                                    , "ETDESPES3"    })
    oDespesBrw:addColumn({"Qtd. Etiquetas"           , {||aDespes[oDespesBrw:nAt,06]}, "N", "999"   , 1, 20    ,                            , .T. , , .F.,, "aDespes[oDespesBrw:nAt,06]",, .F., .T.,                                    , "ETDESPES4"    })
 
    oDespesBrw:setEditCell( .T. , { || .T. } ) //activa edit and code block for validation
 
    /*
    oDespesBrw:acolumns[2]:ledit     := .T.
    oDespesBrw:acolumns[2]:cReadVar:= 'aDespes[oBrowse:nAt,2]'*/

    oDespesBrw:Activate(.T.)


  Activate MsDialog o3Dlg On Init EnchoiceBar(o3Dlg,{||u_SATCOM52(aDespes),o3Dlg:End()},;
        {||o3Dlg:End()}) Centered

return .t.
 
 
 
Static Function SelectOne(oBrowse, aArquivo)
aArquivo[oDespesBrw:nAt,1] := !aArquivo[oDespesBrw:nAt,1]
oBrowse:Refresh()
Return .T.
 
 
 
Static Function SelectAll(oBrowse, nCol, aArquivo)
Local _ni := 1
For _ni := 1 to len(aArquivo)
    aArquivo[_ni,1] := lMarker
Next
oBrowse:Refresh()
lMarker:=!lMarker
Return .T.

/*
Alimenta a tabela temporaria
*/
Static Function GetItensNf()
Local cQuery    as Character
Local cQryT3    as Character
 
cQuery      := ""
cQryT3      := GetNextAlias()
aDespes := {}
 
cQuery+=" SELECT D1_ITEM, D1_COD, B1_DESC, B1_CODBAR, B1_ZZLOCAL, D1_QUANT  FROM " + RetSqlName("SD1")+ " SD1"+ CRLF 
cQuery+=" INNER JOIN "+RetSqlName("SB1") + " SB1 ON SB1.B1_FILIAL='"+xFilial("SB1")+"' AND B1_COD=D1_COD AND "+ RetSqlDel("SB1")+ CRLF 
cQuery+=" WHERE " + RetSqlDel("SD1")+ CRLF 
cQuery+=" AND D1_FILIAL= '"+SF1->F1_FILIAL+"' AND D1_DOC = '"+SF1->F1_DOC+"'"+ CRLF 
cQuery:=ChangeQuery(cQuery)
dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ) , cQryT3, .T., .F. )
 
(cQryT3)->(DbGoTop())
While (cQryT3)->(!EOF())
 
    aadd(aDespes,{.T.,alltrim((cQryT3)->D1_ITEM) ,alltrim((cQryT3)->D1_COD), alltrim((cQryT3)->B1_DESC), alltrim((cQryT3)->B1_CODBAR), (cQryT3)->D1_QUANT , alltrim((cQryT3)->B1_ZZLOCAL)  })
 
    (cQryT3)->(dbSkip())
EndDo
(cQryT3)->(dbCloseArea())
 
Return .t.
