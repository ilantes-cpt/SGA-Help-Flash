table 50301 "Tipo contenedor"
{
    Caption = 'Container Type';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Tipo; Code[20])
        {
            Caption = 'Type';
            DataClassification = ToBeClassified;
        }
        field(2; Descripcion; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; "Nº Serie"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series".Code;
        }
        field(4; Fungible; Boolean)
        {
            Caption = 'Fungible';
            DataClassification = ToBeClassified;
            ObsoleteState = Removed;
            ObsoleteReason = 'No es necesario';
            ObsoleteTag = '20231227';
        }
        field(5; "Admite nivel superior"; Boolean)
        {
            Caption = 'Supports Higher Level';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; Tipo)
        {
            Clustered = true;
        }
    }
}
