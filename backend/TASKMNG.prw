#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/**************************************************************************************/
/*/{Protheus.doc} TASKMNG
    @description Gerenciador de Tarefas
    @type  function
    @author queziavg
    @since 27/08/2025
/*/
/**************************************************************************************/
// User Function TASKMNG()

Private oBrowse := FWMBrowse():New()

oBrowse:SetAlias("ZZG")

oBrowse:SetDescription('Gerenciador de Tarefas')

oBrowse:AddLegend("ZZG_SITUAC  == '1' "	, "ORANGE"	, "Pendente")
oBrowse:AddLegend("ZZG_SITUAC  == '2' "	, "BLUE"	, "Andamento")
oBrowse:AddLegend("ZZG_SITUAC  == '3' "	, "GREEN"	, "Concluída")
oBrowse:AddLegend("ZZG_SITUAC  == '4' "	, "GRAY"	, "Cancelada")

oBrowse:Activate()

Return

/************************************************************************************/
/*/{Protheus.doc} ModelDef
    @description  Modelo de dados, estrutura e modelo de negócio
    @author queziavg
    @since 27/08/2025
    @type function
/*/
/************************************************************************************/
Static Function ModelDef()

	Local oStruZZG := FWFormStruct(1,"ZZG")       // Estrutura do dicionário de dados, 1=Model;2=View
	Local oStruZZH := FWFormStruct(1,"ZZH")
	Local oModel   := MPFormModel():New("ZZGMASTER",, { |oModel| ValidTask( oModel ) },,)

	oModel:AddFields("ZZGMASTER",/*cOwner*/,oStruZZG)

	// Criação relação entre browse e grid  
	oModel:AddGrid('ZZHDETAIL','ZZGMASTER',oStruZZH)

	oModel:SetRelation('ZZHDETAIL', { { "ZZH_FILIAL", "FWxFilial('ZZG')" }, { "ZZH_CODTAR", "ZZG_CODIGO" }  }, ZZH->(IndexKey(1)))

	oModel:SetPrimaryKey( {"ZZG_FILIAL","ZZG_CODIGO"} )

	oModel:SetDescription('Gerenciador de Tarefas')
	oModel:GetModel('ZZGMASTER'):SetDescription('Tarefa')
	oModel:GetModel('ZZHDETAIL'):SetDescription('Subtarefas')

	oModel:SetVldActivate( { |oModel| PreValid( oModel ) } )

Return oModel

/************************************************************************************/
/*/{Protheus.doc} ViewDef
    @description Cria interface com o usuario
    @author queziavg
    @since 27/08/2025
    @type function
/*/
/************************************************************************************/
Static Function ViewDef()

	Local oModel 	:= FwLoadModel("TASKMNG")
	Local oView 	:= FwFormView():New()
	Local oStruZZG  := FwFormStruct( 2, "ZZG")
	Local oStruZZH  := FwFormStruct( 2, "ZZH")

	oView:SetModel(oModel)

	// Prepara a vizualização do cabeçalho (tarefas) e itens (subtarefas)
	oView:AddField("VwFieldZZG", oStruZZG , "ZZGMASTER")
	oView:AddGrid("VwGridZZH", oStruZZH, "ZZHDETAIL")

	oView:CreateHorizontalBox("SUPERIOR", 35)
	oView:CreateHorizontalBox("INFERIOR", 65)

	oView:SetOwnerView("VwFieldZZG", "SUPERIOR")
	oView:SetOwnerView("VwGridZZH", "INFERIOR")

	oView:AddIncrementField( 'VwGridZZH', 'ZZH_CODIGO' ) // Incremento para subtarefas

	// Habilita o tí­tulo
	oView:EnableTitleView('VwFieldZZG','Tarefa')
	oView:EnableTitleView('VwGridZZH','Subtarefas')

Return oView

/************************************************************************************/
/*/{Protheus.doc} MenuDef
    @description Menu padrão 
    @since 27/08/2025
/*/
/************************************************************************************/
Static Function MenuDef()
Return FWMVCMenu( "TASKMNG" )

/************************************************************************************/
/*/{Protheus.doc} ValidTask
    @description  Valida campos das tarefas
    @author queziavg
    @since 27/08/2025
    @type function
/*/
/************************************************************************************/
Static Function ValidTask(oModel)

	Local lRet     := .T.
	Local lConclui := .T.
	Local nX       := 0

	Local oTask    := oModel:GetModel("ZZGMASTER")
	Local oSubTask := oModel:GetModel("ZZHDETAIL")

	If !Empty(oTask:GetValue("ZZG_DTCONC")) .AND. oTask:GetValue("ZZG_DTCONC") < oTask:GetValue("ZZG_DTINC")
		FWAlertWarning("Data de Conclusão não pode ser menor que a Data de Inclusão.")
		lRet := .F.
		Return lRet
	EndIf

	If oTask:GetValue("ZZG_SITUAC") == "3" // Tarefa marcada como concluída
		For nX := 1 To oSubTask:Length()
			oSubTask:GoLine(nX)
			If oSubTask:GetValue("ZZH_STATUS") <> "3" .and. oSubTask:GetValue("ZZH_STATUS") <> "4" // Subtarefa não finalizada
				FWAlertWarning("Não é possível concluir a Tarefa enquanto existirem Subtarefas pendentes ou em andamento.")
				lRet := .F.
				Exit
			EndIf
		Next nX
	EndIf

	// Se todas as subtarefas estão concluí­das, marcar tarefa principal como 'concluí­da' automaticamente
	For nX := 1 To oSubTask:Length()
		oSubTask:GoLine(nX)
		If oSubTask:GetValue("ZZH_STATUS") <> "3" // Subtarefa não concluí­da
			lConclui := .F.
			Exit
		EndIf
	Next nX

	If lConclui
		oTask:SetValue("ZZG_SITUAC", "3")
	EndIf

Return lRet

/************************************************************************************/
/*/{Protheus.doc} AltTask
    @description  Validações lógicas antes de salvar
    @author queziavg
    @since 27/08/2025
    @type function
/*/
/************************************************************************************/
Static Function PreValid(oModel)

	Local aAreaAtu	 := GetArea()
	Local nOperation := oModel:GetOperation()
	Local lRet 		 := .T.

	If nOperation == MODEL_OPERATION_UPDATE
		If ZZG->ZZG_SITUAC == '3' .OR. ZZG->ZZG_SITUAC == '4'
			FWAlertInfo("Tarefas concluídas ou canceladas não podem ser alteradas.")
			lRet := .F.
		EndIf
	EndIf

	RestArea(aAreaAtu)

Return lRet
