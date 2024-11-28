/*
page 50308 "Sel. Cont. Contenedor Transf."
{
    ApplicationArea = All;
    Caption = 'Selector Content Container Transf.';
    PageType = List;
    SourceTable = "Selector Contenedores";
    UsageCategory = Tasks;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            group(Contadores)
            {
                Editable = false;
                field(dTotal; dTotal)
                {
                    Caption = 'Total Quantity', comment = 'ESP="Cdad. total"';
                }
                field(dMarcada; dMarcada)
                {
                    Caption = 'Selected Quantity', comment = 'ESP="Cdad. seleccionada"';
                }
                field(dPendiente; dPendiente)
                {
                    Caption = 'Quantity Outstanding', comment = 'ESP="Cdad. pendiente"';
                }
            }
            repeater(General)
            {
                field(Tipo; Rec.Tipo)
                {
                }
                field("Código"; Rec."Código")
                {
                    trigger OnValidate()
                    begin
                        ValidarCodigo();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        BuscarCodigo();
                    end;
                }
                field(Cantidad; Rec.Cantidad)
                {
                    Editable = false;
                }
                field("Cantidad base"; Rec."Cantidad base")
                {
                    Editable = false;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        rContenedor: Record Contenedores;
    begin
        rconf.get;
        dPendiente += Rec."Cantidad base";
        dMarcada -= rec."Cantidad base";
        if Rec.generado then begin
            rContenido.reset;
            case Rec.Tipo of
                rconf."Tipo pallet":
                    begin
                        rcontenido.SetRange(Padre, Rec."Código");
                    end;
                rconf."Tipo caja":
                    begin
                        rcontenido.SetRange("Código", Rec."Código");
                    end;
                '':
                    begin
                        rcontenido.SetRange(IMEI, Rec."Código");
                    end;
            end;
            rcontenido.SetRange(PedTrans, cDocumento);
            rcontenido.SetRange(LinPedTrans, ilinea);
            if rContenido.find('-') then
                repeat
                    rcontenido.PedTrans := '';
                    rcontenido.LinPedTrans := 0;
                    rcontenido.Modify();
                until rContenido.Next() = 0;
        end;
        CurrPage.Update(true);
    end;

    trigger OnClosePage()
    var
        bValidar: Boolean;
    begin
        bValidar := false;
        if Rec.Count > 1 then bvalidar := true;
        if (rec.Count = 1) and (Rec."Código" <> '') and (rec.Cantidad <> 0) then bvalidar := true;
        if bvalidar then begin
            rec.setrange(generado, false);
            if rec.find('-') then
                repeat
                    case rec.Tipo of
                        rConf."Tipo pallet":
                            begin
                                //A nivel palet
                                rContenido.reset;
                                rContenido.SetRange(padre, rec."Código");
                                if rContenido.find('-') then
                                    repeat
                                        rContenido.Validate(PedTrans, cDocumento);
                                        rContenido.Validate(LinPedTrans, iLinea);
                                        rContenido.Modify(true);
                                    until rContenido.next() = 0
                            end;
                        rconf."Tipo caja":
                            begin
                                //A nivel caja
                                rContenido.reset;
                                rContenido.SetRange("Código", rec."Código");
                                if rContenido.find('-') then
                                    repeat
                                        rContenido.Validate(PedTrans, cDocumento);
                                        rContenido.Validate(LinPedTrans, iLinea);
                                        rContenido.Modify(true);
                                    until rContenido.next() = 0
                            end;
                        '':
                            begin
                                //A nivel IMEI
                                rContenido.reset;
                                rContenido.SetRange(IMEI, rec."Código");
                                if rContenido.find('-') then begin
                                    rContenido.Validate(PedTrans, cDocumento);
                                    rContenido.Validate(LinPedTrans, iLinea);
                                    rContenido.Modify(true);
                                end;
                            end;
                    end;
                until rec.Next() = 0;
            CurrPage.Update(true);
        end;
    end;

    procedure EstablecerDoc(cDoc: code[20]; iLin: Integer; dCantBase: Decimal; cAlm: code[10]; cProd: code[20])
    var
        dCaja, dPalet : Decimal;
        bGenerado: Boolean;
        dSeleccionado: Decimal;
    begin
        Rec.Init();
        rec.Insert();
        cDoc2 := '';
        cdocumento := cdoc;
        ilinea := ilin;
        dTotal := dCantBase;
        cAlmacen := calm;
        cProducto := cProd;
        rec.FilterGroup(2);
        Rec.SetFilter(FiltroAlmacen, calm);
        rec.SetFilter(FiltroProd, cProd);
        rconf.get();
        rec.SetFilter(FiltroCaja, rconf."Tipo caja");
        rec.setfilter(FiltroPalet, rconf."Tipo pallet");
        //rec.setfilter(FiltroPedidoTransf, '<>%1', cdoc);
        rec.setfilter(FiltroPedidoTransf, '<>%1&%2', cdoc, cDoc2);
        rec.setfilter(FiltroLineaTransf, '<>%1', iLin);
        rec.setfilter(FiltroPedido, '%1', '');
        rec.setfilter(FiltroLinea, '%1', 0);
        rec.setfilter(FiltroPedidoRecep, '%1', '');
        rec.setfilter(FiltroLineaRecep, '%1', 0);
        //rec.setfilter(FiltroPedidoEnvio, '%1', '');
        //rec.setfilter(FiltroLineaEnvio, '%1', 0);
        rec.FilterGroup(0);
        //Calculamos el total asignado para este pedido
        rContenido.reset;
        //rcontenido.setfilter("Código", '<>%1', '');
        rcontenido.SetRange(PedTrans, cdoc);
        rcontenido.SetRange(LinPedTrans, ilin);
        rContenido.SetRange(PedVenta, '');
        rContenido.SetRange(LinPedVenta, 0);
        rContenido.SetRange(RecepAlm, '');
        rContenido.SetRange(LinRecep, 0);
        //rContenido.SetRange(EnvioAlm, '');
        //rContenido.SetRange(LinEnvio, 0);
        if rcontenido.findset then begin
            if rContenido.CalcSums(Cantidad) then
                dMarcada := rContenido.Cantidad;
        end;
        dPendiente := dTotal - dMarcada;
        dcaja := rec.MultiplicadorbaseTipo(rconf."Tipo caja", cProducto);
        dpalet := rec.multiplicadorbasetipo(rconf."Tipo pallet", cProducto);
        //Generamos los registros existentes
        if rContenido.find('-') then
            repeat
                //rcontenido.CalcFields(Padre);
                bgenerado := false;
                //Comprobamos si ya esta creado el padre, en caso de estarlo, omitimos este registro
                rec.SetRange(Tipo, rConf."Tipo pallet");
                rec.Setrange("Código", rcontenido.padre);
                if rec.find('-') then bGenerado := true;
                rec.SetRange(Tipo, rConf."Tipo caja");
                rec.Setrange("Código", rcontenido."Código");
                if rec.find('-') then bGenerado := true;
                rContPadre.reset;
                rcontpadre.setrange(padre, rContenido.Padre);
                //rcontpadre.setfilter("Código", '<>%1', '');
                rcontpadre.setrange(PedTrans, cdocumento);
                rcontpadre.setrange(LinPedTrans, ilinea);
                rcontpadre.SetRange(PedVenta, '');
                rcontpadre.SetRange(LinPedVenta, 0);
                rContpadre.SetRange(RecepAlm, '');
                rContpadre.SetRange(LinRecep, 0);
                //rContpadre.SetRange(EnvioAlm, '');
                //rContpadre.SetRange(LinEnvio, 0);
                if rContPadre.findset then
                    if rcontpadre.calcsums(cantidad) then
                        if rcontpadre.cantidad = dpalet then
                            if InsertarRegistro(rconf."Tipo pallet", rcontenido.padre, dpalet) then begin
                                bGenerado := true;
                                dSeleccionado += rContPadre.Cantidad;
                            end;
                if not bgenerado then begin
                    rContPadre.reset;
                    rcontpadre.setrange("Código", rContenido."Código");
                    //rcontpadre.setfilter("Código", '<>%1', '');
                    rcontpadre.setrange(PedTrans, cdocumento);
                    rcontpadre.setrange(LinPedTrans, ilinea);
                    rcontpadre.SetRange(PedVenta, '');
                    rcontpadre.SetRange(LinPedVenta, 0);
                    rContpadre.SetRange(RecepAlm, '');
                    rContpadre.SetRange(LinRecep, 0);
                    //rContpadre.SetRange(EnvioAlm, '');
                    //rContpadre.SetRange(LinEnvio, 0);
                    if rContPadre.findset then begin
                        if rcontpadre.calcsums(cantidad) then
                            if rcontpadre.cantidad = dcaja then
                                if InsertarRegistro(rconf."Tipo caja", rContPadre."Código", dcaja) then begin
                                    bgenerado := true;
                                    dSeleccionado += rContPadre.Cantidad;
                                end;
                    end;
                end;
                if not bgenerado then begin
                    //Si no tenemos generada ni la caja ni el pallet, generamos el IMEI
                    Rec.setrange(Rec.tipo, rconf."Tipo pallet");
                    Rec.setrange(Rec."Código", rcontenido.Padre);
                    if not rec.findset then begin
                        Rec.setrange(Rec.tipo, rconf."Tipo caja");
                        Rec.setrange(Rec."Código", rcontenido."Código");
                        if not rec.findset then begin
                            if InsertarRegistro('', rcontenido.IMEI, 1) then begin
                                bgenerado := true;
                                dSeleccionado += 1;
                            end;
                            rec.setrange(Rec.tipo);
                            rec.SetRange(Rec."Código");
                        end;
                    end;
                end;
            until (rContenido.Next() = 0) or (dSeleccionado >= dMarcada);
        rec.setfilter(Rec.tipo, '%1', '');
        rec.setfilter(Rec."Código", '%1', '');
        rec.setfilter(Rec.cantidad, '0');
        rec.setfilter(Rec.Generado, '%1', false);
        if rec.find('-') then rec.delete(false);
        rec.setrange(Rec.tipo);
        rec.SetRange(Rec."Código");
        rec.setrange(Rec.cantidad);
        rec.setrange(Rec.Generado);
    end;

    var
        dTotal, dMarcada, dPendiente, dAsignacion, dCont : Decimal;
        cDocumento, cProducto : code[20];
        cDoc2: code[20];
        cAlmacen: code[10];
        iLinea: Integer;
        rContenido, rContPadre : Record "Contenido contenedor";
        rConf: Record "Containers Setup";
        pContenedor: page "Lista contenedores";
        pContenido: page "Contenido Cont.";
        rContenedor: Record Contenedores;

    local procedure BuscarCodigo()
    begin
        begin
            clear(pContenedor);
            clear(pContenido);
            rContenedor.reset();
            rContenido.Reset();
            rconf.get;
            case rec.tipo of
                rconf."Tipo caja":
                    begin
                        rcontenedor.SetRange("Almacén", cAlmacen);
                        rcontenedor.SetRange(Tipo, rconf."Tipo caja");
                        rcontenedor.SetRange(FiltroProducto, cProducto);
                        //rContenedor.SetRange(ContieneProductoFiltradoCajaTr, true);
                        //rContenedor.SetFilter(FiltroPedidoTransf, '<>%1&%2', cDocumento, cDoc2);
                        rContenedor.SetFilter(FiltroPedidoTransf, '<>%1', cDocumento);
                        rContenedor.SetFilter(FiltroLineaTransf, '<>%1', iLinea);
                        //rContenedor.SetRange(ContieneProductoFiltradoCaja, true);
                        rContenedor.SetFilter(FiltroPedido, '%1', cDoc2);
                        rContenedor.SetFilter(FiltroLinea, '%1', 0);
                        rContenedor.setfilter(FiltroPedidoRecep, '%1', cDoc2);
                        rContenedor.setfilter(FiltroLineaRecep, '%1', 0);
                        //rContenedor.setfilter(FiltroPedidoEnvio, '%1', cDoc2);
                        //rContenedor.setfilter(FiltroLineaEnvio, '%1', 0);
                        if rContenedor.find('-') then begin
                            pContenedor.SetTableView(rContenedor);
                            pContenedor.LookupMode := true;
                            pContenedor.EstablecerFiltrosSeleccion(cAlmacen, cProducto, cDocumento, iLinea);
                            if pContenedor.RunModal() = action::LookupOK then begin
                                pContenedor.GetRecord(rContenedor);
                                rec.Validate("Código", rContenedor."Código");
                            end;
                        end else
                            Message(lErr003);
                    end;
                rconf."Tipo pallet":
                    begin
                        rcontenedor.SetRange("Almacén", cAlmacen);
                        rcontenedor.SetRange(Tipo, rconf."Tipo pallet");
                        rcontenedor.SetRange(FiltroProducto, cProducto);
                        //rContenedor.SetRange(ContieneProductoFiltPalletTr, true);
                        //rContenedor.SetFilter(FiltroPedidoTransf, '<>%1&%2', cDocumento, cDoc2);
                        rContenedor.SetFilter(FiltroPedidoTransf, '<>%1', cDocumento);
                        rContenedor.SetFilter(FiltroLineaTransf, '<>%1', iLinea);
                        //rContenedor.SetRange(ContieneProductoFiltradoPallet, true);
                        rContenedor.SetFilter(FiltroPedido, '%1', cDoc2);
                        rContenedor.SetFilter(FiltroLinea, '%1', 0);
                        rContenedor.setfilter(FiltroPedidoRecep, '%1', cDoc2);
                        rContenedor.setfilter(FiltroLineaRecep, '%1', 0);
                        //rContenedor.setfilter(FiltroPedidoEnvio, '%1', cDoc2);
                        //rContenedor.setfilter(FiltroLineaEnvio, '%1', 0);
                        if rContenedor.find('-') then begin
                            pContenedor.SetTableView(rContenedor);
                            pContenedor.LookupMode := true;
                            pContenedor.EstablecerFiltrosSeleccion(cAlmacen, cProducto, cDocumento, iLinea);
                            if pContenedor.RunModal() = action::LookupOK then begin
                                pContenedor.GetRecord(rContenedor);
                                rec.Validate("Código", rContenedor."Código");
                            end;
                        end else
                            Message(lErr003);
                    end;
                '':
                    begin
                        rContenido.CalcFields("Cód Almacén");
                        rContenido.SetRange("Cód Almacén", cAlmacen);
                        rcontenido.SetRange("Nº producto", cProducto);
                        //rcontenido.setfilter("Código", '<>%1', '');
                        rcontenido.setfilter(PedTrans, '<>%1&%2', cDocumento, cDoc2);
                        rcontenido.SetFilter(LinPedTrans, '<>%1', iLinea);
                        rcontenido.SetRange(PedVenta, '');
                        rcontenido.SetRange(LinPedVenta, 0);
                        rContenido.SetRange(RecepAlm, '');
                        rContenido.SetRange(LinRecep, 0);
                        //rContenido.SetRange(EnvioAlm, '');
                        //rContenido.SetRange(LinEnvio, 0);
                        if rContenido.find('-') then begin
                            pContenido.SetTableView(rContenido);
                            pContenido.LookupMode := true;
                            if pContenido.RunModal() = action::LookupOK then begin
                                pContenido.GetRecord(rContenido);
                                rec.Validate("Código", rContenido.IMEI);
                            end;
                        end else
                            Message(lErr003);
                    end;
            end;
        end;
        if rec."Código" <> '' then
            ValidarCodigo();
    end;

    local procedure ValidarCodigo()
    var
        rSelec: Record "Selector Contenedores";
        lText0001: Label 'This box is not fully available, there are %1 used slots, do you want to include the rest of the units?', comment = 'ESP="Esta caja no está totalmente disponible, hay %1 huecos usados. ¿Desea incluir el resto de unidades?"';
        lErr0003: Label 'This container cannot be selected as it is not fully available, there are %1 used gaps.', comment = 'ESP="Este contenedor no se puede seleccionar al no estar totalmente disponible, hay %1 huecos usados"';
    begin
        rcontenido.reset;
        rContenido.CalcFields("Cód Almacén");
        rContenido.SetRange("Cód Almacén", cAlmacen);
        rcontenido.SetRange("Nº producto", cProducto);
        //rcontenido.setfilter("Código", '<>%1', '');
        rcontenido.SetFilter(PedTrans, '<>%1', cDocumento);
        rcontenido.SetFilter(LinPedTrans, '<>%1', iLinea);
        rcontenido.SetRange(PedVenta, '');
        rcontenido.SetRange(LinPedVenta, 0);
        rContenido.SetRange(RecepAlm, '');
        rContenido.SetRange(LinRecep, 0);
        //rContenido.SetRange(EnvioAlm, '');
        //rContenido.SetRange(LinEnvio, 0);
        rconf.get;
        case rec.tipo of
            rconf."Tipo caja":
                begin
                    rContenido.setrange("Código", Rec."Código");
                    if rContenido.findset then
                        if rContenido.CalcSums(Cantidad) then begin
                            dCont := rContenido.Cantidad;
                            if rContenido.Cantidad < Rec.MultiplicadorBase(cProducto) then begin
                                //if not Confirm(lText0001, true, dCont) then begin
                                //rSelec := Rec;
                                //Rec."Cantidad base" := 0;
                                //Rec.Cantidad := 0;
                                //Rec.Modify();
                                //if rSelec.Get(Rec.Tipo, Rec."Código") then
                                //rSelec.Delete();
                                //Rec := rSelec;
                                //rec.Insert();
                                //CurrPage.Update(true);
                                error(lErr0003, rContenido.Cantidad);
                                //end;
                            end;
                        end;
                end;
            rconf."Tipo pallet":
                begin
                    rContenido.setrange(Padre, Rec."Código");
                    if rContenido.findset then
                        if rContenido.CalcSums(Cantidad) then
                            if rContenido.Cantidad < Rec.MultiplicadorBase(cProducto) then begin
                                error(lErr0003, rContenido.Cantidad);
                            end;
                end;
        end;
        //if rec."Código" <> '' then begin
        Rec.validate(Cantidad, 1);
        ValidaCantidad();
        //end;
    end;

    local procedure ValidaCantidad()
    var
        dDif, dMultiplicador : Decimal;
    begin
        rconf.Get();
        //if rec.tipo = rconf."Tipo caja" then
        //dMultiplicador := dCont
        //else
        dMultiplicador := rec.MultiplicadorBase(cProducto);
        if Rec.Cantidad = xRec.Cantidad then exit;
        if rec.Cantidad < xRec.Cantidad then begin
            dDif := (xRec.Cantidad - rec.Cantidad) * dMultiplicador;
            dPendiente += ddif;
            dMarcada -= ddif;
        end;
        //En función del tipo de contenedor, validamos su cantidad base (se tiene que mirar tb la ud de medida de producto como al generar los contenedores)
        dAsignacion := Rec.Cantidad * dMultiplicador;
        if dAsignacion > dPendiente then
            error(lErr0001);
        dpendiente -= dAsignacion;
        dMarcada += dAsignacion;
        rec.Validate(Rec."Cantidad base", dAsignacion);
        CurrPage.Update(true);
    end;

    local procedure InsertarRegistro(cTipo: Code[20]; cCodigo: Code[20]; dBase: Decimal): Boolean
    begin
        rec.setrange(Rec.tipo, cTipo);
        rec.SetRange(Rec."Código", cCodigo);
        if not rec.find then begin
            rec.Tipo := cTipo;
            rec."Código" := cCodigo;
            rec.Cantidad := 1;
            rec."Cantidad base" := dBase;
            rec.Generado := true;
            exit(rec.Insert());
        end;
        rec.setrange(Rec.tipo);
        rec.SetRange(Rec."Código");
        //CurrPage.Update(true);
    end;

    var
        lErr0001: Label 'The quantity indicated exceeds the maximum quantity to be selected.', comment = 'ESP="La cantidad indicada sobrepasa el máximo a selecionar."';
        lErr0002: Label 'This container cannot be selected as it is not fully available.', comment = 'ESP="Este contenedor no se puede seleccionar al no estar totalmente disponible"';
        lErr003: Label 'Can''t find related information with the filters specified', comment = 'ESP="No podemos encontrar información relacionada con los filtros indicados"';
}
*/