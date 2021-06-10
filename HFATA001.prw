/*
    Função para chamada rotina automatica de eliminação residuo
*/
Static Function EliminaPedido(cFilial,cNumPedido)
    
    DbSelectArea("SC7")
	SC7->(DbSetOrder(1))
	If SC7->(MsSeek(AVKEY(cFilial,"C7_FILIAL")+AVKEY(cNumPedido,"C7_NUM"))) 
						
        ElimResid(100,1,SC7->C7_EMISSAO,SC7->C7_EMISSAO,SC7->C7_NUM,SC7->C7_NUM,"    ","ZZZZZ") 
    
        If SC7->C7_RESIDUO == 'S'
            
        Else
            
        Endif

    Endif

Return



/*
	Função Eliminar Residuo baseada no fonte MATA235

*/
Static Function ElimResid(nPerc, cTipo, dEmisDe, dEmisAte, cCodigoDe, cCodigoAte, cProdDe, cProdAte,;
	cFornDe, cFornAte, dDatprfde, dDatPrfAte, cItemDe, cItemAte, lConsEIC, aRecSC7)
	
	Default aRecSC7		:= {}
	Default lConsEIC 	:= SuperGetMV("MV_ELREIC",.F.,.T.)
	Default nPerc		:= 100 // Pecencetual Ao informar 100%, elimina também as solicitações pendentes não atendidas.
	Default cTipo 		:= 1 //"Pedido Compra  "
	Default dEmisDe 	:= CTOD("01/01/2000")
	Default dEmisAte 	:= CTOD("31/12/2048")
	Default cCodigoDe 	:= ""
	Default cCodigoAte 	:= "ZZZZZZZZZ"
	Default cProdDe		:= ""
	Default cProdAte 	:= "ZZZZZZZZZ"
	Default cFornDe 	:= ""
	Default cFornAte 	:= "ZZZZZZZZ"
	Default dDatprfde 	:= CTOD("01/01/2000")
	Default dDatPrfAte 	:= CTOD("31/12/2049")
	Default cItemDe   	:= ""
	Default cItemAte 	:= "ZZZZZZ"

	Processa({|lEnd| MA235PC(nPerc, cTipo, dEmisDe, dEmisAte, cCodigoDe, cCodigoAte, cProdDe, cProdAte,;
	cFornDe, cFornAte, dDatprfde, dDatPrfAte, cItemDe, cItemAte, lConsEIC, aRecSC7)})


return
