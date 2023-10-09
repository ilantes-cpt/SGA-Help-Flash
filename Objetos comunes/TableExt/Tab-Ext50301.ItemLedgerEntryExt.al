tableextension 50301 "Item Ledger Entry Ext" extends "Item Ledger Entry"
{
    fields
    {
        field(50300; Contenedor; Code[20])
        {
            Caption = 'Container';
            DataClassification = ToBeClassified;
            TableRelation = Contenedores;
        }
    }
}
