pageextension 50324 "Sales & Receivables Setup" extends "Sales & Receivables Setup"
{
    layout
    {
        addafter("Number Series")
        {
            group(ItemJournalSetup)
            {
                Caption = 'Regularización de stock';

                field("Plantilla regularizacion producto"; Rec."Plantilla regularizacion producto")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item journal template to use for negative adjustments.';
                }
                field("Seccion regularizacion producto"; Rec."Seccion regularizacion producto")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item journal batch to use for negative adjustments.';
                }
            }
        }
    }
}
