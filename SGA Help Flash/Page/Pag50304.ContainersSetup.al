page 50304 "Containers Setup"
{
    ApplicationArea = All;
    Caption = 'Containers Setup';
    PageType = Card;
    SourceTable = "Containers Setup";
    //InsertAllowed = false;
    //DeleteAllowed = false;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Tipo pallet"; Rec."Tipo pallet")
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field("Ud. medida Pallet"; Rec."Ud. medida Pallet")
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field("Tipo caja"; Rec."Tipo caja")
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field("Ud. medida. Caja"; Rec."Ud. medida. Caja")
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field("Comprobación pallets/cajas"; Rec."Comprobación pallets/cajas")
                {
                    ApplicationArea = all;
                    Editable = true;
                }
                field("Libro registro productos"; Rec."Libro registro productos")
                {
                    ApplicationArea = all;
                }
                field("Sección registro productos"; Rec."Sección registro productos")
                {
                    ApplicationArea = all;
                }
                field("No. Serie Prod"; Rec."No. Serie Prod")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
