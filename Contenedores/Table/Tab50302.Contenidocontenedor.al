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
            NotBlank = true;

            /*
            trigger OnValidate()
            begin
                ValidarPadre();
            end;
            */
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
            DataClassification = ToBeClassified;
            /*
            FieldClass = FlowField;
            CalcFormula = lookup(Contenedores.Padre where("Código" = field("Código")));
            */
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
        field(11; PedTrans; code[20])
        {
            Caption = 'Transfer Order';
            DataClassification = ToBeClassified;
        }
        field(12; LinPedTrans; integer)
        {
            Caption = 'Transfer Order Line';
            DataClassification = ToBeClassified;
        }
        field(13; "Nº albarán venta"; Code[20])
        {
            Caption = 'Sales Shipment No.';
            DataClassification = ToBeClassified;
        }
        field(14; "Cód. Almacén"; Code[20])
        {
            Caption = 'Warehouse Code';
            DataClassification = ToBeClassified;
            TableRelation = Location.Code;
            ValidateTableRelation = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'No es necesario';
            ObsoleteTag = '20231227';
        }
        field(15; EnvioAlm; code[20])
        {
            Caption = 'Warehouse Shipment';
            DataClassification = ToBeClassified;
        }
        field(16; LinEnvio; integer)
        {
            Caption = 'Warehouse Shipment Line';
            DataClassification = ToBeClassified;
        }
        field(17; RecepAlm; code[20])
        {
            Caption = 'Warehouse Receipt';
            DataClassification = ToBeClassified;
        }
        field(18; LinRecep; integer)
        {
            Caption = 'Warehouse Receipt Line';
            DataClassification = ToBeClassified;
        }
        field(19; "Nº Albarán Compra"; Code[20])
        {
            Caption = 'Purch. Rcpt. No.';
            DataClassification = ToBeClassified;
            TableRelation = "Purch. Rcpt. Header"."No.";
        }
        field(20; "Libro registro productos"; Code[10])
        {
            Caption = 'Item Log Book';
            DataClassification = ToBeClassified;
            //TableRelation = "Item Journal Template";
        }
        field(21; "Sección registro productos"; Code[10])
        {
            Caption = 'Item Registration Section';
            DataClassification = ToBeClassified;
            //TableRelation = "Item Journal Batch".Name WHERE("Journal Template Name" = FIELD("Libro registro productos"));
        }
        field(22; LinDiario; integer)
        {
            Caption = 'Item Journal Line No.';
            DataClassification = ToBeClassified;
        }
        field(23; "Cód Almacén"; Code[20])
        {
            Caption = 'Warehouse Code';
            FieldClass = FlowField;
            CalcFormula = lookup(Contenedores."Almacén" where("Código" = field("Código")));
        }
        field(24; PedCompra; code[20])
        {
            Caption = 'Purchase Order';
            DataClassification = ToBeClassified;
        }
        field(25; LinPedCompra; integer)
        {
            Caption = 'Purchase Order Line';
            DataClassification = ToBeClassified;
        }
        field(26; Endocumento; Boolean)
        {
            Caption = 'Selected in document';
            DataClassification = ToBeClassified;
        }
        field(27; Incidencia; Boolean)
        {
            Caption = 'Incidence';
            DataClassification = ToBeClassified;
        }
        field(28; Solved; Enum ResolucionCliente)
        {
            Caption = 'Solved';
            DataClassification = ToBeClassified;
        }
        field(29; Baja; Enum ResolucionInterna)
        {
            Caption = 'Baja';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                Validate(Vendido, true);
            end;
        }
        field(30; DevVenta; code[20])
        {
            Caption = 'Sales Return';
            DataClassification = ToBeClassified;
        }
        field(31; LinDevVenta; integer)
        {
            Caption = 'Sales Return Line';
            DataClassification = ToBeClassified;
        }
        field(32; "Nº albarán devolucion"; Code[20])
        {
            Caption = 'Sales Return No.';
            DataClassification = ToBeClassified;
        }
        field(33; IncidenceDate; Date)
        {
            Caption = 'Incidence date';
            DataClassification = ToBeClassified;
        }
        field(34; "Nº pedido ensamblado"; Code[20])
        {
            Caption = 'Nº pedido ensamblado';
            DataClassification = SystemMetadata;
        }
        field(35; "Nº linea pedido ensamblado"; Integer)
        {
            Caption = 'Nº linea pedido ensamblado';
            DataClassification = SystemMetadata;
        }
        field(36; "Nº abono venta"; Code[20])
        {
            Caption = 'Nº abono venta';
            DataClassification = SystemMetadata;
        }
        field(37; "Nº linea abono venta"; Integer)
        {
            Caption = 'Nº linea abono venta';
            DataClassification = SystemMetadata;
        }
        field(38; "Almacen reasignado"; Boolean)
        {
            Caption = 'Almacén reasignado';
            DataClassification = SystemMetadata;
        }
        field(39; "Tipo incidencia"; enum TipoIncidencia)
        {
            Caption = 'Tipo incidencia';
            DataClassification = SystemMetadata;
        }
        field(40; "Anulacion del pedido"; Boolean)
        {
            Caption = 'Anulacion del pedido';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; "Código", "Nº producto", IMEI)
        {
            Clustered = true;
        }
        key(PK1; IMEI)
        {
        }
        key(PK2; "Código")
        {
        }
        key(PK3; "Código", "Nº producto", Endocumento)
        {
        }
        key(PK4; Padre, "Nº producto", Endocumento)
        {
        }
    }

    trigger OnModify()
    begin
        VerificarDocumento();
    end;

    procedure VerificarDocumento()
    begin
        if (rec.PedVenta <> '') or (rec.PedTrans <> '') or (Rec.EnvioAlm <> '') or (Rec.RecepAlm <> '') or (Rec."Sección registro productos" <> '')
         or (rec.DevVenta <> '') or (Rec."Nº pedido ensamblado" <> '') or (Rec."Nº abono venta" <> '') then /*(rec.PedCompra <> '') or */
            Rec.Validate(Endocumento, true)
        else
            Rec.Validate(Endocumento, false);
    end;

    /*
    procedure ValidarPadre()
    var
        rContenedor: Record Contenedores;
    begin
        if rcontenedor.get(Rec."Código") then
            Rec.Validate(Rec.Padre,rContenedor.Padre);
    end;
    */
}
