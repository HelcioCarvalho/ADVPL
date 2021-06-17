
#Include "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#include 'parmtype.ch'

/* HFATA001 - Rotina para Eliminar Resíduo através da Leitura de Arquivo .TXT por Empresa/Filial/Pedido

Exemplo de arquivo:


Empresa;Filial;Pedido
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

				If nAtual == 1 //Cabeçalho
					While AT(cSeparador, cLinAtu) > 0 //Cria o Cabeçalho
						cCabec := substring(cLinAtu, 1, AT(cSeparador, cLinAtu)-1)
						aadd(aDadosCabec,{cCabec})
						cLinAtu :=  substring(cLinAtu, AT(cSeparador, cLinAtu)+1 , len(cLinAtu)) //corta

						If AT(cSeparador, cLinAtu) == 0 //Ultima Linha
							aadd(aDadosCabec,{cLinAtu})
						EndIf
					EndDo
				Else

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
				Endif
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
		Endif
		RESET ENVIRONMENT
	Next i
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
