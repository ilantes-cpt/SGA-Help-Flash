page 50307 "Sel. Contenido Contenedor"
{
    ApplicationArea = all;
    Caption = 'Selector Content Container';
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
    begin
        rconf.get();
        dPendiente += Rec."Cantidad base";
        dMarcada -= rec."Cantidad base";
        if Rec.generado then begin
            rContenido.reset();
            case Rec.Tipo of
                rconf."Tipo pallet":
                    rcontenido.SetRange(Padre, Rec."Código");
                rconf."Tipo caja":
                    rcontenido.SetRange("Código", Rec."Código");
                '':
                    rcontenido.SetRange(IMEI, Rec."Código");
            end;

            //Filtramos el contenido según los datos del formulario.
            FiltrarTipoContenidoContenedor();
            /*
            rcontenido.SetRange(pedventa, cDocumento);
            rcontenido.SetRange(linpedventa, ilinea);
            */
            //rContenido.SetRange(Vendido, false);
            if rContenido.find('-') then
                repeat
                    LimpiarDatosTipoContenedor();
                    rcontenido.Modify();
                until rContenido.Next() = 0;
        end;
        CurrPage.Update(true);
    end;

    trigger OnClosePage()
    var
        dDialog: Dialog;
        bValidar: Boolean;
    begin
        bValidar := false;
        if Rec.Count > 1 then bvalidar := true;
        if (rec.Count = 1) and (Rec."Código" <> '') and (rec.Cantidad <> 0) then bvalidar := true;
        if bvalidar then begin
            rec.setrange(generado, false);
            dDialog.Open('Validando datos a nivel contenido contenedor.\IMEI #1######\Espere un momento por favor.');
            if rec.find('-') then
                repeat
                    case rec.Tipo of
                        rConf."Tipo pallet":
                            begin
                                //A nivel palet
                                rContenido.reset();
                                rContenido.SetRange(padre, rec."Código");
                                if rContenido.find('-') then
                                    repeat
                                        dDialog.Update(1, rcontenido.IMEI);
                                        ValidarDocumentoLinea();
                                        /*
                                        rContenido.Validate(PedVenta, cDocumento);
                                        rContenido.Validate(LinPedVenta, iLinea);
                                        */
                                        rContenido.Modify(true);
                                    until rContenido.next() = 0
                            end;
                        rconf."Tipo caja":
                            begin
                                //A nivel caja
                                rContenido.reset();
                                rContenido.SetRange("Código", rec."Código");
                                if rContenido.find('-') then
                                    repeat
                                        dDialog.Update(1, rcontenido.IMEI);
                                        ValidarDocumentoLinea();
                                        /*
                                        rContenido.Validate(PedVenta, cDocumento);
                                        rContenido.Validate(LinPedVenta, iLinea);
                                        */
                                        rContenido.Modify(true);
                                    until rContenido.next() = 0
                            end;
                        '':
                            begin
                                //A nivel IMEI
                                rContenido.reset();
                                rContenido.SetRange(IMEI, rec."Código");
                                if rContenido.find('-') then begin
                                    dDialog.Update(1, rcontenido.IMEI);
                                    ValidarDocumentoLinea();
                                    /*
                                    rContenido.Validate(PedVenta, cDocumento);
                                    rContenido.Validate(LinPedVenta, iLinea);
                                    */
                                    rContenido.Modify(true);
                                end;
                            end;
                    end;
                until rec.Next() = 0;
            dDialog.Close();
        end;
        CurrPage.Update(true);
    end;

    procedure EstablecerDocNew(Tipo: code[20]; cDoc: code[20]; ilin: Integer; dCantBase: Decimal; cAlm: code[10]; cProd: code[20]; cDiario: code[20]; cSeccion: code[20]; bVend: Boolean)
    var
        qPallet: Query ContenidoPorPalletYDoc;
        qCaja: Query ContenidoPorCajaYDoc;
        dCaja, dPalet, dSeleccionado, dCantQuery : Decimal;
        bGenerado: Boolean;
        dDialog: Dialog;
        tFiltroPadre: Text;
        tFiltroCaja: Text;
        tFPV, tFLPV, tFPT, tFLPT, tFPR, tFLPR, tFPE, tFLPE, tFND, tFSD, tFLD, tPEN, tPENLIN : Text;
    begin
        cDoc2 := '';
        Rec.Init();
        rec.Insert();
        cdocumento := cdoc;
        ilinea := ilin;
        cTipoDoc := tipo;
        cNomDiario := cDiario;
        cNomSeccion := cSeccion;
        bVendido := bVend;
        dTotal := dCantBase;
        cAlmacen := calm;
        cProducto := cProd;
        rec.FilterGroup(2);
        Rec.SetFilter(FiltroAlmacen, calm);
        rec.SetFilter(FiltroProd, cProd);
        rec.SetFilter(FiltroCaja, rconf."Tipo caja");
        rec.setfilter(FiltroPalet, rconf."Tipo pallet");
        rconf.get();
        rContenido.reset();
        rcontenido.SetRange("Cód Almacén", calm);
        rContenido.SetRange("Nº producto", cprod);
        Clear(qPallet);
        clear(qCaja);
        tFPV := '';
        tFLPV := '0';
        tFPT := '';
        tFLPT := '0';
        tFPR := '';
        tFLPR := '0';
        tFPE := '';
        tFLPE := '0';
        tFND := '';
        tFSD := '';
        tFLD := '0';
        tPEN := '';
        tPENLIN := '0';

        case Tipo of
            'PVENTA':
                begin
                    tfpv := '<>' + cdoc;
                    tflpv := '<>' + Format(ilin);
                    rcontenido.SetRange(PedVenta, cdoc);
                    rcontenido.SetRange(LinPedVenta, ilin);
                    qPallet.setrange(qPallet.PedVenta, cdoc);
                    qPallet.setrange(qPallet.LinPedVenta, ilin);
                    qCaja.setrange(qcaja.PedVenta, cDoc);
                    qcaja.SetRange(qcaja.LinPedVenta, ilin);
                end;
            'PTRANS':
                begin
                    tfpt := '<>' + cdoc;
                    tflpt := '<>' + Format(ilin);
                    rcontenido.SetRange(PedTrans, cdoc);
                    rcontenido.SetRange(LinPedtrans, ilin);
                    qPallet.setrange(qPallet.PedTrans, cdoc);
                    qPallet.setrange(qPallet.LinPedTrans, ilin);
                    qCaja.setrange(qcaja.PedTrans, cDoc);
                    qcaja.SetRange(qcaja.LinPedTrans, ilin);
                end;
            'PRECEP':
                begin
                    tfpr := '<>' + cdoc;
                    tflpr := '<>' + Format(ilin);
                    rcontenido.SetRange(RecepAlm, cdoc);
                    rcontenido.SetRange(LinRecep, ilin);
                    qPallet.setrange(qPallet.RecepAlm, cdoc);
                    qPallet.setrange(qPallet.LinRecep, ilin);
                    qCaja.setrange(qcaja.RecepAlm, cDoc);
                    qcaja.SetRange(qcaja.LinRecep, ilin);
                end;
            'PENV':
                begin
                    tfpe := '<>' + cdoc;
                    tflpe := '<>' + Format(ilin);
                    rcontenido.SetRange(EnvioAlm, cdoc);
                    rcontenido.SetRange(LinEnvio, ilin);
                    qPallet.setrange(qPallet.EnvioAlm, cdoc);
                    qPallet.setrange(qPallet.LinEnvio, ilin);
                    qCaja.setrange(qcaja.EnvioAlm, cDoc);
                    qcaja.SetRange(qcaja.LinEnvio, ilin);
                end;
            'DIARIO':
                begin
                    tfnd := '<>' + cdiario;
                    tfsd := '<>' + cseccion;
                    tfld := '<>' + Format(ilin);
                    rcontenido.SetRange("Libro registro productos", cDiario);
                    rcontenido.SetRange("Sección registro productos", cSeccion);
                    rcontenido.SetRange(LinDiario, ilin);
                    qPallet.setrange(qPallet.LibroRegistroProductos, cDiario);
                    qpallet.SetRange(qpallet.SeccionRegistroProductos, cSeccion);
                    qPallet.setrange(qPallet.LinDiario, ilin);
                    qCaja.setrange(qcaja.LibroRegistroProductos, cDiario);
                    qcaja.SetRange(qcaja.SeccionRegistroProductos, cSeccion);
                    qCaja.setrange(qcaja.LinDiario, ilin);
                end;
            //AÑADIMOS FILTRO PED ENSAMBLADO
            'PENSAMBLADO':
                begin
                    tPEN := '<>' + cdoc;
                    tPENLIN := '<>' + Format(ilin);
                    rcontenido.SetRange("Nº pedido ensamblado", cdoc);
                    rcontenido.SetRange("Nº linea pedido ensamblado", ilin);
                    qPallet.setrange(qPallet.Npedidoensamblado, cdoc);
                    qPallet.setrange(qPallet.Nlineapedidoensamblado, ilin);
                    qCaja.setrange(qcaja.Npedidoensamblado, cDoc);
                    qcaja.SetRange(qcaja.Nlineapedidoensamblado, ilin);
                end;
        end;

        rec.SetFilter(FiltroPedido, tfpv);
        rec.SetFilter(FiltroLinea, tflpv);
        rec.SetFilter(FiltroPedidoTransf, tFPT);
        rec.SetFilter(FiltroLineaTransf, tFLPT);
        rec.SetFilter(FiltroPedidoRecep, tfpr);
        rec.SetFilter(FiltroLineaRecep, tflpr);
        rec.SetFilter(FiltroPedidoEnvio, tfpe);
        rec.SetFilter(FiltroLineaEnvio, tflpe);
        rec.SetFilter(FiltroNombreDiario, tFND);
        rec.SetFilter(FiltroSeccionDiario, tfsd);
        rec.SetFilter(FiltroLineaDiario, tfld);

        //AÑADIMOS FILTRO PED ENSAMBLADO
        rec.SetFilter(FiltroPedidoEnsamblado, tPEN);
        rec.SetFilter(FiltroLineaPedidoEnsamblado, tPENLIN);
        //AÑADIMOS FILTRO PED ENSAMBLADO

        rec.FilterGroup(0);
        //Calculamos el total asignado para este pedido
        if rcontenido.findset() then
            if rContenido.CalcSums(Cantidad) then
                dMarcada := rContenido.Cantidad;

        dPendiente := dTotal - dMarcada;
        dcaja := rec.MultiplicadorbaseTipo(rconf."Tipo caja", cProducto);
        dpalet := rec.multiplicadorbasetipo(rconf."Tipo pallet", cProducto);
        dDialog.open('Cargando datos previamente seleccionados\Espere por favor.');
        //Realizamos la query de cantidades filtrando documento y por tipo pallet y caja
        if dmarcada > dpalet then begin
            qPallet.SetRange(vendido, false);
            qpallet.SetRange(qPallet.Nproducto, cProducto);
            qpallet.Open();
            while qpallet.Read() do begin
                dCantQuery := 0;
                if Evaluate(dCantQuery, format(qPallet.CantidadPadre)) then
                    if dCantQuery = dpalet then
                        //Creamos una entrada para el pallet
                        if InsertarRegistro(rconf."Tipo pallet", qPallet.Padre, dpalet) then begin
                            bGenerado := true;
                            dSeleccionado += dPalet;
                        end;
            end;
            qPallet.Close();
        end;
        qcaja.SetRange(qcaja.Vendido, false);
        qcaja.SetRange(qcaja.Nproducto, cProducto);
        qcaja.Open();
        while qCaja.Read() do begin
            dCantQuery := 0;
            if Evaluate(dCantQuery, format(qcaja.CantidadCaja)) then
                if dCantQuery = dCaja then begin
                    rec.SetRange("Código", qCaja.Padre);
                    if not rec.Find('-') then
                        if InsertarRegistro(rconf."Tipo caja", qcaja."Código", dcaja) then begin
                            bGenerado := true;
                            dSeleccionado += dcaja;
                        end;
                    rec.SetRange("Código");
                end else begin
                    rContenido.SetRange("Código", qcaja."Código");
                    //OJO CREAR EL FILTRO PARA EL TIPO DE DOCUMENTO QUE CORRESPONDA
                    /*
                    rContenido.reset;                    
                    rContenido.setrange(pedventa, cdocumento);
                    rcontenido.setrange(linpedventa, ilinea);
                    */
                    if rContenido.Find('-') then
                        repeat
                            rec.SetRange("Código", qCaja.Padre);
                            if (not rec.Find('-')) or (qcaja.padre = '') then begin
                                rec.SetRange("Código", qCaja."Código");
                                if not rec.Find('-') then
                                    if InsertarRegistro('', rcontenido.IMEI, 1) then begin
                                        bGenerado := true;
                                        dSeleccionado += 1;
                                    end;
                                rec.SetRange("Código");
                            end;
                            rec.SetRange("Código");
                        until rContenido.Next() = 0;
                end;
        end;
        qCaja.Close();
        rec.setfilter(Rec.tipo, '%1', '');
        rec.setfilter(Rec."Código", '%1', '');
        rec.setfilter(Rec.cantidad, '0');
        rec.setfilter(Rec.Generado, '%1', false);
        if rec.find('-') then rec.delete(false);
        rec.setrange(Rec.tipo);
        rec.SetRange(Rec."Código");
        rec.setrange(Rec.cantidad);
        rec.setrange(Rec.Generado);
        dDialog.close();
    end;


    procedure EstablecerDoc(cDoc: code[20]; iLin: Integer; dCantBase: Decimal; cAlm: code[10]; cProd: code[20])
    var
        dCaja, dPalet, dSeleccionado, dCantQuery : Decimal;
        bGenerado: Boolean;
        tFiltroPadre: Text;
        tFiltroCaja: Text;
        qPallet: Query ContenidoPorPalletYDoc;
        qCaja: Query ContenidoPorCajaYDoc;
        dDialog: Dialog;
    begin
        cDoc2 := '';
        Rec.Init();
        rec.Insert();
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
        rec.setfilter(FiltroPedido, '<>%1', cdoc);
        rec.setfilter(FiltroLinea, '<>%1', iLin);
        rec.setfilter(FiltroPedidoTransf, '%1', '');
        rec.setfilter(FiltroLineaTransf, '%1', 0);
        rec.setfilter(FiltroPedidoRecep, '%1', '');
        rec.setfilter(FiltroLineaRecep, '%1', 0);
        //rec.setfilter(FiltroPedidoEnvio, '%1', '');
        //rec.setfilter(FiltroLineaEnvio, '%1', 0);
        rec.FilterGroup(0);
        //Calculamos el total asignado para este pedido
        rContenido.reset();
        rcontenido.SetRange(PedVenta, cdoc);
        rcontenido.SetRange(LinPedVenta, ilin);
        rcontenido.SetRange(PedTrans, '');
        rcontenido.SetRange(LinPedTrans, 0);
        rContenido.SetRange(RecepAlm, '');
        rContenido.SetRange(LinRecep, 0);
        //rContenido.SetRange(EnvioAlm, '');
        //rContenido.SetRange(LinEnvio, 0);
        if rcontenido.findset() then begin
            if rContenido.CalcSums(Cantidad) then
                dMarcada := rContenido.Cantidad;
        end;
        dPendiente := dTotal - dMarcada;
        dcaja := rec.MultiplicadorbaseTipo(rconf."Tipo caja", cProducto);
        dpalet := rec.multiplicadorbasetipo(rconf."Tipo pallet", cProducto);
        //PRUEBAS LANTES
        dDialog.open('Cargando datos previamente seleccionados\Espere por favor.');
        //Realizamos la query de cantidades filtrando documento y por tipo pallet y caja
        Clear(qPallet);
        qPallet.setrange(qPallet.PedVenta, cdoc);
        qPallet.setrange(qPallet.LinPedVenta, ilin);
        qPallet.SetRange(vendido, false);
        qpallet.SetRange(qPallet.Nproducto, cProducto);
        qpallet.Open();
        while qpallet.Read() do begin
            dCantQuery := 0;
            if Evaluate(dCantQuery, format(qPallet.CantidadPadre)) then
                if dCantQuery = dpalet then
                    //Creamos una entrada para el pallet
                    if InsertarRegistro(rconf."Tipo pallet", qPallet.Padre, dpalet) then begin
                        bGenerado := true;
                        dSeleccionado += dPalet;
                    end;
        end;
        qPallet.Close();
        qCaja.Setrange(qCaja.PedVenta, cdoc);
        qcaja.Setrange(qCaja.LinPedVenta, ilin);
        qcaja.SetRange(qcaja.Vendido, false);
        qcaja.SetRange(qcaja.Nproducto, cProducto);
        qcaja.Open();
        while qCaja.Read() do begin
            dCantQuery := 0;
            if Evaluate(dCantQuery, format(qcaja.CantidadCaja)) then;
            if dCantQuery = dCaja then begin
                rec.SetRange("Código", qCaja.Padre);
                if not rec.Find('-') then
                    if InsertarRegistro(rconf."Tipo caja", qcaja."Código", dcaja) then begin
                        bGenerado := true;
                        dSeleccionado += dcaja;
                    end;
                rec.SetRange("Código");
            end else begin
                rContenido.reset();
                rContenido.SetRange("Código", qcaja."Código");
                rContenido.setrange(pedventa, cdocumento);
                rcontenido.setrange(linpedventa, ilinea);
                if rContenido.Find('-') then
                    repeat
                        rec.SetRange("Código", qCaja.Padre);
                        if not rec.Find('-') then begin
                            rec.SetRange("Código", qCaja."Código");
                            if not rec.Find('-') then
                                if InsertarRegistro('', rcontenido.IMEI, 1) then begin
                                    bGenerado := true;
                                    dSeleccionado += 1;
                                end;
                            rec.SetRange("Código");
                        end;
                        rec.SetRange("Código");
                    until rContenido.Next() = 0;
            end;
        end;
        rec.setfilter(Rec.tipo, '%1', '');
        rec.setfilter(Rec."Código", '%1', '');
        rec.setfilter(Rec.cantidad, '0');
        rec.setfilter(Rec.Generado, '%1', false);
        if rec.find('-') then rec.delete(false);
        rec.setrange(Rec.tipo);
        rec.SetRange(Rec."Código");
        rec.setrange(Rec.cantidad);
        rec.setrange(Rec.Generado);
        dDialog.close();
        exit;
        //FIN PRUEBAS LANTES        
        //Generamos los registros existentes
        dSeleccionado := 0;
        tFiltroPadre := '';
        tFiltroCaja := '';
        if rContenido.find('-') then
            repeat
                bgenerado := false;
                //rcontenido.CalcFields(Padre);
                //Comprobamos si ya esta creado el padre, en caso de estarlo, omitimos este registro
                rec.SetRange(Tipo, rConf."Tipo pallet");
                rec.Setrange("Código", rcontenido.padre);
                if rec.find('-') then bGenerado := true;
                rec.SetRange(Tipo, rConf."Tipo caja");
                rec.Setrange("Código", rcontenido."Código");
                if rec.find('-') then bGenerado := true;
                if not bgenerado then begin
                    rContPadre.reset();
                    rcontpadre.setrange(padre, rContenido.Padre);
                    rcontpadre.setrange(pedventa, cdocumento);
                    rcontpadre.setrange(linpedventa, ilinea);
                    rcontpadre.SetRange(PedTrans, '');
                    rcontpadre.SetRange(LinPedTrans, 0);
                    rcontpadre.SetRange(RecepAlm, '');
                    rcontpadre.SetRange(LinRecep, 0);
                    //rcontpadre.SetRange(EnvioAlm, '');
                    //rcontpadre.SetRange(LinEnvio, 0);
                    if rContPadre.findset() then
                        if rcontpadre.calcsums(cantidad) then
                            if rcontpadre.cantidad = dpalet then
                                if InsertarRegistro(rconf."Tipo pallet", rcontenido.padre, dpalet) then begin
                                    bGenerado := true;
                                    dSeleccionado += rContPadre.Cantidad;
                                    /*if tFiltroPadre = '' then
                                        tFiltroPadre := '<>' + rContenido.Padre
                                    else
                                        tFiltroPadre := tFiltroPadre + '|<>' + rContenido.Padre;
                                    rcontenido.setfilter(Padre, tfiltropadre);*/
                                end;
                end;
                if not bgenerado then begin
                    rContPadre.reset();
                    rcontpadre.setrange("Código", rContenido."Código");
                    rcontpadre.setrange(pedventa, cdocumento);
                    rcontpadre.setrange(linpedventa, ilinea);
                    rcontpadre.SetRange(PedTrans, '');
                    rcontpadre.SetRange(LinPedTrans, 0);
                    rcontpadre.SetRange(RecepAlm, '');
                    rcontpadre.SetRange(LinRecep, 0);
                    //rcontpadre.SetRange(EnvioAlm, '');
                    //rcontpadre.SetRange(LinEnvio, 0);
                    if rContPadre.findset() then begin
                        if rcontpadre.calcsums(cantidad) then
                            if rcontpadre.cantidad = dcaja then
                                if InsertarRegistro(rconf."Tipo caja", rContPadre."Código", dcaja) then begin
                                    bgenerado := true;
                                    dSeleccionado += rContPadre.Cantidad;
                                    /*
                                    if tfiltrocaja = '' then
                                        tfiltrocaja := '<>' + rcontpadre."Código"
                                    else
                                        tFiltroCaja := tFiltroCaja + '|<>' + rContPadre."Código";
                                    rcontenido.setfilter("Código", tFiltroCaja);
                                    */
                                end;
                    end;
                end;
                if not bgenerado then begin
                    //Si no tenemos generada ni la caja ni el pallet, generamos el IMEI
                    Rec.setrange(Rec.tipo, rconf."Tipo pallet");
                    Rec.setrange(Rec."Código", rcontenido.Padre);
                    if not rec.findset() then begin
                        Rec.setrange(Rec.tipo, rconf."Tipo caja");
                        Rec.setrange(Rec."Código", rcontenido."Código");
                        if not rec.findset() then begin
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

    local procedure BuscarCodigo()
    begin
        clear(pContenedor);
        clear(pContenido);
        rContenedor.reset();
        rContenido.Reset();
        rconf.get();
        case rec.tipo of
            rconf."Tipo caja":
                begin
                    rcontenedor.SetRange("Almacén", cAlmacen);
                    rcontenedor.SetRange(Tipo, rconf."Tipo caja");
                    rcontenedor.SetRange(FiltroProducto, cProducto);
                    rContenedor.SetRange(ContieneProductoFiltradoCaja, true);
                    rContenedor.SetRange(FiltroVendido, bVendido);
                    /*
                    rContenedor.SetFilter(FiltroPedido, '<>%1', cDocumento);
                    rContenedor.SetFilter(FiltroLinea, '<>%1', iLinea);
                    rContenedor.SetFilter(FiltroPedidoTransf, '%1', '');
                    rContenedor.SetFilter(FiltroLineaTransf, '%1', 0);
                    rContenedor.setfilter(FiltroPedidoRecep, '%1', '');
                    rContenedor.setfilter(FiltroLineaRecep, '%1', 0);
                    //rContenedor.setfilter(FiltroPedidoEnvio, '%1', cDoc2);
                    //rContenedor.setfilter(FiltroLineaEnvio, '%1', 0);
                    */
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
                    rContenedor.SetRange(ContieneProductoFiltradoPallet, true);
                    rContenedor.SetRange(FiltroVendido, bVendido);
                    /*
                    rContenedor.SetFilter(FiltroPedido, '<>%1', cDocumento);
                    rContenedor.SetFilter(FiltroLinea, '<>%1', iLinea);
                    rContenedor.SetFilter(FiltroPedidoTransf, '%1', '');
                    rContenedor.SetFilter(FiltroLineaTransf, '%1', 0);
                    rContenedor.setfilter(FiltroPedidoRecep, '%1', '');
                    rContenedor.setfilter(FiltroLineaRecep, '%1', 0);
                    //rContenedor.setfilter(FiltroPedidoEnvio, '%1', cDoc2);
                    //rContenedor.setfilter(FiltroLineaEnvio, '%1', 0);
                    */
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
                    rContenido.SetRange("Cód Almacén", cAlmacen);
                    rcontenido.SetRange("Nº producto", cProducto);
                    rContenido.SETRANGE(Endocumento, FALSE);
                    /*
                    rcontenido.SetFilter(PedVenta, '<>%1&%2', cDocumento, cDoc2);
                    rcontenido.SetFilter(LinPedVenta, '<>%1', iLinea);
                    rcontenido.SetRange(PedTrans, '');
                    rcontenido.SetRange(LinPedTrans, 0);
                    rContenido.SetRange(RecepAlm, '');
                    rContenido.SetRange(LinRecep, 0);
                    //rContenido.SetRange(EnvioAlm, '');
                    //rContenido.SetRange(LinEnvio, 0);
                    */
                    rContenido.setrange(Vendido, bVendido);
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
        if rec."Código" <> '' then
            ValidarCodigo();
    end;

    local procedure ValidarCodigo()
    var
        lText0001: Label 'This box is not fully available, there are %1 used slots, do you want to include the rest of the units?', comment = 'ESP="Esta caja no está totalmente disponible, hay %1 huecos usados. ¿Desea incluir el resto de unidades?"';
        lErr0003: Label 'This container cannot be selected as it is not fully available, there are %1 used gaps.', comment = 'ESP="Este contenedor no se puede seleccionar al no estar totalmente disponible, hay %1 huecos usados"';
        lErr0004: Label 'Selected container cannot be found with filter criteria.';
        lErr0005: Label 'Selected IMEI cannot be found with filter criteria.';
    begin
        rcontenido.reset();
        rContenido.SetRange("Cód Almacén", cAlmacen);
        rcontenido.SetRange("Nº producto", cProducto);
        rcontenido.SetFilter(PedVenta, '<>%1', cDocumento);
        rcontenido.SetFilter(LinPedVenta, '<>%1', iLinea);
        //AÑADIMOS FILTRO PED ENSAMBLADO
        rcontenido.SetFilter("Nº pedido ensamblado", '<>%1', cDocumento);
        rcontenido.SetFilter("Nº linea pedido ensamblado", '<>%1', iLinea);
        //AÑADIMOS FILTRO PED ENSAMBLADO
        rContenido.SetRange(RecepAlm, '');
        rContenido.SetRange(LinRecep, 0);
        rContenido.SetRange(EnvioAlm, '');
        rContenido.SetRange(LinEnvio, 0);
        rContenido.SetRange(PedTrans, '');
        rContenido.SetRange(LinPedTrans, 0);
        rconf.get();
        case rec.tipo of
            rconf."Tipo caja":
                begin
                    rContenido.setrange("Código", Rec."Código");
                    if rContenido.findset() then begin
                        if rContenido.CalcSums(Cantidad) then
                            if rContenido.Cantidad < Rec.MultiplicadorBase(cProducto) then begin
                                dCont := rContenido.Cantidad;
                                //if not Confirm(lText0001, true, dCont) then
                                error(lErr0003, rContenido.Cantidad);
                            end;
                    end else
                        error(lerr0004);
                end;
            rconf."Tipo pallet":
                begin
                    rContenido.setrange(Padre, Rec."Código");
                    if rContenido.findset() then begin
                        if rContenido.CalcSums(Cantidad) then
                            if rContenido.Cantidad < Rec.MultiplicadorBase(cProducto) then
                                error(lErr0003, rcontenido.Cantidad);
                    end else
                        error(lerr0004);
                end;
            '':
                begin
                    rContenido.SetRange(IMEI, rec."Código");
                    if not rContenido.FindSet() then
                        error(lErr0005);
                end;
        end;
        Rec.validate(Cantidad, 1);
        ValidaCantidad();
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
        //rec.SetRange(Generado, false);
        if not rec.find() then begin
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

    local procedure LimpiarDatosTipoContenedor()
    begin
        rContenido.Endocumento := false;
        case cTipoDoc of
            'PVENTA', '':
                begin
                    rcontenido.PedVenta := '';
                    rcontenido.LinPedVenta := 0;
                end;
            'PTRANS':
                begin
                    rcontenido.PedTrans := '';
                    rcontenido.LinPedTrans := 0;
                end;
            'PRECEP':
                begin
                    rcontenido.RecepAlm := '';
                    rcontenido.LinRecep := 0;
                end;
            'PENV':
                begin
                    rcontenido.EnvioAlm := '';
                    rcontenido.LinEnvio := 0;
                end;
            'DIARIO':
                begin
                    rcontenido."Libro registro productos" := '';
                    rcontenido."Sección registro productos" := '';
                    rcontenido.LinDiario := 0;
                end;
            'PENSAMBLADO':
                begin
                    rcontenido."Nº pedido ensamblado" := '';
                    rcontenido."Nº linea pedido ensamblado" := 0;
                end;
        end;
    end;

    local procedure FiltrarTipoContenidoContenedor()
    begin
        case cTipoDoc of
            'PVENTA', '':
                begin
                    rcontenido.SetRange(PedVenta, cDocumento);
                    rcontenido.SetRange(LinPedVenta, ilinea);
                end;
            'PTRANS':
                begin
                    rcontenido.SetRange(PedTrans, cDocumento);
                    rcontenido.SetRange(LinPedtrans, ilinea);
                end;
            'PRECEP':
                begin
                    rcontenido.SetRange(RecepAlm, cdocumento);
                    rcontenido.SetRange(LinRecep, ilinea);
                end;
            'PENV':
                begin
                    rcontenido.SetRange(EnvioAlm, cdocumento);
                    rcontenido.SetRange(LinEnvio, ilinea);
                end;
            'DIARIO':
                begin
                    rcontenido.SetRange("Libro registro productos", cnomDiario);
                    rcontenido.SetRange("Sección registro productos", cnomSeccion);
                    rcontenido.SetRange(LinDiario, ilinea);
                end;
            'PENSAMBLADO':
                begin
                    rcontenido.SetRange("Nº pedido ensamblado", cDocumento);
                    rcontenido.SetRange("Nº linea pedido ensamblado", ilinea);
                end;
        end;
    end;

    local procedure ValidarDocumentoLinea()
    begin
        case cTipoDoc of
            'PVENTA', '':
                begin
                    rcontenido.validate(PedVenta, cDocumento);
                    rcontenido.validate(LinPedVenta, ilinea);
                end;
            'PTRANS':
                begin
                    rcontenido.validate(PedTrans, cDocumento);
                    rcontenido.validate(LinPedtrans, ilinea);
                end;
            'PRECEP':
                begin
                    rcontenido.validate(RecepAlm, cdocumento);
                    rcontenido.validate(LinRecep, ilinea);
                end;
            'PENV':
                begin
                    rcontenido.validate(EnvioAlm, cdocumento);
                    rcontenido.validate(LinEnvio, ilinea);
                end;
            'DIARIO':
                begin
                    rcontenido.validate("Libro registro productos", cnomDiario);
                    rcontenido.validate("Sección registro productos", cnomSeccion);
                    rcontenido.validate(LinDiario, ilinea);
                end;
            'PENSAMBLADO':
                begin
                    rcontenido.validate("Nº pedido ensamblado", cDocumento);
                    rcontenido.validate("Nº linea pedido ensamblado", ilinea);
                end;
        end;
    end;

    //Variables globales
    var
        dTotal, dMarcada, dPendiente, dAsignacion, dCont : Decimal;
        cDocumento, cProducto, cDoc2, cTipoDoc, cNomDiario, cNomSeccion : code[20];
        bVendido: Boolean;
        cAlmacen: code[10];
        iLinea: Integer;
        rContenido, rContPadre : Record "Contenido contenedor";
        rConf: Record "Containers Setup";
        pContenedor: page "Lista contenedores";
        pContenido: page "Contenido Cont.";
        lErr0001: Label 'The quantity indicated exceeds the maximum quantity to be selected.', comment = 'ESP="La cantidad indicada sobrepasa el máximo a selecionar."';
        lErr0002: Label 'This container cannot be selected as it is not fully available.', comment = 'ESP="Este contenedor no se puede seleccionar al no estar totalmente disponible"';
        lErr003: Label 'Can''t find related information with the filters specified', comment = 'ESP="No podemos encontrar información relacionada con los filtros indicados"';
        rContenedor: Record Contenedores;
}
