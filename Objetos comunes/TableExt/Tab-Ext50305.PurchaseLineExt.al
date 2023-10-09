tableextension 50305 "Purchase Line Ext" extends "Purchase Line"
{
    fields
    {
        field(50300; "Nº Lote"; Integer)
        {
            Caption = 'Lot No.';
            DataClassification = ToBeClassified;
        }
    }
}
