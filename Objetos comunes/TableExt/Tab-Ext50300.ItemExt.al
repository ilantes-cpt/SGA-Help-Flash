tableextension 50300 "Item Ext." extends Item
{
    fields
    {
        field(50300; "Gestión de contenedores"; Boolean)
        {
            Caption = 'Containers Management';
            DataClassification = ToBeClassified;
        }
        /*field(50301; "Baja producto asociado"; Boolean)
        {
            Caption = 'Terminate an Associated Item';
            DataClassification = ToBeClassified;
        }
        field(50302; "Código producto asociado"; Code[20])
        {
            Caption = 'Associated Item Code';
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }*/
        field(50303; "Gestión de IMSIs"; Boolean)
        {
            Caption = 'IMSI Management';
            DataClassification = ToBeClassified;
        }
        field(50304; "Fecha caducidad"; DateFormula)
        {
            Caption = 'Expiration date';
            DataClassification = ToBeClassified;
        }
    }
}
