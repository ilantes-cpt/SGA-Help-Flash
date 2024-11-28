tableextension 50304 "Purchases & Payables Setup Ext" extends "Purchases & Payables Setup"
{
    fields
    {
        field(50300; "Paquetes de datos"; Code[20])
        {
            Caption = 'Data Packages';
            DataClassification = ToBeClassified;
            TableRelation = Item;
            ObsoleteState = Removed;
            ObsoleteReason = 'No es necesario';
            ObsoleteTag = '20230928';
        }
        field(50301; ConsumirPaquetes; Boolean)
        {
            Caption = 'Consume Data Packages';
            DataClassification = ToBeClassified;
        }
    }
}
