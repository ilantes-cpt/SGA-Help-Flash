table 50306 "Historicos IMEI"
{
    Caption = 'Historicos IMEI';
    DataClassification = ToBeClassified;

    fields
    {

        field(1; IMEI; Code[20])
        {
            Caption = 'IMEI';
        }
        field(2; "Nº abono venta"; Code[20])
        {
            Caption = 'Nº abono venta';
        }
        field(3; "Fecha registro abono"; Date)
        {
            Caption = 'Fecha registro abono';
        }
        field(4; "Nº factura venta"; Code[20])
        {
            Caption = 'Nº factura venta';
        }
        field(5; "Fecha registro factura"; Date)
        {
            Caption = 'Fecha registro factura';
        }
        field(6; "Nº pedido compra"; Code[20])
        {
            Caption = 'Nº pedido compra';
            FieldClass = FlowField;
            CalcFormula = lookup(AzmHFBreakdownPallet.OrderNo where(UnitNo = field(IMEI)));
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
