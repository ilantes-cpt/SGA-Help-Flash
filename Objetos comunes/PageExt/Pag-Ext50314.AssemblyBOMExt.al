pageextension 50314 "Assembly BOM Ext" extends "Assembly BOM"
{
    layout
    {
        addafter("Unit of Measure Code")
        {
            field("Consumption Location"; Rec."Consumption Location")
            {
                ApplicationArea = all;
            }
        }

    }
}
