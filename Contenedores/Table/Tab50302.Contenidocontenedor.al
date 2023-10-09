table 50302 "Contenido contenedor"
{
    Caption = 'Container Content';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Código"; Code[20])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;
        }
        field(2; "Nº producto"; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
        }
        field(3; Cantidad; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;

            /*
            trigger OnValidate()
            begin
                Rec.Validate(Cantidad, 1);
            end;
            */
        }
        field(4; "Unidad de medida"; Code[20])
        {
            Caption = 'Unit Of Measure';
            DataClassification = ToBeClassified;
        }
        field(5; IMEI; Code[20])
        {
            Caption = 'IMEI';
            DataClassification = ToBeClassified;
        }
        field(6; Caducidad; Date)
        {
            Caption = 'Expiry';
            DataClassification = ToBeClassified;
        }
        field(7; Padre; code[20])
        {
            Caption = 'Father';
            FieldClass = FlowField;
            CalcFormula = lookup(Contenedores.Padre where("Código" = field("Código")));
        }
        field(8; PedVenta; code[20])
        {
            Caption = 'Sales Order';
            DataClassification = ToBeClassified;
        }
		field(9; LinPedVenta; integer)
        {
            Caption = 'Sales Order Line';
            DataClassification = ToBeClassified;
        }
        field(10; Vendido; Boolean)
        {
            Caption = 'Sold';
        }

    }
    keys
    {
        key(PK; "Código", "Nº producto", IMEI)
        {
            Clustered = true;
        }
    }
}
