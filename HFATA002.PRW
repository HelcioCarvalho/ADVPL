#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*
    Fun��o/Tela Gen�rica para Marca��o (MarkBrowse) MVC
    Retorna Tabela Tempor�ria  cAlias
*/


User Function HFATA002(cTitulo,aCabec,aDados)
	
	Local cArqTrb
	Local lMarcar                               := .F.
	Local i                                     := 1

	Private oBrowse                             := Nil
	Private cCadastro                           := cTitulo
	Private aRotina                             := Menudef() //Se for criar menus via MenuDef
	Private cAlias                              := GetNextAlias()
	Private aCampos                             := {}
	Private aSeek                               := {}

	If CriaTabTemp(aCabec,aDados) //Cria tabela Tempor�ria

		//Agora iremos usar a classe FWMarkBrowse
		oBrowse:= FWMarkBrowse():New()
		oBrowse:SetDescription(cCadastro) //Titulo da Janela
		oBrowse:SetAlias(cAlias) //Indica o alias da tabela que ser� utilizada no Browse
		oBrowse:SetFieldMark("TR_OK") //Indica o campo que dever� ser atualizado com a marca no registro
		oBrowse:oBrowse:SetDBFFilter(.T.)
		oBrowse:oBrowse:SetUseFilter(.T.) //Habilita a utiliza��o do filtro no Browse
		oBrowse:oBrowse:SetFixedBrowse(.T.)
		oBrowse:SetWalkThru(.F.) //Habilita a utiliza��o da funcionalidade Walk-Thru no Browse
		oBrowse:SetAmbiente(.T.) //Habilita a utiliza��o da funcionalidade Ambiente no Browse
		oBrowse:SetTemporary() //Indica que o Browse utiliza tabela tempor�ria
		oBrowse:oBrowse:SetSeek(.T.,aSeek) //Habilita a utiliza��o da pesquisa de registros no Browse
		oBrowse:oBrowse:SetFilterDefault("") //Indica o filtro padr�o do Browse

		For i:=1 to Len(aCabec)
			oBrowse:SetColumns(MCFG006TIT(aCabec[i,1] ,aCabec[i,1] ,05,"@!",0,len(aDados[1,i,1]),0))
		Next i

		//Adiciona botoes na janela
		oBrowse:AddButton("Processar"    , { || u_HFATA003()},,,, .F., 2 )
	
		//Indica o Code-Block executado no clique do header da coluna de marca/desmarca
		oBrowse:bAllMark := { || MCFG6Invert(oBrowse:Mark(),lMarcar := !lMarcar ), oBrowse:Refresh(.T.)  }
		//M�todo de ativa��o da classe
		oBrowse:Activate()

		oBrowse:oBrowse:Setfocus() //Seta o foco na grade
	Else
		Return
	EndIf

	//Limpar o arquivo tempor�rio
	If !Empty(cArqTrb)
		Ferase(cArqTrb+GetDBExtension())
		Ferase(cArqTrb+OrdBagExt())
		cArqTrb := ""
		(cAlias)->(DbCloseArea())
	Endif
Return(.T.)

/*
 Fun��o para marcar/desmarcar todos os registros do grid
*/
Static Function MCFG6Invert(cMarca,lMarcar)
	Local cAliasSD1 := cAlias
	Local aAreaSD1  := (cAliasSD1)->( GetArea() )
	dbSelectArea(cAliasSD1)
	(cAliasSD1)->( dbGoTop() )
	While !(cAliasSD1)->( Eof() )
		RecLock( (cAliasSD1), .F. )
		(cAliasSD1)->TR_OK := IIf( lMarcar, cMarca, '  ' )
		MsUnlock()
		(cAliasSD1)->( dbSkip() )
	EndDo
	RestArea( aAreaSD1 )
Return .T.

/*
    Caso crie os bot�es por fun��o, abaixo seque um exemplo
*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE "Executar" ACTION "U_HFATA003()"  OPERATION 6 ACCESS 0

Return(Aclone(aRot))

/*
    Fun��o para criar as colunas do grid
*/
Static Function MCFG006TIT(cCampo,cTitulo,nArrData,cPicture,nAlign,nSize,nDecimal)
	Local aColumn
	Local bData     := {||}
	Default nAlign     := 1
	Default nSize     := 20
	Default nDecimal:= 0
	Default nArrData:= 0

	If nArrData > 0
		bData := &("{||" + cCampo +"}") //&("{||oBrowse:DataArray[oBrowse:At(),"+STR(nArrData)+"]}")
	EndIf

    /* Array da coluna
    [n][01] T�tulo da coluna
    [n][02] Code-Block de carga dos dados
    [n][03] Tipo de dados
    [n][04] M�scara
    [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
    [n][06] Tamanho
    [n][07] Decimal
    [n][08] Indica se permite a edi��o
    [n][09] Code-Block de valida��o da coluna ap�s a edi��o
    [n][10] Indica se exibe imagem
    [n][11] Code-Block de execu��o do duplo clique
    [n][12] Vari�vel a ser utilizada na edi��o (ReadVar)
    [n][13] Code-Block de execu��o do clique no header
    [n][14] Indica se a coluna est� deletada
    [n][15] Indica se a coluna ser� exibida nos detalhes do Browse
    [n][16] Op��es de carga dos dados (Ex: 1=Sim, 2=N�o)
    */
	aColumn := {cTitulo,bData,,cPicture,nAlign,nSize,nDecimal,.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}
