table 50303 "Activaciones IMEI"
{
    Caption = 'IMEI Activations';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; IMEI; Code[20])
        {
            Caption = 'IMEI';
        }
        field(2; "Fecha activación"; Date)
        {
            Caption = 'Activation Date';
        }
        field(3; Coste; Decimal)
        {
            Caption = 'Cost';
        }
        field(4; "Fecha caducidad"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(5; "Fecha venta"; Date)
        {
            Caption = 'Sale Date';
        }
        field(6; Venta; Decimal)
        {
            Caption = 'Sale';
        }
    }
    keys
    {
        key(PK; IMEI)
        {
            Clustered = true;
        }
    }
}
