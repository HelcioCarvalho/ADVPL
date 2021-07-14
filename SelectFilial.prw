#include "Protheus.Ch"
#include "TopConn.Ch"

/*
Abre Tela para escolha das Filiais
Como usar ParamBox

Public cFiliais		:= ""

AAdd(aButtons, {05, {|| U_LEAEST10()   }, 'Escolha as Filiais'}) // bot?o Parametros
If ParamBox(aParamBox,"Gera??o da Planilha..." + cTitulo,,,aButtons,,,,,cPerg,.T.,.T.)
	FWMsgRun(, {|| FAT000007()}, "Processando...", "Aguarde gerando planilhas...")
EndIf


	cParamFil:= StrTran(Alltrim(cFiliais),"/","','")
	cParamFil:= "'"+cParamFil+"'"

*/

User Function SELECTFILIAL()

	Local cRet			:= ""
	Local aListHdr 		:= {'','C¨®digo','Filial'} 
	Local aRegs			:= fLdDados()  
	Local bDuploClick   := {|| aRegs[oListBox:nAt,1] := !aRegs[oListBox:nAt,1] }  
	Local bValid 		:= { || ValidArray(@oDlg,@oListBox,@aRegs,oOk,oNo,oListBox:nAt) }
	Local oOk			:= LoadBitmap( GetResources(), "LBOK")
	Local oNo			:= LoadBitMap( GetResources(), "LBNO")
	Local lOk			:= .f.
	Local nI			:= 0
	
	Define MsDialog oDlg Title "Selecione as Filiais" From  10,10 To 30 ,55 
	oDlg:lEscClose := .t.                                                                                                     
	
	oListBox := TWBrowse():New( 01,0,200,130,,aListHdr,,oDlg,,,,,,,,,,,,.F.,,.T.,,.F.,,,) 
			oListBox:SetArray(aRegs)                  
			oListBox:bLDblClick:= { || aRegs[oListBox:nAt,1] := !aRegs[oListBox:nAt,1] }                          
			oListBox:bHeaderClick 	:= {|| } 
			oListBox:bLine 			:= {|| {iif(aRegs[oListBox:nAt,01],oOk,oNo),;
											aRegs[oListBox:nAt,02] ,;
											aRegs[oListBox:nAt,03]	} }
	
		TButton():New(135,3," Ok ",oDlg,{|| (lOk := .t.), oDlg:End() },35,11,,,.F.,.T.,.F.,,.F.,,,.F.)
		TButton():New(135,42," Cancelar ",oDlg,{|| oDlg:End() },35,11,,,.F.,.T.,.F.,,.F.,,,.F.)
		TButton():New(135,82," Sel. Todos ",oDlg,{|| selTodos(@aRegs)  },35,11,,,.F.,.T.,.F.,,.F.,,,.F.)
		TButton():New(135,122," Invert Sel. ",oDlg,{|| invertTodos(@aRegs) },35,11,,,.F.,.T.,.F.,,.F.,,,.F.)
		
	Activate MsDialog oDlg Centered           
	
	If lOk

		For nI := 1 to Len(aRegs)
				                 
			If aRegs[nI,1] .And. Len(cRet) > 0
				cRet += "/"
			Endif				                
				                
			If aRegs[nI,1]	                            
				cRet += Alltrim(aRegs[nI,2])
			Endif
	     
	    Next nI 

	Endif       
	
	cFiliais:= cRet
	
Return(.t.)                        

Static Function fLdDados()
	Local aRet		:= {}
	Local aArea		:= GetArea()
	Local cQry		:= ""

	cQry := "SELECT M0_CODIGO, M0_CODFIL, M0_FILIAL "+CRLF
	cQry += "FROM "+RetSqlName('SM0')+ " "+CRLF
	cQry += "WHERE D_E_L_E_T_ = ' ' "+CRLF
	cQry += "ORDER BY M0_CODIGO "+CRLF
	
	TcQuery cQry NEW Alias "QRY"
	
	While QRY->(!Eof())                              
	
		aAdd(aRet, {.f., QRY->M0_CODFIL, QRY->M0_FILIAL } )

		QRY->(DbSkip())
	Enddo
                                           
	QRY->(DbCloseArea())
	       
	RestArea(aArea)	

Return(aRet)                                                                


/*
*/
Static Function ValidArray(oDlg,oListBox,aRegs,oOk,oNo,nPos)

Local lMarca	:=	.f.

For t := 1 to Len(aRegs)
	if	aRegs[t,1] 
		lMarca := .t.
	endif
Next t

if	lMarca
	For	k := 1 to Len(aRegs)
		if	k <> nPos
			aRegs[k,1]	:=	.f.
		endif
	Next k
endif
                   
oListBox:SetArray(aRegs)
oListBox:bLine		:= { || { iif(aRegs[oListBox:nAt,01],oOk,oNo),aRegs[oListBox:nAt,03], aRegs[oListBox:nAt,02]} }

oListBox:Refresh()
oDlg:Refresh()

Return ( .t. )             

Static Function selTodos(aRegs)
	For t := 1 to Len(aRegs)
		aRegs[t,1] := .T.
	Next t

	oListBox:Refresh()
	oDlg:Refresh()

Return ( .t. )

/*
*/
Static Function invertTodos(aRegs)
	For t := 1 to Len(aRegs)
		if aRegs[t,1]
			aRegs[t,1] := .F.
		else
			aRegs[t,1] := .T.
		endIf
	Next t

	oListBox:Refresh()
	oDlg:Refresh()

Return ( .t. ) 