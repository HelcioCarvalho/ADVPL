
#Include "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#include 'parmtype.ch'

/* HFATA001 - Rotina para Eliminar Resíduo através da Leitura de Arquivo .TXT por Empresa/Filial/Pedido

Exemplo de arquivo:


01;001014;000006
11;001001;024154

*/

User Function HFATA001()

	Local cFile := AllTrim( cGetFile( 'Arquivo |*.TXT' , 'Selecione arquivo' ,0, 'C:\' , .T., GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE ) )

	If !vazio(cFile)
		Processa({|| LerArquivo(cFile)},"Lendo Arquivo Selecionado...")
	Endif
Return

/*
	Lê o arquivo e organiza os dados
*/

Static Function LerArquivo(cFile)

	Local cSeparador    := ";"
	Local cEmpresaPc    := ""
	Local cFilialPC     := ""
	Local cPedidoCompra := ""
	Local aDadosElimina := {}
	Local aLinhas  		:= {}
	Local nAtual		:= 0
	Local nTotal		:= 100
	Local aDadosCabec	:= {}

//Definindo o arquivo a ser lido
	oFile := FWFileReader():New(cFile)

//Se o arquivo pode ser aberto
	If (oFile:Open())

		PROCREGUA(100)

		//Se não for fim do arquivo
		If ! (oFile:EoF())
			//Enquanto houver linhas a serem lidas
			While (oFile:HasLine())

				//Incrementa a mensagem na régua
				nAtual++
				IncProc("Analisando registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

				//Buscando o texto da linha atual
				cLinAtu := oFile:GetLine()

				If AT(cSeparador, cLinAtu) > 0 //Empresa procura ;
						cEmpresaPc := substring(cLinAtu, 1, AT(cSeparador, cLinAtu)-1)
					cLinAtu :=  substring(cLinAtu, AT(cSeparador, cLinAtu)+1 , len(cLinAtu)) //corta
				Endif

				If AT(cSeparador, cLinAtu) > 0 //Filial procura ;
						cFilialPC := substring(cLinAtu, 1, AT(cSeparador, cLinAtu)-1)
					cLinAtu :=  substring(cLinAtu, AT(cSeparador, cLinAtu)+1 , len(cLinAtu)) //corta
				Endif

				If AT(cSeparador, cLinAtu) > 0 //Pedido procura ;
						cPedidoCompra := substring(cLinAtu, 1, AT(cSeparador, cLinAtu)-1)
					cLinAtu :=  substring(cLinAtu, AT(cSeparador, cLinAtu)+1 , len(cLinAtu)) //corta
				Else
					cPedidoCompra := cLinAtu
				Endif

				aadd(aDadosElimina,{ cEmpresaPc, cFilialPC, cPedidoCompra  }    )
			EndDo
		EndIf

		//Fecha o arquivo e finaliza o processamento
		oFile:Close()
	EndIf

	If len(aDadosElimina) > 0
		If	ApMsgYesNo("Foram encontrados, "+cvaltochar(len(aDadosElimina))+" pedidos. Deseja realizar Eliminar Resíduo?")
			Processa({|| EliminaPedido(aDadosElimina)},"Eliminando Resíduos...")
		Endif
	Endif
Return

/*
    Função para chamada rotina automatica de eliminação residuo
*/
Static Function EliminaPedido(aDadosElimina)

	Local i:= 1
	Local cEmpresa 	:= ""
	Local cFilialPC := ""
	Local cTextoLog := ""
	Default aParam          := Nil

	PROCREGUA(Len(aDadosElimina))

	For i:=1 to Len(aDadosElimina)
		cEmpresa 	:= aDadosElimina[i,1]
		cFilialPC 	:= aDadosElimina[i,2]
		cNumPedido 	:= aDadosElimina[i,3]

		IncProc("Eliminando Pedido " + cNumPedido + "...")

		RPCSetType(3)
		PREPARE ENVIRONMENT EMPRESA cEmpresa FILIAL cFilialPC MODULO "COM" TABLES "SA1","SA2","SB1","SC7"
		SetModulo("SIGACOM","COM")
		DbSelectArea("SC7")
		SC7->(DbSetOrder(1))
		If SC7->(MsSeek(AVKEY(cFilial,"C7_FILIAL")+AVKEY(cNumPedido,"C7_NUM")))
			ElimResid(100,1,SC7->C7_EMISSAO,SC7->C7_EMISSAO,SC7->C7_NUM,SC7->C7_NUM,"    ","ZZZZZ")
			cTextoLog += "Eliminado Resíduo Pedido : " + cNumPedido + " Empresa : "+cEmpresa+" - Filial :"+cFilialPC + CRLF
		Endif
		RESET ENVIRONMENT
	Next i

	If !vazio(cTextoLog)
		GravaLog(cTextoLog)
	Endif
Return


/*
	Função Eliminar Residu
	o baseada no fonte MATA235
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

	If !vazio(cCodigoDe) .or. !cCodigoAte$('Z') // Nunca fazer para todos
		Processa({|lEnd| MA235PC(nPerc, cTipo, dEmisDe, dEmisAte, cCodigoDe, cCodigoAte, cProdDe, cProdAte,;
			cFornDe, cFornAte, dDatprfde, dDatPrfAte, cItemDe, cItemAte, lConsEIC, aRecSC7)})
	Endif
return


/*
*/

Static Function GravaLog(cTexto)
	Local cPasta   := GetTempPath()
	Local cArquivo := ProcName()+".txt"
	Default cTexto := "Arquivo LOG"

	oFWriter := FWFileWriter():New(cPasta + cArquivo, .T.)

	If ! oFWriter:Create()
		MsgStop("Houve um erro ao gerar o arquivo: " + CRLF + oFWriter:Error():Message, "Atenção")
	Else
		oFWriter:Write(cTexto + CRLF)
		oFWriter:Close()
		If MsgYesNo("Arquivo de LOG gerado com sucesso (" + cPasta + cArquivo + ")!" + CRLF + "Deseja abrir?", "Atenção")
			ShellExecute("OPEN", cArquivo, "", cPasta, 1 )
		EndIf
	EndIf
Return
