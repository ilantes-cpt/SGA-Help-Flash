table 50304 "Selector Contenedores"
{
    Caption = 'Selector Container';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; Tipo; Code[20])
        {
            Caption = 'Type';
            DataClassification = ToBeClassified;
            TableRelation = "tipo contenedor".Tipo;
        }
        field(2; "Código"; Code[20])
        {
            Caption = 'Code';
        }
        field(3; Cantidad; Decimal)
        {
            Caption = 'Quantity';
        }
        field(4; "Cantidad base"; Decimal)
        {
            Caption = 'Quantity (base)';
        }
        field(5; FiltroAlmacen; code[20])
        {
            Caption = 'Filter Warehouse';
            FieldClass = FlowFilter;
        }
        field(6; FiltroProd; code[20])
        {
            Caption = 'Filter Item';
            FieldClass = FlowFilter;
        }
        field(7; FiltroPalet; code[20])
        {
            Caption = 'Filter Pallet';
            fieldclass = flowfilter;
        }
        field(8; FiltroCaja; code[20])
        {
            Caption = 'Filter Box';
            fieldclass = flowfilter;
        }
        field(9; FiltroPedido; code[20])
        {
            Caption = 'Filter Order';
            fieldclass = flowfilter;
        }
        field(10; FiltroLinea; integer)
        {
            Caption = 'Filter Line';
            fieldclass = flowfilter;
        }
        field(11; Generado; boolean)
        {
            Caption = 'Generated';
        }
        field(12; FiltroPedidoTransf; code[20])
        {
            Caption = 'Filter Transfer Order';
            fieldclass = flowfilter;
        }
        field(13; FiltroLineaTransf; integer)
        {
            Caption = 'Filter Transfer Line';
            fieldclass = flowfilter;
        }
        field(14; FiltroPedidoRecep; code[20])
        {
            Caption = 'Filter Receipt Order';
            FieldClass = FlowFilter;
        }
        field(15; FiltroLineaRecep; integer)
        {
            Caption = 'Filter Receipt line';
            FieldClass = FlowFilter;
        }
        field(16; FiltroPedidoEnvio; code[20])
        {
            Caption = 'Filter Shipment Order';
            FieldClass = FlowFilter;
        }
        field(17; FiltroLineaEnvio; integer)
        {
            Caption = 'Filter Shipment line';
            FieldClass = FlowFilter;
        }
        field(18; FiltroNombreDiario; code[20])
        {
            Caption = 'Filter Journal Name';
            FieldClass = FlowFilter;
        }
        field(19; FiltroSeccionDiario; code[20])
        {
            Caption = 'Filter Section Journal';
            FieldClass = FlowFilter;
        }
        field(20; FiltroLineaDiario; integer)
        {
            Caption = 'Filter Item Journal Line';
            FieldClass = FlowFilter;
        }
        field(21; FiltroPedidoEnsamblado; code[20])
        {
            Caption = 'Filter Assembly Order';
            FieldClass = FlowFilter;
        }
        field(22; FiltroLineaPedidoEnsamblado; integer)
        {
            Caption = 'Filter Line Assembly Order';
            FieldClass = FlowFilter;
        }
    }
    keys
    {
        key(PK; Tipo, "Código")
        {
            Clustered = true;
        }
    }

    procedure MultiplicadorBase(cProd: code[20]) dMultiplicador: Decimal
    var
        rConf: Record "Containers Setup";
        rIUOM: Record "Item Unit of Measure";
    begin
        dMultiplicador := 0;
        if (cProd = '') and (Tipo = '') then exit(dMultiplicador);
        rconf.get;
        rIUOM.reset;
        rIUOM.SetRange("Item No.", cProd);
        case tipo of
            rconf."Tipo caja":
                rIUOM.SetRange(Code, rconf."Ud. medida. Caja");
            rconf."Tipo pallet":
                rIUOM.SetRange(Code, rconf."Ud. medida Pallet");
            '':
                begin
                    dMultiplicador := 1;
                    exit(dMultiplicador);
                end;
        end;
        if rIUOM.find('-') then dMultiplicador := rIUOM."Qty. per Unit of Measure";
    end;

    procedure MultiplicadorBaseTipo(cTipo: code[20]; cProd: code[20]) dMultiplicador: Decimal
    var
        rConf: Record "Containers Setup";
        rIUOM: Record "Item Unit of Measure";
    begin
        dMultiplicador := 0;
        if (cProd = '') and (Tipo = '') then exit(dMultiplicador);
        rconf.get;
        rIUOM.reset;
        rIUOM.SetRange("Item No.", cProd);
        case ctipo of
            rconf."Tipo caja":
                rIUOM.SetRange(Code, rconf."Ud. medida. Caja");
            rconf."Tipo pallet":
                rIUOM.SetRange(Code, rconf."Ud. medida Pallet");
            '':
                begin
                    dMultiplicador := 1;
                    exit(dMultiplicador);
                end;
        end;
        if rIUOM.find('-') then dMultiplicador := rIUOM."Qty. per Unit of Measure";
    end;
}
