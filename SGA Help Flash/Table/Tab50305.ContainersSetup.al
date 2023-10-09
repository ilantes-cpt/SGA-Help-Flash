table 50305 "Containers Setup"
{
    Caption = 'Containers Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "Ud. medida Pallet"; Code[20])
        {
            Caption = 'Palet Unit of Measure';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
        }
        field(3; "Ud. medida. Caja"; Code[20])
        {
            Caption = 'Box Unit of Measure';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
        }
        field(4; "Tipo pallet"; Code[20])
        {
            Caption = 'Palet type';
            DataClassification = ToBeClassified;
            TableRelation = "Tipo contenedor".Tipo;
        }
        field(5; "Tipo caja"; Code[20])
        {
            Caption = 'Box type';
            DataClassification = ToBeClassified;
            TableRelation = "Tipo contenedor".Tipo;
        }
        field(6; "Contenedor devoluciones"; Code[20])
        {
            Caption = 'Returns Container';
            DataClassification = ToBeClassified;
        }
        field(7; "Comprobación pallets/cajas"; Boolean)
        {
            Caption = 'Pallet/Box Check';
            DataClassification = ToBeClassified;
        }
        field(8; "Libro registro productos"; Code[10])
        {
            Caption = 'Item Log Book';
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Template";
        }
        field(9; "Sección registro productos"; Code[10])
        {
            Caption = 'Item Registration Section';
            DataClassification = ToBeClassified;
            TableRelation = "Item Journal Batch".Name WHERE("Journal Template Name" = FIELD("Libro registro productos"));
        }
        field(10; "No. Serie Prod"; Code[20])
        {
            Caption = 'No. Series Item';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
