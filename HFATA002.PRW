#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*
    Função/Tela Genérica para Marcação (MarkBrowse) MVC
    Retorna Tabela Temporária  cAlias
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

	If CriaTabTemp(aCabec,aDados) //Cria tabela Temporária

		//Agora iremos usar a classe FWMarkBrowse
		oBrowse:= FWMarkBrowse():New()
		oBrowse:SetDescription(cCadastro) //Titulo da Janela
		oBrowse:SetAlias(cAlias) //Indica o alias da tabela que será utilizada no Browse
		oBrowse:SetFieldMark("TR_OK") //Indica o campo que deverá ser atualizado com a marca no registro
		oBrowse:oBrowse:SetDBFFilter(.T.)
		oBrowse:oBrowse:SetUseFilter(.T.) //Habilita a utilização do filtro no Browse
		oBrowse:oBrowse:SetFixedBrowse(.T.)
		oBrowse:SetWalkThru(.F.) //Habilita a utilização da funcionalidade Walk-Thru no Browse
		oBrowse:SetAmbiente(.T.) //Habilita a utilização da funcionalidade Ambiente no Browse
		oBrowse:SetTemporary() //Indica que o Browse utiliza tabela temporária
		oBrowse:oBrowse:SetSeek(.T.,aSeek) //Habilita a utilização da pesquisa de registros no Browse
		oBrowse:oBrowse:SetFilterDefault("") //Indica o filtro padrão do Browse

		For i:=1 to Len(aCabec)
			oBrowse:SetColumns(MCFG006TIT(aCabec[i,1] ,aCabec[i,1] ,05,"@!",0,len(aDados[1,i,1]),0))
		Next i

		//Adiciona botoes na janela
		oBrowse:AddButton("Processar"    , { || u_HFATA003()},,,, .F., 2 )
	
		//Indica o Code-Block executado no clique do header da coluna de marca/desmarca
		oBrowse:bAllMark := { || MCFG6Invert(oBrowse:Mark(),lMarcar := !lMarcar ), oBrowse:Refresh(.T.)  }
		//Método de ativação da classe
		oBrowse:Activate()

		oBrowse:oBrowse:Setfocus() //Seta o foco na grade
	Else
		Return
	EndIf

	//Limpar o arquivo temporário
	If !Empty(cArqTrb)
		Ferase(cArqTrb+GetDBExtension())
		Ferase(cArqTrb+OrdBagExt())
		cArqTrb := ""
		(cAlias)->(DbCloseArea())
	Endif
Return(.T.)

/*
 Função para marcar/desmarcar todos os registros do grid
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
    Caso crie os botões por função, abaixo seque um exemplo
*/
Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE "Executar" ACTION "U_HFATA003()"  OPERATION 6 ACCESS 0

Return(Aclone(aRot))

/*
    Função para criar as colunas do grid
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
    [n][01] Título da coluna
    [n][02] Code-Block de carga dos dados
    [n][03] Tipo de dados
    [n][04] Máscara
    [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
    [n][06] Tamanho
    [n][07] Decimal
    [n][08] Indica se permite a edição
    [n][09] Code-Block de validação da coluna após a edição
    [n][10] Indica se exibe imagem
    [n][11] Code-Block de execução do duplo clique
    [n][12] Variável a ser utilizada na edição (ReadVar)
    [n][13] Code-Block de execução do clique no header
    [n][14] Indica se a coluna está deletada
    [n][15] Indica se a coluna será exibida nos detalhes do Browse
    [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
    */
	aColumn := {cTitulo,bData,,cPicture,nAlign,nSize,nDecimal,.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}
Return {aColumn}

/*
    Função para criar a tela de legenda
*/
Static Function MCFG006LEG()
	Local oLegenda  :=  FWLegend():New()
	oLegenda:Add( '', 'BR_VERDE'   , "Usuários Liberados" )
	oLegenda:Add( '', 'BR_VERMELHO', "Usuários Bloqueados")

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()
Return Nil


/*
    Criar a tabela temporária
*/
Static Function CriaTabTemp(aCabec,aDados)

	Local i:= 1
    Local j:=1
	Local cIndRandom
    Local lValid := .T.

	aadd(aCampos, {"TR_OK"   , "C", 002, 0}) //Este campo será usado para marcar/desmarcar
	For i:=1 to Len(aCabec)
		aadd(aCampos, { aCabec[i,1] , "C", len(aDados[1,i,1]), 0})
	Next i

	//Se o alias estiver aberto, fechar para evitar erros com alias aberto
	If (Select(cAlias) <> 0)
		dbSelectArea(cAlias)
		(cAlias)->(dbCloseArea ())
	Endif
	//A função CriaTrab() retorna o nome de um arquivo de trabalho que ainda não existe e dependendo dos parâmetros passados, pode criar um novo arquivo de trabalho.
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

	//A função dbUseArea abre uma tabela de dados na área de trabalho atual ou na primeira área de trabalho disponível
	dbUseArea(.T.,,cArqTrb,cAlias,Nil,.F.)
	//A função IndRegua cria um índice temporário para o alias especificado, podendo ou não ter um filtro


	For i:=1 to Len(aCabec)
		cIndRandom:="cIndice"+cValtochar(i)
		IndRegua(cAlias, &cIndRandom, aCabec[i,1],,, "Indice"+aCabec[i,1] )
	Next i

	//Fecha todos os índices da área de trabalho corrente.
	dbClearIndex()
	//Acrescenta uma ou mais ordens de determinado índice de ordens ativas da área de trabalho.
		If Len(aCabec) > 1
		For i:=1 to Len(aCabec)
            cIndRandom:="cIndice"+cValtochar(i)
             dbSetIndex(&cIndRandom+OrdBagExt())
        Next i
	Endif
 
	//Popular tabela temporária, irei colocar apenas um unico registro
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
		//Irei criar a pesquisa que será apresentada na tela
		For i:=1 to Len(aCabec)
			aadd(aSeek, {aCabec[i,1], {{"","C",len(aDados[1,i,1]),0,aCabec[i,1] ,"@!"}}})
		Next i
	Endif

Return lValid
