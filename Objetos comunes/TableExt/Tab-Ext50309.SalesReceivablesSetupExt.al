tableextension 50309 "Sales & Receivables Setup Ext." extends "Sales & Receivables Setup"
{
    fields
    {
        field(50300; "Plantilla regularizacion producto"; Code[10])
        {
            Caption = 'Plantilla regularizacion producto';
            TableRelation = "Item Journal Template";
        }
        field(50301; "Seccion regularizacion producto"; Code[10])
        {
            Caption = 'Seccion regularizacion producto';
            TableRelation = "Item Journal Batch".Name WHERE("Journal Template Name" = FIELD("Plantilla regularizacion producto"));
        }
    }
}
