pageextension 50302 "Item Journal Ext" extends "Item Journal"
{
    layout
    {
        /*addafter(Description)
        {
            field(Contenedor; Rec.Contenedor)
            {
                ApplicationArea = all;
            }
        }*/
        addafter(Control1)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                SubPageLink = "Libro registro productos" = field("Journal Template Name"), "Sección registro productos" = field("Journal Batch Name"), LinDiario = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
    actions
    {
        addafter(ItemTrackingLines)
        {
            action(AsignaContLantes)
            {
                ApplicationArea = All;
                Enabled = true;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = false;
                PromotedCategory = Category6;
                Caption = 'Asign Container', comment = '="Asignar contenedor"';
                Image = SelectLineToApply;

                trigger OnAction()
                var
                    pSel: page "Sel. Contenido Contenedor";
                    dCant: Decimal;
                    bVendido: Boolean;
                begin
                    clear(psel);
                    case Rec."Entry Type" of
                        Rec."Entry Type"::Output, Rec."Entry Type"::"Negative Adjmt.":
                            bVendido := false;
                        Rec."Entry Type"::Purchase, Rec."Entry Type"::"Positive Adjmt.":
                            bVendido := true;
                    end;
                    psel.EstablecerDocnew('DIARIO', '', rec."Line No.", rec."Quantity (Base)", rec."Location Code", Rec."Item No.", Rec."Journal Template Name", Rec."Journal Batch Name", bVendido);
                    psel.RunModal();
                    CurrPage.Update(true);
                end;
            }
        }
    }
}
