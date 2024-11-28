pageextension 50315 "Location Card Ext." extends "Location Card"
{
    layout
    {
        addafter("Use As In-Transit")
        {
            field("Contenedor devoluciones"; Rec."Contenedor devoluciones")
            {
                ApplicationArea = all;
            }
        }
    }
}