Return {aColumn}

/*
    Fun��o para criar a tela de legenda
*/
Static Function MCFG006LEG()
	Local oLegenda  :=  FWLegend():New()
	oLegenda:Add( '', 'BR_VERDE'   , "Usu�rios Liberados" )
	oLegenda:Add( '', 'BR_VERMELHO', "Usu�rios Bloqueados")

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()
Return Nil


/*
    Criar a tabela tempor�ria
*/
Static Function CriaTabTemp(aCabec,aDados)

	Local i:= 1
    Local j:=1
	Local cIndRandom
    Local lValid := .T.

	aadd(aCampos, {"TR_OK"   , "C", 002, 0}) //Este campo ser� usado para marcar/desmarcar
	For i:=1 to Len(aCabec)
		aadd(aCampos, { aCabec[i,1] , "C", len(aDados[1,i,1]), 0})
	Next i

	//Se o alias estiver aberto, fechar para evitar erros com alias aberto
	If (Select(cAlias) <> 0)
		dbSelectArea(cAlias)
		(cAlias)->(dbCloseArea ())
	Endif
	//A fun��o CriaTrab() retorna o nome de um arquivo de trabalho que ainda n�o existe e dependendo dos par�metros passados, pode criar um novo arquivo de trabalho.
	cArqTrb   := CriaTrab(aCampos,.T.)

	//Criar indices
	cIndice1 := Alltrim(CriaTrab(,.F.))
	cIndice1 := Left(cIndice1,5) + Right(cIndice1,2) + "A"

	If Len(aCabec) > 1
		For i:=2 to Len(aCabec)
			cIndRandom:="cIndice"+cValtochar(i)
			&cIndRandom := cIndice1
			&cIndRandom := Left(&cIndRandom,5) + Right(&cIndRandom,2) + RetAsc(cvaltochar(i+9), 1, .T.) // Converte Numeros em Letra
		Next i
	Endif

	//Se indice existir excluir
	If File(cIndice1+OrdBagExt())
		FErase(cIndice1+OrdBagExt())
	EndIf

	If Len(aCabec) > 1
		For i:=2 to Len(aCabec)
			cIndRandom:="cIndice"+cValtochar(i)
			If File( &cIndRandom+OrdBagExt())
				FErase(&cIndRandom+OrdBagExt())
			EndIf
		Next i
	Endif

	//A fun��o dbUseArea abre uma tabela de dados na �rea de trabalho atual ou na primeira �rea de trabalho dispon�vel
	dbUseArea(.T.,,cArqTrb,cAlias,Nil,.F.)
	//A fun��o IndRegua cria um �ndice tempor�rio para o alias especificado, podendo ou n�o ter um filtro


	For i:=1 to Len(aCabec)
		cIndRandom:="cIndice"+cValtochar(i)
		IndRegua(cAlias, &cIndRandom, aCabec[i,1],,, "Indice"+aCabec[i,1] )
	Next i

	//Fecha todos os �ndices da �rea de trabalho corrente.
	dbClearIndex()
	//Acrescenta uma ou mais ordens de determinado �ndice de ordens ativas da �rea de trabalho.
		If Len(aCabec) > 1
		For i:=1 to Len(aCabec)
            cIndRandom:="cIndice"+cValtochar(i)
             dbSetIndex(&cIndRandom+OrdBagExt())
        Next i
	Endif
 
	//Popular tabela tempor�ria, irei colocar apenas um unico registro
	For i:=1 to len(aDados)
		If RecLock(cAlias,.t.)
			(cAlias)->TR_OK   := "  "
			For j:= 1 to len(aCabec)
				cCampo:= "(cAlias)->"+aCabec[j,1]
				&cCampo := aDados[i,j,1]
			Next j
			MsUnLock()
		Endif
	Next i

	(cAlias)->(DbGoTop())

	If (cAlias)->(!Eof())
		//Irei criar a pesquisa que ser� apresentada na tela
		For i:=1 to Len(aCabec)
			aadd(aSeek, {aCabec[i,1], {{"","C",len(aDados[1,i,1]),0,aCabec[i,1] ,"@!"}}})
		Next i
	Endif

Return lValid
