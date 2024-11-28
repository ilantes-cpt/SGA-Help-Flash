pageextension 50321 "Assembly Order Subform Ext" extends "Assembly Order Subform"
{
    actions
    {

        addlast("&Line")
        {
            action(AsignaContLantes)
            {
                ApplicationArea = All;
                Caption = 'Asign Container', comment = '="Asignar contenedor"';
                Image = SelectLineToApply;

                trigger OnAction()
                var
                    pSel: page "Sel. Contenido Contenedor";
                    dCant: Decimal;
                begin
                    clear(psel);
                    psel.EstablecerDocnew('PENSAMBLADO', Rec."Document No.", rec."Line No.", Rec.Quantity, rec."Location Code", Rec."No.", '', '', FALSE);
                    psel.RunModal();
                    CurrPage.Update(true);
                end;
            }
        }
    }
}

