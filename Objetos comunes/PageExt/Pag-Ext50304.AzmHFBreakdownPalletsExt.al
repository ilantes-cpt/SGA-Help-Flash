pageextension 50304 "AzmHFBreakdownPallets Ext" extends AzmHFBreakdownPallets
{
    layout
    {
        addafter(OrderNo)
        {
            field("Nº Albarán Compra"; Rec."Nº Albarán Compra")
            {
                ApplicationArea = all;
            }
        }
        addafter(IMSI)
        {
            field("Nº pedido IMSI"; Rec."Nº pedido IMSI")
            {
                ApplicationArea = all;
            }

        }
        addlast(General)
        {
            field("Contenedor generado"; Rec."Contenedor generado")
            {
                ApplicationArea = all;
                editable = false;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            /*action(Desmarcar)
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ClearLog;

                trigger OnAction()
                var
                    rRec: record AzmHFBreakdownPallet;
                    lText001: Label 'Process completed', comment = 'ESP="Proceso finalizado."';
                begin
                    CurrPage.SetSelectionFilter(rrec);
                    if rrec.Find('-') then
                        repeat
                            //rrec."Contenedor generado" := true;
                            rrec."Contenedor generado" := false;
                            rRec.Modify(false);
                        until rrec.Next() = 0;
                    Message(lText001);
                end;
            }

            
            action(ActValor)
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ClearLog;

                trigger OnAction()
                var
                    rRec: record AzmHFBreakdownPallet;
                begin
                    CurrPage.SetSelectionFilter(rrec);
                    if rrec.Find('-') then
                        repeat
                            rrec.ItemNo := 'PD-000037';
                            rRec.Modify(false);
                        until rrec.Next() = 0;
                    Message('Proceso finalizado');
                end;
            }
            */
        }
    }
}
