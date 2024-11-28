pageextension 50317 "Whse. Receipt Subform Ext" extends "Whse. Receipt Subform"
{
    actions
    {
        addlast("&Line")
        {
            action(AsignaContLantes)
            {
                ApplicationArea = All;
                Enabled = bEnabled;
                Caption = 'Asign Container', comment = '="Asignar contenedor"';
                Image = SelectLineToApply;

                trigger OnAction()
                var
                    pSel: page "Sel. Contenido Contenedor";
                    dCant: Decimal;
                begin
                    clear(psel);
                    //if Rec."Qty. Shipped (Base)" <> 0 then begin
                    //dCant := Rec."Qty. Shipped (Base)" + Rec."Qty. to Ship (Base)";
                    psel.EstablecerDocnew('PRECEP', Rec."No.", rec."Line No.", rec."Qty. to Receive (Base)", rec."Location Code", Rec."Item No.", '', '', FALSE);
                    //end else
                    //psel.EstablecerDoc(Rec."Document No.", rec."Line No.", rec."Qty. to Ship (Base)", rec."Location Code", Rec."No.");
                    psel.RunModal();
                    CurrPage.Update(true);
                end;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        if Rec.Status = Rec.Status::"Completely Received" then
            bEnabled := false
        else
            bEnabled := true;
    end;

    var
        bEnabled: Boolean;
}
