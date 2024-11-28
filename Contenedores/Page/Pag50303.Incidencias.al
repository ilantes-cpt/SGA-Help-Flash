page 50303 Incidencias
{
    ApplicationArea = All;
    Caption = 'Incidencias';
    PageType = List;
    SourceTable = "Contenido contenedor";
    SourceTableView = where(Incidencia = const(true));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Cód. Almacén"; Rec."Cód Almacén")
                {
                    Editable = false;
                }
                field(IMEI; Rec.IMEI)
                {
                    Editable = false;
                }
                field(Incidencia; Rec.Incidencia)
                {
                    Editable = false;
                }
                field("Nº producto"; Rec."Nº producto")
                {
                    Editable = false;
                }
                field("Nº albarán venta"; Rec."Nº albarán venta")
                {
                    Editable = false;
                }
                field(PedVenta; Rec.PedVenta)
                {
                    Editable = false;
                }
                field(LinPedVenta; Rec.LinPedVenta)
                {
                    Editable = false;
                }
                field(Solved; Rec.Solved)
                {
                    Editable = false;
                }
                field(Baja; Rec.Baja)
                {
                    Editable = false;
                }
                field(IncidenceDate; Rec.IncidenceDate)
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action("Anular incidencia")
            {
                ApplicationArea = All;
                Caption = 'Anular incidencia';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = ChangeBatch;

                trigger OnAction()
                var
                    rContenidocontenedor: record "Contenido contenedor";
                begin
                    //filtramos las lineas que tengan un pedido de venta y un nº de linea venta pero que no esten abonados.
                    rContenidocontenedor.Reset();
                    rContenidocontenedor.Copy(Rec);
                    CurrPage.SetSelectionFilter(rContenidocontenedor);
                    if rContenidocontenedor.FindSet() then
                        if Confirm('¿Desea anular las incidencias seleccionadas?') then
                            rContenidocontenedor.ModifyAll(Incidencia, false);

                end;
            }
            action("Asignar almacen cuarentena")
            {
                ApplicationArea = All;
                Caption = 'Asignar almacen cuarentena';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Location;

                trigger OnAction()
                var
                    rContenidocontenedor: record "Contenido contenedor";
                    rContenido: record "Contenido contenedor";
                    rAlmacen: Record Location;
                    pAlmacen: page "Location List";
                begin
                    //Seleccionar el almacén al que se llevará la mercancía
                    rAlmacen.Reset();
                    rAlmacen.SetRange("Use As In-Transit", false);
                    if rAlmacen.FindSet() then begin
                        Clear(pAlmacen);
                        pAlmacen.SetTableView(rAlmacen);
                        pAlmacen.LookupMode := true;
                        if pAlmacen.RunModal() = action::LookupOK then begin
                            pAlmacen.GetRecord(rAlmacen);
                            rAlmacen.TestField("Contenedor devoluciones");

                            rContenidocontenedor.Reset();
                            rContenidocontenedor.Copy(Rec);
                            CurrPage.SetSelectionFilter(rContenidocontenedor);
                            if rContenidocontenedor.FindSet() then
                                repeat

                                    //Se cambia el contenedor de ubicación al predeterminado de almacén
                                    if rContenidocontenedor."Código" <> rAlmacen."Contenedor devoluciones" then begin
                                        rContenido.get(rContenidocontenedor."Código", rContenidocontenedor."Nº producto", rContenidocontenedor.IMEI);
                                        rContenido.Rename(rAlmacen."Contenedor devoluciones", rContenido."Nº producto", rContenido.IMEI);
                                        rContenido."Almacen reasignado" := true;
                                        rContenido.Modify();
                                    end;

                                until rContenidocontenedor.Next() = 0;

                        end;
                    end;
                end;
            }


            action(Devolver)
            {
                Caption = 'Devolver al cliente';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ReturnShipment;

                trigger OnAction()
                var
                    rRen: Record "Contenido contenedor";
                    rAlmacen: Record Location;
                    pFecha: page "Date-Time Dialog";
                    pAlmacen: page "Location List";
                begin
                    Clear(pAlmacen);
                    pAlmacen.SetTableView(rAlmacen);
                    pAlmacen.LookupMode := true;
                    if pAlmacen.RunModal() = action::LookupOK then begin
                        clear(pFecha);
                        pFecha.UseDateOnly();
                        pfecha.LookupMode := true;
                        if pFecha.RunModal() = action::LookupOK then begin
                            pAlmacen.GetRecord(rAlmacen);
                            rAlmacen.TestField("Contenedor devoluciones");
                            Rec.validate(Rec.Solved, Rec.Solved::Returned);
                            Rec.Validate(Rec.Baja, Rec.baja::None);
                            Rec.Validate(Rec.Incidencia, false);
                            Rec.Validate(Rec.IncidenceDate, pfecha.GetDate());
                            Rec.Validate(Rec.Vendido, true);
                            Rec.Modify();
                            if rAlmacen."Contenedor devoluciones" <> Rec."Código" then begin
                                rRen.get(Rec."Código", Rec."Nº producto", Rec.IMEI);
                                rren.Rename(rAlmacen."Contenedor devoluciones", rren."Nº producto", rren.IMEI);
                            end;
                        end;
                    end;
                end;
            }
            action("Anular pedido")
            {
                ApplicationArea = All;
                Caption = 'Anular pedido';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = CancelFALedgerEntries;

                trigger OnAction()
                var
                    SalesShipmentLine: Record "Sales Shipment Line";
                    rContenidocontenedor: record "Contenido contenedor";
                    rContenidocontenedor2: record "Contenido contenedor";
                    rSalesHeader: record "Sales Header";
                    rItemJournalLine: record "Item Journal Line";
                    rItemJnlTemplate: record "Item Journal Template";
                    rItemJnlBatch: record "Item Journal Batch";
                    cContenedores: codeunit Contenedores;
                    cUndoShipmentLine: Codeunit "Undo Sales Shipment Line";
                    cItemJnlPost: codeunit "Item Jnl.-Post";
                    cNoSeriesMgt: codeunit "No. Series";
                    nAlbaranVenta: code[20];
                    cAlmacenAlbaran: Code[20];
                    LineNo: Integer;
                begin

                    Clear(nAlbaranVenta);
                    Clear(cAlmacenAlbaran);

                    rContenidocontenedor.Reset();
                    rContenidocontenedor.Copy(Rec);
                    CurrPage.SetSelectionFilter(rContenidocontenedor);
                    rContenidocontenedor.SetFilter("Nº albarán venta", '<>%1', '');
                    if rContenidocontenedor.FindSet() then begin
                        if not Confirm(StrSubstNo('¿Está seguro de que desea deshacer los albaranes para %1 líneas seleccionadas?', rContenidocontenedor.Count), false) then
                            exit;
                        repeat
                            rContenidocontenedor.CalcFields("Cód Almacén");

                            if rContenidocontenedor."Nº albarán venta" <> nAlbaranVenta then begin

                                nAlbaranVenta := rContenidocontenedor."Nº albarán venta";

                                SalesShipmentLine.Reset();
                                SalesShipmentLine.SetRange("Document No.", rContenidocontenedor."Nº albarán venta");
                                SalesShipmentLine.SetRange("No.", rContenidocontenedor."Nº producto");
                                SalesShipmentLine.SetFilter("Quantity Invoiced", '<>%1', 0);
                                if not SalesShipmentLine.FindSet() then begin

                                    SalesShipmentLine.Reset();
                                    SalesShipmentLine.SetRange("Document No.", rContenidocontenedor."Nº albarán venta");
                                    SalesShipmentLine.SetRange("No.", rContenidocontenedor."Nº producto");
                                    SalesShipmentLine.FindSet();

                                    cAlmacenAlbaran := SalesShipmentLine."Location Code";

                                    Clear(cUndoShipmentLine);
                                    // Desactivar confirmaciones y mensajes

                                    cContenedores.AnularPedido(true);
                                    cUndoShipmentLine.SetHideDialog(true);
                                    // Llamar a la función estándar para deshacer la línea del albarán
                                    if cUndoShipmentLine.Run(SalesShipmentLine) then begin
                                        // Buscar la cabecera del pedido de venta
                                        rSalesHeader.SetRange("Document Type", rSalesHeader."Document Type"::Order);
                                        rSalesHeader.SetRange("No.", rContenidocontenedor.PedVenta);
                                        if rSalesHeader.FindFirst() then
                                            rSalesHeader.Delete(true);

                                        rContenidocontenedor2.Reset();
                                        rContenidocontenedor2.CopyFilters(rContenidocontenedor);
                                        if rContenidocontenedor2.FindFirst() then begin
                                            rContenidocontenedor2."Anulacion del pedido" := true;
                                            rContenidoContenedor2."Nº albarán venta" := '';
                                            rContenidoContenedor2.PedVenta := '';
                                            rContenidoContenedor2.LinPedVenta := 0;
                                            rContenidocontenedor2.Modify();
                                        end;
                                    end else
                                        Error('Ocurrió un error: %1', GetLastErrorText());

                                end else
                                    Error('Existen lineas con cantidad facturada, no se puede deshacer el albarán.');

                            end;

                            //EL CONTENEDOR ESTA EN CUARENTENA Y TENEMOS QUE RECLASIFICARLO
                            if rContenidocontenedor."Almacen reasignado" then begin

                                rItemJnlTemplate.Reset();
                                rItemJnlTemplate.SetRange("Page ID", Page::"Item Reclass. Journal");
                                rItemJnlTemplate.SetRange(Recurring, false);
                                rItemJnlTemplate.SetRange(Type, rItemJnlTemplate.type::Transfer);
                                if rItemJnlTemplate.FindFirst() then begin

                                    rItemJnlBatch.Reset();
                                    rItemJnlBatch.SetRange("Journal Template Name", rItemJnlTemplate.Name);
                                    if rItemJnlBatch.FindFirst() then begin


                                        rItemJournalLine.Reset();
                                        rItemJournalLine.SetRange("Journal Template Name", rItemJnlTemplate.Name);
                                        rItemJournalLine.SetRange("Journal Batch Name", rItemJnlBatch.Name);
                                        rItemJournalLine.SetRange("Item No.", rContenidocontenedor."Nº producto");
                                        rItemJournalLine.SetRange("Document No.", nAlbaranVenta);
                                        if not rItemJournalLine.FindFirst() then begin

                                            rItemJournalLine.Reset();
                                            rItemJournalLine.SetRange("Journal Template Name", rItemJnlTemplate.Name);
                                            rItemJournalLine.SetRange("Journal Batch Name", rItemJnlBatch.Name);
                                            if rItemJournalLine.FindLast() then
                                                LineNo := rItemJournalLine."Line No." + 10000
                                            else
                                                LineNo := 10000;

                                            rItemJournalLine.Reset();
                                            rItemJournalLine.Init();
                                            rItemJournalLine.Validate("Journal Template Name", rItemJnlTemplate.Name);
                                            rItemJournalLine.Validate("Journal Batch Name", rItemJnlBatch.Name);
                                            rItemJournalLine.Validate("Line No.", LineNo);
                                            rItemJournalLine.Insert(true);

                                            // Rellenar los campos de la línea de diario
                                            rItemJournalLine.Validate("Posting Date", WorkDate());
                                            rItemJournalLine.Validate("Document No.", nAlbaranVenta);
                                            rItemJournalLine.Validate("Entry Type", rItemJournalLine."Entry Type"::Transfer);
                                            rItemJournalLine.Validate("Item No.", rContenidoContenedor."Nº producto");
                                            rItemJournalLine.Validate("Location Code", cAlmacenAlbaran);
                                            rItemJournalLine.Validate("New Location Code", rContenidoContenedor."Cód Almacén");
                                            rItemJournalLine.Validate(Quantity, rContenidoContenedor.Cantidad);
                                            rItemJournalLine.Description := StrSubstNo('Reclasificación a cuarentena - Contenedor %1', rContenidoContenedor.Código);
                                            rItemJournalLine.Modify(true);
                                        end else begin
                                            rItemJournalLine.Validate(Quantity, rItemJournalLine.Quantity + rContenidoContenedor.Cantidad);
                                            rItemJournalLine.Modify();
                                        end;
                                    end;
                                end;

                            end;

                        until rContenidocontenedor.Next() = 0;

                        rItemJnlTemplate.Reset();
                        rItemJnlTemplate.SetRange("Page ID", Page::"Item Reclass. Journal");
                        rItemJnlTemplate.SetRange(Recurring, false);
                        rItemJnlTemplate.SetRange(Type, rItemJnlTemplate.type::Transfer);
                        if rItemJnlTemplate.FindFirst() then begin

                            rItemJnlBatch.Reset();
                            rItemJnlBatch.SetRange("Journal Template Name", rItemJnlTemplate.Name);
                            if rItemJnlBatch.FindFirst() then begin

                                rItemJournalLine.Reset();
                                rItemJournalLine.SetRange("Journal Template Name", rItemJnlTemplate.Name);
                                rItemJournalLine.SetRange("Journal Batch Name", rItemJnlBatch.Name);
                                if rItemJournalLine.FindSet() then
                                    if cItemJnlPost.Run(rItemJournalLine) then
                                        Message('Se han registrado las líneas de reclasificación en el diario de productos.')
                                    else
                                        Error('Ocurrió un error: %1', GetLastErrorText());
                            end;
                        end;

                    end;
                end;
            }

            action(Abonar)
            {
                Caption = 'Abonar al cliente';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = CreditMemo;

                trigger OnAction()
                var
                    rHistoricosIMEI: record "Historicos IMEI";
                    rContenidocontenedor: record "Contenido contenedor";
                    rContenidocontenedor2: record "Contenido contenedor";
                    rAlmacen: Record Location;
                    FromReturnRcptLine: Record "Return Receipt Line";
                    rrSalesReceivablesSetup: record "Sales & Receivables Setup";
                    FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
                    rCabAbo: Record "Sales Header";
                    rCabAbo2: Record "Sales Header";
                    rSalesInvHdr: Record "Sales Invoice Header";
                    rSalesInvLn: record "Sales Invoice Line";
                    rLinAbo: Record "Sales Line";
                    FromSalesShptLine: Record "Sales Shipment Line";
                    rCopySalesDoc: report "Copy Sales Document";
                    CopyDocMgt: Codeunit "Copy Document Mgt.";
                    cNoSeriesMgt: codeunit NoSeriesManagement;
                    pAlmacen: page "Location List";
                    MissingExCostRevLink: Boolean;
                    cPedVenta: code[20];
                    cPedVenta2: code[20];
                    NewFromDocType: Enum "Sales Document Type From";
                    iLinPedVenta: Integer;
                    LinesNotCopied: Integer;
                begin
                    /* 
                    Los datos los buscaremos:
                        1º - Factura de venta
                        2º - Albarán de venta
                        3º - Pedido de venta (abierto)
                        4º - Pedido de venta (archivado)
                        En caso de no encontrar crear cabecera y asociarla en la línea de contenido contenedor, pero dejar pendiente de enlazar (al cubrir datos de cliente generar línea asociada)
                    */
                    //Creamos un pedido de devolución con el almacén y la fecha indicada

                    Clear(pAlmacen);
                    pAlmacen.SetTableView(rAlmacen);
                    pAlmacen.LookupMode := true;
                    if pAlmacen.RunModal() = action::LookupOK then begin
                        pAlmacen.GetRecord(rAlmacen);

                        Clear(cPedVenta);
                        Clear(cPedVenta2);
                        Clear(iLinPedVenta);

                        //filtramos las lineas que tengan un pedido de venta y un nº de linea venta pero que no esten abonados.
                        rContenidocontenedor.Reset();
                        rContenidocontenedor.Copy(Rec);
                        CurrPage.SetSelectionFilter(rContenidocontenedor);
                        rContenidocontenedor.SetFilter(PedVenta, '<>%1', '');
                        rContenidocontenedor.SetFilter(LinPedVenta, '<>%1', 0);
                        rContenidocontenedor.SetFilter("Nº abono venta", '%1', '');
                        rContenidocontenedor.SetFilter("Nº linea abono venta", '%1', 0);
                        rContenidocontenedor.SetCurrentKey(PedVenta, LinPedVenta, Incidencia);
                        if rContenidocontenedor.FindSet() then
                            repeat

                                if (rContenidocontenedor.PedVenta <> cPedVenta) and (rContenidocontenedor.LinPedVenta <> iLinPedVenta) then begin

                                    cPedVenta := rContenidocontenedor.PedVenta;
                                    iLinPedVenta := rContenidocontenedor.LinPedVenta;

                                    //Si encontramos la línea facturada, creamos el abono con los mismos datos
                                    rSalesInvLn.reset();
                                    rSalesInvLn.SetRange("Order No.", Rec.PedVenta);
                                    rSalesInvLn.SetRange("Order Line No.", Rec.LinPedVenta);
                                    if rSalesInvLn.FindFirst() then begin
                                        rSalesInvHdr.get(rSalesInvLn."Document No.");

                                        rrSalesReceivablesSetup.Get();
                                        rrSalesReceivablesSetup.TestField("Credit Memo Nos.");

                                        //Creamos cabeceras de abono cuando no se repita el nº de pedido venta
                                        if cPedVenta2 <> rContenidocontenedor.PedVenta then begin
                                            //Creamos el abono de venta de la factura registrada
                                            rCabAbo.Reset();
                                            rCabAbo.Init();
                                            rCabAbo."Document Type" := rCabAbo."Document Type"::"Credit Memo";
                                            rCabAbo."No." := cNoSeriesMgt.GetNextNo(rrSalesReceivablesSetup."Credit Memo Nos.", WorkDate(), true);
                                            rCabAbo."Sell-to Customer No." := rSalesInvHdr."Sell-to Customer No.";
                                            rCabAbo."Corrected Invoice No." := rSalesInvHdr."No.";
                                            rCabAbo.Insert();

                                            //Copiamos los datos de la factura registrada y traemos todo cabecera y lineas
                                            Clear(rCopySalesDoc);
                                            rCopySalesDoc.SetSalesHeader(rCabAbo);
                                            rCopySalesDoc.SetParameters(NewFromDocType::"Posted Invoice", rSalesInvHdr."No.", true, false);
                                            rCopySalesDoc.UseRequestPage(false);
                                            rCopySalesDoc.Run();

                                            rCabAbo2.Reset();
                                            rCabAbo2.SetRange("Document Type", rCabAbo."Document Type");
                                            rCabAbo2.SetRange("No.", rCabAbo."No.");
                                            if rCabAbo2.FindFirst() then;

                                            //Borramos todas las lineas ya que vamos a insertar solo las que tengan incidencia
                                            rLinAbo.Reset();
                                            rLinAbo.SetRange("Document No.", rCabAbo2."No.");
                                            rLinAbo.SetRange("Document Type", rCabAbo2."Document Type");
                                            if rLinAbo.FindSet() then
                                                rLinAbo.DeleteAll();

                                        end;

                                        //Copiamos la linea de factura que queremos abonar
                                        Clear(CopyDocMgt);
                                        CopyDocMgt.SetProperties(true, false, false, false, true, true, true);
                                        CopyDocMgt.CopySalesLinesToDoc(
                                          Enum::"Sales Document Type From"::"Posted Invoice".AsInteger(), rCabAbo2,
                                          FromSalesShptLine, rSalesInvLn, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);

                                        //comprobamos la cantidad del producto que nos llega de una linea para abonar y sera la que validemos en la linea del abono junto al almacen
                                        rContenidocontenedor2.Reset();
                                        rContenidocontenedor2.SetRange("Nº producto", rContenidocontenedor."Nº producto");
                                        rContenidocontenedor2.SetRange(PedVenta, rContenidocontenedor.PedVenta);
                                        rContenidocontenedor2.SetRange(LinPedVenta, rContenidocontenedor.LinPedVenta);
                                        rContenidocontenedor2.SetRange(Incidencia, true);
                                        if rContenidocontenedor2.FindSet() then
                                            rContenidocontenedor2.CalcSums(Cantidad);

                                        rLinAbo.Reset();
                                        rLinAbo.SetRange("Document No.", rCabAbo2."No.");
                                        rLinAbo.SetRange("Document Type", rCabAbo2."Document Type");
                                        rLinAbo.SetRange(Type, rLinAbo.Type::Item);
                                        rLinAbo.SetRange("No.", rContenidocontenedor."Nº producto");
                                        if rLinAbo.Find('-') then begin
                                            rLinAbo.Validate("Location Code", rAlmacen.Code);
                                            rLinAbo.Validate(Quantity, rContenidocontenedor2.Cantidad);
                                            rLinAbo.Modify();

                                            //Asignamos el nº de abono venta al contenido contenedor
                                            rContenidocontenedor2.Reset();
                                            rContenidocontenedor2.SetRange("Nº producto", rContenidocontenedor."Nº producto");
                                            rContenidocontenedor2.SetRange(PedVenta, rContenidocontenedor.PedVenta);
                                            rContenidocontenedor2.SetRange(LinPedVenta, rContenidocontenedor.LinPedVenta);
                                            rContenidocontenedor2.SetRange(Incidencia, true);
                                            if rContenidocontenedor2.FindSet() then
                                                repeat
                                                    // rContenidocontenedor2.ModifyAll("Nº abono venta", rLinAbo."Document No.");
                                                    // rContenidocontenedor2.ModifyAll("Nº linea abono venta", rLinAbo."Line No.");
                                                    rContenidocontenedor2."Tipo incidencia" := rContenidocontenedor2."Tipo incidencia"::"Credit Memo generated";
                                                    rContenidocontenedor2.Incidencia := false;
                                                    rContenidocontenedor2.PedVenta := '';
                                                    rContenidocontenedor2.LinPedVenta := 0;
                                                    rContenidocontenedor2.EnvioAlm := '';
                                                    rContenidocontenedor2.LinEnvio := 0;
                                                    rContenidocontenedor2."Nº albarán venta" := '';

                                                    //ALMACENAMOS EL Nº ABONO EN EL HISTORIO DE IMEIS
                                                    rHistoricosIMEI.Reset();
                                                    rHistoricosIMEI.SetRange(IMEI, rContenidocontenedor.IMEI);
                                                    if rHistoricosIMEI.FindFirst() then begin
                                                        rHistoricosIMEI.IMEI := rContenidocontenedor.IMEI;
                                                        rHistoricosIMEI."Nº abono venta" := rLinAbo."Document No.";
                                                        rHistoricosIMEI."Fecha registro abono" := rLinAbo."Posting Date";
                                                        rHistoricosIMEI.Modify();
                                                    end else begin // SINO EXISTE EL REGISTRO EN EL HISTORICO LO CREAMOS
                                                        rHistoricosIMEI.Reset();
                                                        rHistoricosIMEI.Init();
                                                        rHistoricosIMEI.IMEI := rContenidocontenedor.IMEI;
                                                        rHistoricosIMEI."Nº abono venta" := rLinAbo."Document No.";
                                                        rHistoricosIMEI."Fecha registro abono" := rLinAbo."Posting Date";
                                                        rHistoricosIMEI.Insert();
                                                    end;

                                                until rContenidocontenedor2.Next() = 0;

                                        end;

                                        //Asignamos en esta variable el nº de pedido de venta para comprobar arriba si estamos en el mismo pedido o es uno nuevo para generar una nueva cabecera de abono
                                        cPedVenta2 := rContenidocontenedor.PedVenta;

                                    end else
                                        Message('El pedido no esta facturado, deshaga el albarán manualmente Nº albarán: %1', rContenidocontenedor."Nº albarán venta");
                                end;

                            until rContenidocontenedor.Next() = 0;

                        Message('Se ha generado correctamente el abono de las lineas con incidencia.');
                        CurrPage.Update(false);

                    end;
                end;
            }

            action("Sustitución de producto")
            {
                Caption = 'Sustitución de producto';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ItemSubstitution;

                trigger OnAction()
                var
                    rContenidocontenedor: record "Contenido contenedor";
                    rItemJournalLine: Record "Item Journal Line";
                    rSalesReceivablesSetup: Record "Sales & Receivables Setup";
                    rItemJournalBatch: Record "Item Journal Batch";
                    pItemJnl: page "Item Journal";
                    LineNo: Integer;
                begin
                    // Obtenga la plantilla del diario y el seccion desde Configuración de ventas y cuentas por cobrar
                    rSalesReceivablesSetup.Get();
                    rSalesReceivablesSetup.TestField("Plantilla regularizacion producto");
                    rSalesReceivablesSetup.TestField("Seccion regularizacion producto");

                    rContenidocontenedor.Reset();
                    rContenidocontenedor.Copy(Rec);
                    CurrPage.SetSelectionFilter(rContenidocontenedor);
                    rContenidocontenedor.SetCurrentKey(PedVenta, LinPedVenta);
                    if rContenidocontenedor.FindSet() then
                        repeat
                            rContenidocontenedor.CalcFields("Cód Almacén");

                            // Verifique que el seccion exista
                            rItemJournalBatch.Get(rSalesReceivablesSetup."Plantilla regularizacion producto", rSalesReceivablesSetup."Seccion regularizacion producto");


                            rItemJournalLine.Reset();
                            rItemJournalLine.SetRange("Journal Template Name", rSalesReceivablesSetup."Plantilla regularizacion producto");
                            rItemJournalLine.SetRange("Journal Batch Name", rSalesReceivablesSetup."Seccion regularizacion producto");
                            rItemJournalLine.SetRange("Item No.", rContenidocontenedor."Nº producto");
                            rItemJournalLine.SetRange("Location Code", rContenidocontenedor."Cód Almacén");
                            if not rItemJournalLine.FindSet() then begin

                                // Busque el último número de línea en el diario
                                rItemJournalLine.Reset();
                                rItemJournalLine.SetRange("Journal Template Name", rSalesReceivablesSetup."Plantilla regularizacion producto");
                                rItemJournalLine.SetRange("Journal Batch Name", rSalesReceivablesSetup."Seccion regularizacion producto");
                                if rItemJournalLine.FindLast() then
                                    LineNo := rItemJournalLine."Line No." + 10000
                                else
                                    LineNo := 10000;

                                // Cree la nueva línea del diario
                                rItemJournalLine.Init();
                                rItemJournalLine.Validate("Journal Template Name", rSalesReceivablesSetup."Plantilla regularizacion producto");
                                rItemJournalLine.Validate("Journal Batch Name", rSalesReceivablesSetup."Seccion regularizacion producto");
                                rItemJournalLine.Validate("Line No.", LineNo);
                                rItemJournalLine.Insert(true);

                                // Complete los detalles de la línea del diario
                                rItemJournalLine.Validate("Posting Date", WorkDate());
                                rItemJournalLine.Validate("Entry Type", rItemJournalLine."Entry Type"::"Positive Adjmt.");
                                rItemJournalLine.Validate("Document No.", rContenidocontenedor."Nº albarán venta");
                                rItemJournalLine.Validate("Item No.", rContenidocontenedor."Nº producto");
                                rItemJournalLine.Validate("Location Code", rContenidocontenedor."Cód Almacén");
                                rItemJournalLine.Validate(Quantity, rContenidocontenedor.Cantidad);

                                rItemJournalLine.Modify(true);

                            end else begin
                                rItemJournalLine.Validate(Quantity, rItemJournalLine.Quantity + rContenidocontenedor.Cantidad);
                                rItemJournalLine.Modify();
                            end;

                            rContenidocontenedor.Validate(PedVenta, '');
                            rContenidocontenedor.Validate(LinPedVenta, 0);
                            rContenidocontenedor.Validate("Nº abono venta", '');
                            rContenidocontenedor.Validate("Nº linea abono venta", 0);
                            rContenidocontenedor.Validate("Tipo incidencia", rContenidocontenedor."Tipo incidencia"::"Item changed");
                            rContenidocontenedor.Modify();

                        until rContenidocontenedor.Next() = 0;

                    rItemJournalLine.Reset();
                    rItemJournalLine.SetRange("Journal Template Name", rSalesReceivablesSetup."Plantilla regularizacion producto");
                    rItemJournalLine.SetRange("Journal Batch Name", rSalesReceivablesSetup."Seccion regularizacion producto");
                    if rItemJournalLine.FindSet() then
                        PAGE.Run(page::"Item Journal", rItemJournalLine);


                end;
            }

            // action(Reemplazar)
            // {
            //     Caption = 'Sustitución de producto';
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     PromotedOnly = true;
            //     Image = ItemSubstitution;

            //     trigger OnAction()
            //     var
            //         rContenidocontenedor: record "Contenido contenedor";
            //         rSalesShipmentLine: record "Sales Shipment Line";
            //         rSalesHeader: record "Sales Header";
            //         rSalesLine: record "Sales Line";
            //         rrSalesReceivablesSetup: record "Sales & Receivables Setup";
            //         rItem: record Item;
            //         cNoSeriesMgt: codeunit "No. Series";
            //         pItem: page "Item List";
            //         cPedVenta: code[20];
            //         iLinPedVenta: Integer;
            //         iLinea: integer;
            //     begin

            //         rrSalesReceivablesSetup.Get();
            //         rrSalesReceivablesSetup.TestField("Order Nos.");

            //         Clear(cPedVenta);
            //         Clear(iLinPedVenta);
            //         Clear(pItem);

            //         pItem.SetTableView(rItem);
            //         pItem.LookupMode := true;
            //         if pItem.RunModal() = action::LookupOK then begin
            //             pItem.GetRecord(rItem);

            //             rContenidocontenedor.Reset();
            //             rContenidocontenedor.Copy(Rec);
            //             CurrPage.SetSelectionFilter(rContenidocontenedor);
            //             rContenidocontenedor.SetCurrentKey(PedVenta, LinPedVenta);
            //             if rContenidocontenedor.FindSet() then
            //                 repeat
            //                     iLinPedVenta := rContenidocontenedor.LinPedVenta;

            //                     IF (cPedVenta <> rContenidocontenedor.PedVenta) or (cPedVenta = '') THEN begin
            //                         //SI NO EXISTE EL PEDIDO DE VENTA LO CREAMOS

            //                         rSalesShipmentLine.Reset();
            //                         rSalesShipmentLine.SetRange("Document No.", rContenidocontenedor."Nº albarán venta");
            //                         rSalesShipmentLine.SetRange(Type, rSalesShipmentLine.Type::Item);
            //                         rSalesShipmentLine.SetRange("No.", rContenidocontenedor."Nº producto");
            //                         if rSalesShipmentLine.FindFirst() then begin

            //                             //CREAMOS LA CABECERA DEL PEDIDO DE VENTA
            //                             rSalesHeader.Reset();
            //                             rSalesHeader.Init();
            //                             rSalesHeader."Document Type" := rSalesHeader."Document Type"::Order;
            //                             rSalesHeader."No." := cNoSeriesMgt.GetNextNo(rrSalesReceivablesSetup."Order Nos.", WorkDate(), true);
            //                             rSalesHeader.Insert();
            //                             rSalesHeader.Validate("Sell-to Customer No.", rSalesShipmentLine."Sell-to Customer No.");
            //                             rSalesHeader.Validate("Posting Date", WorkDate());
            //                             rSalesHeader.Modify();

            //                             //CREAMOS LINEA DE PRODUCTO SUSTITUTIVO
            //                             rSalesLine.Reset();
            //                             rSalesLine.init();
            //                             rSalesLine."Document Type" := rSalesHeader."Document Type";
            //                             rSalesLine."Document No." := rSalesHeader."No.";
            //                             rSalesLine."Line No." := 10000;
            //                             rSalesLine.Insert();
            //                             rSalesLine.Validate("Sell-to Customer No.", rSalesHeader."Sell-to Customer No.");
            //                             rSalesLine.Validate(Type, rSalesLine.Type::Item);
            //                             rSalesLine.Validate("No.", rItem."No.");
            //                             rSalesLine.Validate(Quantity, rContenidocontenedor.Cantidad);
            //                             rSalesLine.Validate("Location Code", rContenidocontenedor."Cód Almacén");
            //                             rSalesLine.Modify();

            //                             //CREAMOS LA LINEA DEL PRODUCTO A DEVOLVER EN NEGATIVO
            //                             rSalesLine.Reset();
            //                             rSalesLine.init();
            //                             rSalesLine."Document Type" := rSalesHeader."Document Type";
            //                             rSalesLine."Document No." := rSalesHeader."No.";
            //                             rSalesLine."Line No." := 20000;
            //                             rSalesLine.Insert();
            //                             rSalesLine.Validate("Sell-to Customer No.", rSalesHeader."Sell-to Customer No.");
            //                             rSalesLine.Validate(Type, rSalesLine.Type::Item);
            //                             rSalesLine.Validate("No.", rContenidocontenedor."Nº producto");
            //                             rSalesLine.Validate(Quantity, -rContenidocontenedor.Cantidad);
            //                             rSalesLine.Validate("Location Code", rContenidocontenedor."Cód Almacén");
            //                             rSalesLine.Modify();

            //                         end

            //                     end ELSE begin
            //                         rSalesHeader.Reset();
            //                         rSalesHeader.SetRange("Document Type", rSalesHeader."Document Type"::Order);
            //                         rSalesHeader.SetRange("No.", cPedVenta);
            //                         if rSalesHeader.FindFirst() then begin

            //                             //BUSCAMOS LA LINEA SUSTITUTIVA Y AÑADIMOS LA CANTIDAD 
            //                             rSalesLine.Reset();
            //                             rSalesLine.SetRange("Document Type", rSalesHeader."Document Type");
            //                             rSalesLine.SetRange("Document No.", rSalesHeader."No.");
            //                             rSalesLine.SetRange(Type, rSalesLine.Type::Item);
            //                             rSalesLine.SetRange("No.", rItem."No.");
            //                             if rSalesLine.FindFirst() then begin
            //                                 rSalesLine.Validate(Quantity, rSalesLine.Quantity + rContenidocontenedor.Cantidad);
            //                                 rSalesLine.Modify();

            //                                 //BUSCAMOS LA LINEA NEGATIVA Y RESTAMOS LA CANTIDAD DE LA LINEA DE CONTENIDO CONTENEDOR EN NEGATIVO
            //                                 rSalesLine.Reset();
            //                                 rSalesLine.SetRange("Document Type", rSalesHeader."Document Type");
            //                                 rSalesLine.SetRange("Document No.", rSalesHeader."No.");
            //                                 rSalesLine.SetRange(Type, rSalesLine.Type::Item);
            //                                 rSalesLine.SetRange("No.", rContenidocontenedor."Nº producto");
            //                                 if rSalesLine.FindFirst() then begin
            //                                     rSalesLine.Validate(Quantity, rSalesLine.Quantity - rContenidocontenedor.Cantidad);
            //                                     rSalesLine.Modify();
            //                                 end
            //                             end else begin
            //                                 //SINO EXISTE LINEA DE ESE PRODUCTO LA CREAMOS
            //                                 Clear(iLinea);

            //                                 rSalesLine.Reset();
            //                                 rSalesLine.SetRange("Document Type", rSalesHeader."Document Type");
            //                                 rSalesLine.SetRange("Document No.", rSalesHeader."No.");
            //                                 if rSalesLine.FindLast() then
            //                                     iLinea := rSalesLine."Line No." + 10000
            //                                 else
            //                                     iLinea := 10000;

            //                                 //CREAMOS LINEA DE PRODUCTO SUSTITUTIVO
            //                                 rSalesLine.Reset();
            //                                 rSalesLine.init();
            //                                 rSalesLine."Document Type" := rSalesHeader."Document Type";
            //                                 rSalesLine."Document No." := rSalesHeader."No.";
            //                                 rSalesLine."Line No." := iLinea;
            //                                 rSalesLine.Insert();
            //                                 rSalesLine.Validate("Sell-to Customer No.", rSalesHeader."Sell-to Customer No.");
            //                                 rSalesLine.Validate(Type, rSalesLine.Type::Item);
            //                                 rSalesLine.Validate("No.", rItem."No.");
            //                                 rSalesLine.Validate(Quantity, rContenidocontenedor.Cantidad);
            //                                 rSalesLine.Validate("Location Code", rContenidocontenedor."Cód Almacén");
            //                                 rSalesLine.Modify();

            //                                 rSalesLine.Reset();
            //                                 rSalesLine.SetRange("Document Type", rSalesHeader."Document Type");
            //                                 rSalesLine.SetRange("Document No.", rSalesHeader."No.");
            //                                 if rSalesLine.FindLast() then
            //                                     iLinea := rSalesLine."Line No." + 10000
            //                                 else
            //                                     iLinea := 10000;

            //                                 //CREAMOS LA LINEA DEL PRODUCTO A DEVOLVER EN NEGATIVO
            //                                 rSalesLine.Reset();
            //                                 rSalesLine.init();
            //                                 rSalesLine."Document Type" := rSalesHeader."Document Type";
            //                                 rSalesLine."Document No." := rSalesHeader."No.";
            //                                 rSalesLine."Line No." := iLinea;
            //                                 rSalesLine.Insert();
            //                                 rSalesLine.Validate("Sell-to Customer No.", rSalesHeader."Sell-to Customer No.");
            //                                 rSalesLine.Validate(Type, rSalesLine.Type::Item);
            //                                 rSalesLine.Validate("No.", rContenidocontenedor."Nº producto");
            //                                 rSalesLine.Validate(Quantity, -rContenidocontenedor.Cantidad);
            //                                 rSalesLine.Validate("Location Code", rContenidocontenedor."Cód Almacén");
            //                                 rSalesLine.Modify();

            //                             end;

            //                         end;

            //                     end;

            //                     cPedVenta := rContenidocontenedor.PedVenta;

            //                 until rContenidocontenedor.Next() = 0;

            //         end;
            //     end;
            // }

        }
    }

}
