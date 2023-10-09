page 50301 "Tipo contenedor"
{
    ApplicationArea = All;
    Caption = 'Container Type';
    PageType = List;
    SourceTable = "Tipo contenedor";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Tipo; Rec.Tipo)
                {
                    ApplicationArea = All;
                }
                field(Descripcion; Rec.Descripcion)
                {
                    ApplicationArea = All;
                }
                field("Nº Serie"; Rec."Nº Serie")
                {
                    ApplicationArea = All;
                }
                field("Admite nivel superior"; Rec."Admite nivel superior")
                {
                    ApplicationArea = All;
                }
                field(Fungible; Rec.Fungible)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    /*actions
    {
        area(Processing)
        {
            action(Combinaciones)
            {
                ApplicationArea = All;
                Caption = 'Combination types';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Components;
                RunObject = page "Combinacion contenedores";
            }
        }
    }*/
}
