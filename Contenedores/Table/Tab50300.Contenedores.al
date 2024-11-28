table 50300 Contenedores
{
    Caption = 'Containers';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Código"; Code[20])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;
            NotBlank = true;

            trigger OnValidate()
            begin
                //Comprobamos si, el tipo, tiene nº de serie y/o se puede introducir de forma manual
                rtipo.Get(tipo);
                if rTipo."Nº Serie" <> '' then begin
                    if "Código" <> '' then begin
                        cNoSeries.TestManual(rTipo."Nº Serie");
                    end else begin
                        validate("código", cNoSeries.TryGetNextNo(rTipo."Nº Serie", workdate));
                    end;
                end else
                    TestField("Código");

            end;
        }
        field(2; "Descripción"; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; "Almacén"; Code[20])
        {
            Caption = 'Warehouse';
            DataClassification = ToBeClassified;
            TableRelation = Location.Code;
            ValidateTableRelation = false;
        }
        field(4; Ubicacion; Code[20])
        {
            Caption = 'Bin';
            DataClassification = ToBeClassified;
            TableRelation = bin.Code where("Zone Code" = field(Zona), "Location Code" = field("Almacén"));
            //TableRelation = bin.Code where("Zone Code" = field(Zona));
            ValidateTableRelation = false;
        }
        field(5; Tipo; Code[20])
        {
            Caption = 'Type';
            DataClassification = ToBeClassified;
            TableRelation = "Tipo contenedor".Tipo;
        }
        field(6; Padre; Code[20])
        {
            //Nivel superior
            Caption = 'Father';
            DataClassification = ToBeClassified;
            TableRelation = Contenedores."Código";

            trigger OnValidate()
            var
                cContenedores: Codeunit Contenedores;
            begin
                IF NOT Rec.Insert() THEN Rec.Modify();
                //Validamos el padre en contenido contenedor
                cContenedores.ValidaPadreContenido(Rec."Código", Rec.Padre);
                if Rec."Código" = Rec.Padre then
                    error(lErrNoSeleccionable);
                if not cContenedores.VerificarAsignacionContenedor(Rec."Código", Rec.Padre) then
                    Error(lErr006);
            end;
        }
        field(7; Huecos; Integer)
        {
            Caption = 'Gaps';
            DataClassification = ToBeClassified;
        }
        field(8; Zona; Code[20])
        {
            Caption = 'Zone';
            DataClassification = ToBeClassified;
            TableRelation = Zone.Code where("Location Code" = field("Almacén"));
            ValidateTableRelation = false;
        }
        field(9; FiltroProducto; code[20])
        {
            Caption = 'Filter Item';
            FieldClass = FlowFilter;
        }
        field(10; ContieneProductoFiltradoCaja; Boolean)
        {
            Caption = 'Contains Filtered Item Box';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), "Cód. Almacén" = field("Almacén"), PedVenta = field(FiltroPedido), LinPedVenta = field(FiltroLinea)));
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), PedVenta = field(FiltroPedido), LinPedVenta = field(FiltroLinea)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), Endocumento = const(false), Vendido = field(filtrovendido)));
        }
        field(11; ContieneProductoFiltradoPallet; Boolean)
        {
            Caption = 'Contains Filtered Item Pallet';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), "Cód. Almacén" = field("Almacén"), PedVenta = field(FiltroPedido), LinPedVenta = field(FiltroLinea)));
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), PedVenta = field(FiltroPedido), LinPedVenta = field(FiltroLinea)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), Endocumento = const(false), Vendido = field(filtrovendido)));
        }
        field(12; FiltroPedido; code[20])
        {
            Caption = 'Filter Order';
            FieldClass = FlowFilter;
        }
        field(13; FiltroLinea; integer)
        {
            Caption = 'Filter Line';
            FieldClass = FlowFilter;
        }
        field(14; FiltroVendido; Boolean)
        {
            Caption = 'Filter sell';
            FieldClass = FlowFilter;
        }
        /*
        field(14; ContieneProductoFiltradoCajaTr; Boolean)
        {
            Caption = 'Contains Filtered Item Box';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), "Cód. Almacén" = field("Almacén"), PedTrans = field(FiltroPedidoTransf), LinPedTrans = field(FiltroLineaTransf)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), PedTrans = field(FiltroPedidoTransf), LinPedTrans = field(FiltroLineaTransf)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        */
        field(15; ContieneProductoFiltPalletTr; Boolean)
        {
            Caption = 'Contains Filtered Item Pallet';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), "Cód. Almacén" = field("Almacén"), PedTrans = field(FiltroPedidoTransf), LinPedTrans = field(FiltroLineaTransf)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), PedTrans = field(FiltroPedidoTransf), LinPedTrans = field(FiltroLineaTransf)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(16; FiltroPedidoTransf; code[20])
        {
            Caption = 'Filter Transfer Order';
            FieldClass = FlowFilter;
        }
        field(17; FiltroLineaTransf; integer)
        {
            Caption = 'Filter Transfer Line';
            FieldClass = FlowFilter;
        }
        field(18; ContieneProductoFiltradoCajaRc; Boolean)
        {
            Caption = 'Contains Filtered Item Box';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), "Cód. Almacén" = field("Almacén"), RecepAlm = field(FiltroPedidoRecep), LinRecep = field(FiltroLineaRecep)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), RecepAlm = field(FiltroPedidoRecep), LinRecep = field(FiltroLineaRecep)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(19; ContieneProductoFiltPalletRc; Boolean)
        {
            Caption = 'Contains Filtered Item Pallet';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), "Cód. Almacén" = field("Almacén"), RecepAlm = field(FiltroPedidoRecep), LinRecep = field(FiltroLineaRecep)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), RecepAlm = field(FiltroPedidoRecep), LinRecep = field(FiltroLineaRecep)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(20; FiltroPedidoRecep; code[20])
        {
            Caption = 'Filter Receipt Order';
            FieldClass = FlowFilter;
        }
        field(21; FiltroLineaRecep; integer)
        {
            Caption = 'Filter Receipt line';
            FieldClass = FlowFilter;
        }
        field(22; ContieneProductoFiltradoCajaEn; Boolean)
        {
            Caption = 'Contains Filtered Item Box';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), "Cód. Almacén" = field("Almacén"), EnvioAlm = field(FiltroPedidoEnvio), LinEnvio = field(FiltroLineaEnvio)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), EnvioAlm = field(FiltroPedidoEnvio), LinEnvio = field(FiltroLineaEnvio)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(23; ContieneProductoFiltPalletEn; Boolean)
        {
            Caption = 'Contains Filtered Item Pallet';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), "Cód. Almacén" = field("Almacén"), EnvioAlm = field(FiltroPedidoEnvio), LinEnvio = field(FiltroLineaEnvio)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), EnvioAlm = field(FiltroPedidoEnvio), LinEnvio = field(FiltroLineaEnvio)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(24; FiltroPedidoEnvio; code[20])
        {
            Caption = 'Filter Shipment Order';
            FieldClass = FlowFilter;
        }
        field(25; FiltroLineaEnvio; integer)
        {
            Caption = 'Filter Shipment line';
            FieldClass = FlowFilter;
        }
        field(26; "Nº Albarán Compra"; Code[20])
        {
            Caption = 'Purch. Rcpt. No.';
            DataClassification = ToBeClassified;
            TableRelation = "Purch. Rcpt. Header"."No.";
        }
        field(27; FiltroNombreDiario; code[20])
        {
            Caption = 'Filter Journal Name';
            FieldClass = FlowFilter;
        }
        field(28; FiltroSeccionDiario; code[20])
        {
            Caption = 'Filter Section Journal';
            FieldClass = FlowFilter;
        }
        field(29; ContieneProductoFiltradoCajaDi; Boolean)
        {
            Caption = 'Contains Filtered Item Box';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), "Cód. Almacén" = field("Almacén"), "Libro registro productos" = field(FiltroNombreDiario), "Sección registro productos" = field(FiltroSeccionDiario), LinDiario = field(FiltroLineaDiario)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), "Código" = field("Código"), "Libro registro productos" = field(FiltroNombreDiario), "Sección registro productos" = field(FiltroSeccionDiario), LinDiario = field(FiltroLineaDiario)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(30; ContieneProductoFiltPalletDi; Boolean)
        {
            Caption = 'Contains Filtered Item Pallet';
            FieldClass = FlowField;
            //CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), "Cód. Almacén" = field("Almacén"), "Libro registro productos" = field(FiltroNombreDiario), "Sección registro productos" = field(FiltroSeccionDiario), LinDiario = field(FiltroLineaDiario)));
            CalcFormula = exist("Contenido contenedor" where("Nº producto" = field(FiltroProducto), Padre = field("Código"), "Libro registro productos" = field(FiltroNombreDiario), "Sección registro productos" = field(FiltroSeccionDiario), LinDiario = field(FiltroLineaDiario)));
            ObsoleteState = Removed;
            ObsoleteReason = 'No se utiliza más';
        }
        field(31; FiltroLineaDiario; integer)
        {
            Caption = 'Filter Item Journal Line';
            FieldClass = FlowFilter;
        }
        field(32; QtyOnContainer; Decimal)
        {
            Caption = 'Qty. on container';
            FieldClass = FlowField;
            CalcFormula = sum("Contenido contenedor".Cantidad WHERE("Código" = field("Código"), "Nº producto" = FIELD(FILTROPRODUCTO)));//, "Nº producto" = filter()));
        }
        field(33; QtyOnFatherContainer; Decimal)
        {
            Caption = 'Qty. on father container';
            FieldClass = FlowField;
            CalcFormula = sum("Contenido contenedor".Cantidad WHERE(Padre = field("Código"), "Nº producto" = FIELD(FILTROPRODUCTO)));//, "Nº producto" = filter()));
        }
    }
    keys
    {
        key(PK; "Código")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        cContenedores: Codeunit Contenedores;
    begin
        //VerificarUbicacion(true);
        if Rec."Código" = '' then
            Error(lErr002);
    end;

    trigger OnModify()
    begin
        //VerificarUbicacion(true);
    end;

    trigger OnDelete()
    var
        rContCont: Record "Contenido contenedor";

    begin
        //VerificarUbicacion(false);
        if Rec."Código" <> '' then begin
            rContCont.reset;
            rContCont.SetRange(Padre, Rec."Código");
            if rContCont.find('-') then
                Error(lErr001);
            rContCont.reset;
            rContCont.SetRange("Código", Rec."Código");
            if rContCont.find('-') then
                Error(lErr001);
        end;
    end;

    trigger OnRename()
    begin
        error(lErrRen);
    end;

    /*procedure VerificarUbicacion(bInsertar: Boolean)
    begin
        if bInsertar then begin
            if not rBin.get(Rec."Almacén", Rec."Código") then
                if rtipo.get(Rec.Tipo) then
                    CrearUbicacion(rTipo.DefaultLocation);
        end else begin
            if rbin.get(Rec."Almacén", Rec."Código") then
                rbin.Delete();
        end;
    end;

    procedure CrearUbicacion(cAlm: code[20])
    begin
        rtipo.get(Rec.Tipo);
        if not rtipo.CreateAsBin then
            exit;
        rloc.get(cAlm);
        rbin.Init();
        rbin.validate("Location Code", cAlm);
        rbin.Validate(Code, rec."Código");
        rbin.Validate("Zone Code", rloc.BufferZone);
        rbin.Validate(Description, 'Buffer ' + rec."Código");
        if not rbin.Insert() then rbin.Modify();
    end;*/

    var
        cNoSeries: Codeunit NoSeriesManagement;
        rTipo: Record "Tipo contenedor";
        rBin: Record bin;
        rLoc: Record Location;
        lErrRen: Label 'Cannot rename a container';
        lErrNoSeleccionable: label 'The same container cannot be selected as a parent';
        lErr006: label 'This type of combination it''s not allowed';
        lErr001: Label 'The container cannot be deleted until the existing content is removed or moved.', comment = 'ESP="No se puede eliminar el contenedor hasta eliminar o mover el contenido existente."';
        lErr002: Label 'Cannot create a pallet without code', comment = 'ESP="No se puede crear un palet sin código"';
}
