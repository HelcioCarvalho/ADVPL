#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'


User Function TSTMES()
	Local dDate01	:= ctoD('12/12/19')
	Local dDate02	:= ctoD('19/12/19')

	//Montagem da Query
	cQuery := " SELECT * FROM " + RetSQLName("SBM") + " SBM WHERE BM_FILIAL = '" + FWxFilial("SBM") + "' AND SBM.D_E_L_E_T_ = ' '"

//Se o usuário estiver no grupo de administradores, mostra a query SQL
	If FWIsAdmin()
		ShowLog(cQuery, 'Query SQL')
	EndIf

Return( Nil )
