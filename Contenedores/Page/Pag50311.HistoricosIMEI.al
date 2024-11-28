page 50311 "Historicos IMEI"
{
    ApplicationArea = All;
    Caption = 'Históricos IMEI';
    PageType = List;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    DelayedInsert = true;
    ModifyAllowed = false;
    SourceTable = "Historicos IMEI";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                ShowCaption = false;

                field(IMEI; Rec.IMEI)
                {
                    ApplicationArea = All;
                }
                field("Nº abono venta"; Rec."Nº abono venta")
                {
                    ApplicationArea = All;
                }
                field("Fecha registro abono"; Rec."Fecha registro abono")
                {
                    ApplicationArea = All;
                }
                field("Nº factura venta"; Rec."Nº factura venta")
                {
                    ApplicationArea = All;
                }
                field("Fecha registro factura"; Rec."Fecha registro factura")
                {
                    ApplicationArea = All;
                }
                field("Nº pedido compra"; Rec."Nº pedido compra")
                {
                    ApplicationArea = All;
                }


            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Cargar datos")
            {
                ApplicationArea = All;
                Caption = 'Cargar datos';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = WorkCenterLoad;
                RunObject = report "Recargar historico IMEI";

            }
        }
    }
}
