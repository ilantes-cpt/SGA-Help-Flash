codeunit 50300 Contenedores
{
    SingleInstance = true;

    var
        bAnularGlobal: Boolean;

    internal procedure VerificarAsignacionContenedor(cContenedor: Code[20]; cPadre: Code[20]): Boolean
    var
        rCont, rPadre : record Contenedores;
    begin
        if (cContenedor = '') or (cpadre = '') then exit(true);
        //rcont.get(cContenedor);
        if rpadre.Get(cPadre) then exit(true);
    end;

    local procedure ProcesarLinDiario(var ItemJournalLine: Record "Item Journal Line"; var rContCont: Record "Contenido contenedor")
    var
        tMensaje: text;
    begin
        //En función de lo que indique el diario realizamos una acción u otra
        tmensaje := '';
        case itemjournalline."Entry Type" of
            itemjournalline."Entry Type"::"Positive Adjmt.", itemjournalline."Entry Type"::Purchase:
                begin
                    if rContCont.find('-') then
                        repeat
                            if rContCont.Vendido then begin
                                rcontcont.Vendido := false;
                                rcontcont.Modify(false);
                            end else begin
                                if tMensaje = '' then
                                    tmensaje := rcontcont.IMEI
                                else
                                    tmensaje += ', ' + rContCont.IMEI;
                            end;
                        until rcontcont.next = 0;
                    if tmensaje <> '' then
                        message('Los siguientes IMEI''s no están marcados como vendidos:\' + tmensaje);
                end;
            itemjournalline."Entry Type"::"Negative Adjmt.", itemjournalline."Entry Type"::Sale:
                if rcontcont.find('-') then
                    repeat
                        rcontcont.Vendido := true;
                        rcontcont.Modify(false);
                    until rcontcont.next = 0;
        end;
    end;

    procedure ValidaPadreContenido(cCaja: code[20]; cPadre: Code[20])
    var
        rContenido: Record "Contenido contenedor";
    begin
        rContenido.reset;
        rContenido.SetRange("Código", cCaja);
        rContenido.SetFilter(Padre, '<>%1', cPadre);
        if rContenido.find('-') then
            repeat
                rContenido.Validate(Padre, cPadre);
                rcontenido.Modify(true);
            until rContenido.next() = 0;
    end;


    //Crear contendores de manera manual - OMITIDO
    /*
    2023-11-16:     Esto solo se va a realizar la primera vez que se quieran importar los contenedores; por ello, vamos a generar un botón en el formulario para que recorra los registros seleccionados y genere en su caso los hijos y los contenidos.
                    En caso de tener cubierto el almacén en el contenedor seleccionado, arrastrar ese valor al contenido, sino utilizar el que esté en la tabla de detalle palet
    [EventSubscriber(ObjectType::Table, Database::Contenedores, 'OnAfterValidateEvent', 'Código', false, false)]
    procedure ComprobCantDetallPalet(var Rec: Record Contenedores; var xRec: Record Contenedores; CurrFieldNo: Integer)
    var
        rDetallPal, rBox : Record AzmHFBreakdownPallet;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        dCantPallet, dCantCaja : Decimal;
        cPalletNo, cBoxNo : Code[20];
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        rWarehouseShipmentLine: Record "Warehouse Shipment Line";
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
    begin
        //Al crear contenedores de manera manual, solo creamos desde la tabla detalle palet si tenemos 
        //Buscamos el registro (si es pallet verificamos su cantidad y agregamos sus contenedores hijos, CAJAS)
        //Si lo que introducimos es un código de caja, verificamos la cantidad y metemos el contenido dentro del contenedor
        rContSetup.Get();
        if rContSetup."Comprobación pallets/cajas" then begin
            if rContSetup."Tipo pallet" = Rec.Tipo then begin
                rDetallPal.reset();
                rDetallPal.SetRange(PalletNo, Rec."Código");
                rDetallPal.SetRange("Contenedor generado", false);
                if rDetallPal.Find('-') then begin
                    rProdUdMedPal.Get(rDetallPal.ItemNo, rContSetup."Ud. medida Pallet");
                    if rDetallPal.Count = rProdUdMedPal."Qty. per Unit of Measure" then begin
                        Rec.Validate("Descripción");
                        rec.Validate("Almacén", rDetallPal.LocationCode);
                        rec.Validate(Ubicacion, rDetallPal.BinCode);
                    end else
                        error(lErr001, rDetallPal.PalletNo, rDetallPal.Count, rProdUdMedPal."Qty. per Unit of Measure");
                    if not rec.Insert(true) then
                        Rec.Modify(true);
                    //COMMIT;
                    //Creamos los contenedores hijo de los pallets
                    cBoxNo := '';
                    repeat
                        if cBoxNo <> rDetallPal.BoxNo then begin
                            cBoxNo := rDetallPal.BoxNo;
                            rContenedor.Init();
                            rcontenedor.Validate(tipo, rContSetup."Tipo caja");
                            rContenedor.Padre := Rec."Código";
                            rContenedor.Validate("Código", cBoxNo);
                        end;
                    until rDetallPal.Next() = 0;
                end;
            end;
            if rContSetup."Tipo caja" = Rec.Tipo then begin
                rbox.reset;
                if rec.padre <> '' then
                    rbox.SetRange(PalletNo, Rec.Padre);
                rbox.SetRange(BoxNo, Rec."Código");
                if rbox.find('-') then begin
                    rProdUdMedCaja.get(rBox.ItemNo, rContSetup."Ud. medida. Caja");
                    if rbox.Count = rProdUdMedCaja."Qty. per Unit of Measure" then begin
                        rec.Validate("Descripción");
                        rec.Validate("Almacén", rbox.LocationCode);
                        rec.Validate(Ubicacion, rbox.BinCode);
                    end else
                        error(lErr002, rbox.BoxNo, rbox.Count, rProdUdMedCaja."Qty. per Unit of Measure");
                    if not rec.Insert(true) then
                        Rec.Modify(true);
                    //COMMIT;
                    //Creamos el contenido para dicho contenedor
                    repeat
                        rContCont.reset;
                        rContCont.SetRange("Código", rec."Código");
                        rContCont.SetRange("Nº producto", rbox.ItemNo);
                        rContCont.SetRange(IMEI, rbox.UnitNo);
                        if not rContCont.find('-') then begin
                            rContCont.init;
                            rContCont.Validate("Código", rec."Código");
                            rContCont.Validate("Nº producto", rbox.ItemNo);
                            rContCont.Validate(Cantidad, 1);
                            rProd.get(rbox.ItemNo);
                            rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                            rContCont.Validate(IMEI, rbox.UnitNo);
                            rContCont.Validate(Caducidad, rbox."Expiration Date");
                            rContCont.Validate("Cód. Almacén", Rec."Almacén");
                            rcontcont.Insert();
                            rbox."Contenedor generado" := true;
                            rbox.Modify();
                            //COMMIT;
                        end;
                    until rBox.Next() = 0;
                end
            end;
        end;
    end;
    */

    //Pedidos compras, recepción almacén

    procedure ComprobCantDetallPaletRecep(var WhseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        rDetallPal, rDetallPalBox, rDetallPalCant, rBox, rDetallBoxCant, rBoxContCont : Record AzmHFBreakdownPallet;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        dCantPallet, dCantCaja, dCant, dCantCont : Decimal;
        cPalletNo, cBoxNo, cDetPallet : Code[20];
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        rWhseReceiptLine: Record "Warehouse Receipt Line";
        rContenedor, rContenedor2 : Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
    begin
        //Buscamos el registro (si es pallet verificamos su cantidad y agregamos sus contenedores hijos, CAJAS)
        //Si lo que introducimos es un código de caja, verificamos la cantidad y metemos el contenido dentro del contenedor
        rContSetup.Get();
        rProd.Get(WhseReceiptLine."Item No.");
        if rProd."Gestión de contenedores" then begin
            if rContSetup."Comprobación pallets/cajas" then begin
                if WhseReceiptLine."Source Type" = 39 then
                    VerificaContenedor(WhseReceiptLine."Source No.", WhseReceiptLine."Qty. to Receive (Base)", WhseReceiptLine."Item No.");
                dCant := 0;
                rWhseReceiptLine.Reset();
                rWhseReceiptLine.SetRange("No.", WhseReceiptLine."No.");
                rWhseReceiptLine.SetFilter("Qty. to Receive", '<>%1', 0);
                if rWhseReceiptLine.FindSet() then
                    repeat
                        dCant += WhseReceiptLine."Qty. to Receive (Base)";
                    until rWhseReceiptLine.Next() = 0;
                dCantPallet := 0;
                rDetallPal.reset();
                rDetallPal.SetRange(OrderNo, WhseReceiptLine."Source No.");
                rDetallPal.SetRange(ItemNo, WhseReceiptLine."Item No.");
                rDetallPal.SetRange("Contenedor generado", false);
                if rDetallPal.find('-') then begin
                    repeat
                        if not rContenedor.Get(rDetallPal.PalletNo) then begin
                            rDetallPalCant.Reset();
                            rDetallPalCant.SetRange(PalletNo, rDetallPal.PalletNo);
                            if rDetallPalCant.FindSet() then begin
                                rProdUdMedPal.Get(rDetallPalCant.ItemNo, rContSetup."Ud. medida Pallet");
                                //if rDetallPalCant.Count = rProdUdMedPal."Qty. per Unit of Measure" then begin
                                if rDetallPalCant.Count <= rProdUdMedPal."Qty. per Unit of Measure" then begin
                                    rContenedor.Init();
                                    rContenedor.Validate(Tipo, rContSetup."Tipo pallet");
                                    rContenedor.Validate("Código", rDetallPal.PalletNo);
                                    rContenedor.Validate("Descripción");
                                    rContenedor.Validate("Almacén", WhseReceiptLine."Location Code");
                                    rContenedor.Validate(Ubicacion, WhseReceiptLine."Bin Code");
                                    dCantPallet += 1;
                                end else
                                    error(lErr001, rDetallPalCant.PalletNo, rDetallPalCant.Count, rProdUdMedPal."Qty. per Unit of Measure");
                                if not rContenedor.Insert(true) then
                                    rContenedor.Modify(true);
                            end;
                        end;
                        //Creamos los contenedores hijo de los pallets
                        if not rContenedor2.get(rDetallPal.BoxNo) then begin
                            rContenedor2.Init();
                            rContenedor2.Validate(tipo, rContSetup."Tipo caja");
                            rContenedor2.Validate("Código", rDetallPal.BoxNo);
                            rContenedor2.Padre := rContenedor."Código";
                            rContenedor2.Validate("Descripción");
                            rContenedor2.Validate("Almacén", WhseReceiptLine."Location Code");
                            rContenedor2.Validate(Ubicacion, WhseReceiptLine."Bin Code");
                            if not rContenedor2.Insert(true) then
                                rcontenedor2.Modify(true);
                            ValidaPadreContenido(rContenedor2."Código", rContenedor2.Padre);
                        end;
                        rContCont.reset;
                        rContCont.SetRange("Código", rDetallPal.BoxNo);
                        rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                        rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                        if not rContCont.find('-') then begin
                            rContCont.init;
                            rContCont.Validate("Código", rDetallPal.BoxNo);
                            rContCont.Validate("Nº producto", rDetallPal.ItemNo);
                            rContCont.Validate(Cantidad, 1);
                            rProd.get(rDetallPal.ItemNo);
                            rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                            rContCont.Validate(IMEI, rDetallPal.UnitNo);
                            rContCont.Validate(Caducidad, rDetallPal."Expiration Date");
                            rcontcont.padre := rDetallPal.PalletNo;
                            //rContCont.Validate("Cód. Almacén", WhseReceiptLine."Location Code");
                            if rcontcont.Insert() then
                                dCantCont += 1;
                        end;
                        rDetallPal."Contenedor generado" := true;
                        rDetallPal.Modify();
                    until (rDetallPal.Next() = 0) or (dCant = dCantCont);
                end;
                if WhseReceiptLine."Source Type" = 39 then
                    AlbDetallPallet(WarehouseReceiptHeader."No.", WhseReceiptLine."Item No.");
            end;
        end;
    end;

    procedure CrearContPedComp(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        rDetallPal, rDetallPalBox, rDetallPalCant, rBox, rDetallBoxCant, rBoxContCont : Record AzmHFBreakdownPallet;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        dCantPallet, dCant, dCantCaja, dCount, dCantCont, dCantDet : Decimal;
        cPalletNo, cBoxNo, cDetPallet : Code[20];
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units maccording to the corresponding unit of measure number.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        rPurchaseLine: Record "Purchase Line";
        rContenedor, rContenedor2 : Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
        rPurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        //Buscamos el registro (si es pallet verificamos su cantidad y agregamos sus contenedores hijos, CAJAS)
        //Si lo que introducimos es un código de caja, verificamos la cantidad y metemos el contenido dentro del contenedor
        //if (PurchaseHeader.Receive) and (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order) and (PurchaseLine."Qty. to Receive" <> 0) then begin
        if (PurchaseHeader.Receive) and (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order) then begin
            rContSetup.Get();
            rProd.Get(PurchaseLine."No.");
            if rProd."Gestión de contenedores" then begin
                if rContSetup."Comprobación pallets/cajas" then begin
                    VerificarCdadContenedor(PurchaseHeader."No.", PurchaseLine);
                    dCant := 0;
                    rPurchaseLine.Reset();
                    rPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                    rPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                    rPurchaseLine.SetRange("No.", PurchaseLine."No.");
                    rPurchaseLine.SetFilter("Qty. to Receive", '<>%1', 0);
                    if rPurchaseLine.FindSet() then begin
                        if rPurchaseLine.CalcSums("Qty. to Receive (Base)") then
                            dCant := rPurchaseLine."Qty. to Receive (Base)";
                        //repeat
                        //dCant += rPurchaseLine."Qty. to Receive (Base)";
                        //until rPurchaseLine.Next() = 0;
                    end;
                    dCantCont := 0;
                    rDetallPal.reset();
                    rDetallPal.SetRange(OrderNo, PurchaseHeader."No.");
                    rDetallPal.SetRange(ItemNo, PurchaseLine."No.");
                    rDetallPal.SetRange("Contenedor generado", false);
                    if rDetallPal.FindSet() then begin
                        if rDetallPal.CalcSums(Quantity) then
                            dCantDet := rDetallPal.Quantity;
                    end;
                    if rDetallPal.find('-') then begin
                        if dCant <= dCantDet then begin
                            repeat
                                if not rContenedor.Get(rDetallPal.PalletNo) then begin
                                    rDetallPalCant.Reset();
                                    rDetallPalCant.SetRange(PalletNo, rDetallPal.PalletNo);
                                    if rDetallPalCant.FindSet() then begin
                                        rProdUdMedPal.Get(rDetallPalCant.ItemNo, rContSetup."Ud. medida Pallet");
                                        //if rDetallPalCant.Count = rProdUdMedPal."Qty. per Unit of Measure" then begin
                                        if rDetallPalCant.Count <= rProdUdMedPal."Qty. per Unit of Measure" then begin
                                            rContenedor.Init();
                                            rContenedor.Validate(Tipo, rContSetup."Tipo pallet");
                                            rContenedor.Validate("Código", rDetallPal.PalletNo);
                                            rContenedor.Validate("Descripción");
                                            rContenedor.Validate("Almacén", PurchaseLine."Location Code");
                                            rContenedor.Validate(Ubicacion, PurchaseLine."Bin Code");
                                        end else
                                            error(lErr001, rDetallPalCant.PalletNo, rDetallPalCant.Count, rProdUdMedPal."Qty. per Unit of Measure");
                                        if not rContenedor.Insert(true) then
                                            rContenedor.Modify(true);
                                    end;
                                end;
                                //Creamos los contenedores hijo de los pallets
                                if not rContenedor2.get(rDetallPal.BoxNo) then begin
                                    rContenedor2.Init();
                                    rContenedor2.Validate(tipo, rContSetup."Tipo caja");
                                    rContenedor2.Validate("Código", rDetallPal.BoxNo);
                                    rContenedor2.Padre := rContenedor."Código";
                                    rContenedor2.Validate("Descripción");
                                    rContenedor2.Validate("Almacén", PurchaseLine."Location Code");
                                    rContenedor2.Validate(Ubicacion, PurchaseLine."Bin Code");
                                    if not rContenedor2.Insert(true) then
                                        rcontenedor2.Modify(true);
                                    ValidaPadreContenido(rContenedor2."Código", rContenedor2.Padre);
                                end;
                                rContCont.reset;
                                rContCont.SetRange("Código", rDetallPal.BoxNo);
                                rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                                rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                                if not rContCont.find('-') then begin
                                    rContCont.init;
                                    rContCont.Validate("Código", rDetallPal.BoxNo);
                                    rContCont.Validate("Nº producto", rDetallPal.ItemNo);
                                    rContCont.Validate(Cantidad, 1);
                                    rProd.get(rDetallPal.ItemNo);
                                    rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                                    rContCont.Validate(IMEI, rDetallPal.UnitNo);
                                    rContCont.Validate(Caducidad, rDetallPal."Expiration Date");
                                    rContCont.Validate(PedCompra, PurchaseLine."Document No.");
                                    rContCont.Validate(LinPedCompra, PurchaseLine."Line No.");
                                    rcontcont.padre := rDetallPal.PalletNo;
                                    //rContCont.Validate("Cód. Almacén", PurchaseLine."Location Code");
                                    if rcontcont.Insert() then
                                        dCantCont += 1;
                                end;
                                rDetallPal."Contenedor generado" := true;
                                rDetallPal.Modify();
                            until (rDetallPal.Next() = 0) or (dCant = dCantCont);
                        end else
                            Error(lError003);
                    end;
                    AlbDetallPallet(PurchaseHeader."No.", PurchaseLine."No.");
                end;
            end;
        end;
    end;

    procedure AlbDetallPallet(cNo: Code[20]; cItemNo: Code[20])
    var
        rDetallPal: Record AzmHFBreakdownPallet;
        rPurchRcptHeader: Record "Purch. Rcpt. Header";
        rPurchaseHeader: Record "Purchase Header";
        rContenedor, rContenedor2 : Record Contenedores;
        rContCont: Record "Contenido contenedor";
    begin
        rPurchaseHeader.Get(rPurchaseHeader."Document Type"::Order, cNo);
        rDetallPal.reset();
        rDetallPal.SetRange(OrderNo, rPurchaseHeader."No.");
        rDetallPal.SetRange(ItemNo, cItemNo);
        rDetallPal.SetRange("Nº Albarán Compra", '');
        rDetallPal.SetRange("Contenedor generado", true);
        if rDetallPal.find('-') then
            repeat
                if rPurchaseHeader."Receiving No." <> '' then
                    rPurchRcptHeader.Get(rPurchaseHeader."Receiving No.")
                else
                    rPurchRcptHeader.Get(rPurchaseHeader."Last Receiving No.");
                rDetallPal.Validate("Nº Albarán Compra", rPurchRcptHeader."No.");
                rDetallPal.Modify();
                rContCont.reset();
                rContCont.SetRange("Código", rDetallPal.BoxNo);
                rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                if rContCont.findset then begin
                    rContCont.Validate("Nº Albarán Compra", rPurchRcptHeader."No.");
                    rContCont.Modify(true);
                    if rContenedor2.Get(rContCont."Código") then
                        if rContenedor.Get(rContenedor2.Padre) then begin
                            rContenedor.Validate("Nº Albarán Compra", rPurchRcptHeader."No.");
                            rContenedor.Modify(true);
                            rContenedor2.Reset();
                            rContenedor2.SetRange(Padre, rContenedor."Código");
                            if rContenedor2.FindSet() then
                                repeat
                                    rContenedor2.Validate("Nº Albarán Compra", rPurchRcptHeader."No.");
                                    rContenedor2.Modify(true);
                                until rContenedor2.Next() = 0;
                        end;
                end
            until rDetallPal.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeTestStatusOpen', '', false, false)]
    local procedure PermitirValidarCoste(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
        //if (PurchaseHeader.Receive) and not (PurchaseHeader.Invoice) and (PurchaseLine."Unit Cost (LCY)" <> xPurchaseLine."Unit Cost (LCY)") and (CallingFieldNo = 23) then IsHandled := true;
        if (PurchaseHeader.Receive) and (PurchaseLine."Unit Cost (LCY)" <> xPurchaseLine."Unit Cost (LCY)") then IsHandled := true;
    end;

    procedure ActualizarCosteLinCompra(PurchaseHeader: Record "Purchase Header")
    var
        rConfCompras: Record "Purchases & Payables Setup";
        rItem, rImsi : Record Item;
        rLinCompra: Record "Purchase Line";
        rBOMComp: Record "BOM Component";
        rConfCont: Record "Containers Setup";
    begin
        rConfCompras.get();
        if not rConfCompras.ConsumirPaquetes then exit;
        //Si no estamos en una prefactura no registramos la baja de los datos
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then exit;
        rLinCompra.reset;
        rLinCompra.SetRange("Document Type", PurchaseHeader."Document Type");
        rLinCompra.SetRange("Document No.", PurchaseHeader."No.");
        if rLinCompra.find('-') then
            repeat
                if rItem.Get(rLinCompra."No.") then begin
                    if rItem."Gestión de contenedores" then begin
                        if (rItem."Gestion IMEI") and not (rItem."Gestión de IMSIs") then begin
                            rConfCont.Get();
                            rBOMComp.Reset();
                            rBOMComp.SetRange("Parent Item No.", rLinCompra."No.");
                            rBOMComp.SetRange("Installed in Item No.", '');
                            if rBOMComp.FindSet() then begin
                                if rImsi.get(rBOMComp."No.") then begin
                                    ritem.Validate("Standard Cost", rImsi."unit cost" + rLinCompra."Direct Unit Cost");
                                    ritem.Modify();
                                    if rLinCompra."Unit Cost (LCY)" <> ritem."Standard Cost" then begin
                                        if not (PurchaseHeader.Status = PurchaseHeader.Status::Open) then
                                            error('Para actualizar el coste (DL) de los paquetes de datos, debe realizar el proceso de registro con el estado abierto');
                                        rLinCompra.Validate("Unit Cost (LCY)", ritem."Standard Cost");
                                        rLinCompra.modify;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            until rLinCompra.Next() = 0;
    end;

    procedure BajaPaqDatosFact(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        rItem, rImsi : Record Item;
        rItemJnlLine: Record "Item Journal Line";
        //rMovProd: Record "Item Ledger Entry";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        rConfCont: Record "Containers Setup";
        LineNo, iEntryNo : Integer;
        recReservationEntry, CheckReservationEntry : record "Reservation Entry";
        rBOMComp: Record "BOM Component";
        cDocNo: Code[20];
        rWarehouseEntry: Record "Warehouse Entry";
        rLocation: Record Location;
        rPurchRcptLine: Record "Purch. Rcpt. Line";
        rPurchRcptHeader: Record "Purch. Rcpt. Header";
        rConfCompras: Record "Purchases & Payables Setup";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        oEstado: Enum "Purchase Document Status";
    begin
        rConfCompras.get();
        if not rConfCompras.ConsumirPaquetes then exit;
        //Si no estamos en una prefactura no registramos la baja de los datos
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then exit;
        if rItem.Get(PurchaseLine."No.") then begin
            if rItem."Gestión de contenedores" then begin
                if (rItem."Gestion IMEI") and not (rItem."Gestión de IMSIs") then begin
                    rConfCont.Get();
                    ItemJnlTemplate.Get(rConfCont."Libro registro productos");
                    ItemJnlBatch.Get(rConfCont."Libro registro productos", rConfCont."Sección registro productos");
                    rItemJnlLine.SetRange("Journal Template Name", rConfCont."Libro registro productos");
                    rItemJnlLine.SetRange("Journal Batch Name", rConfCont."Sección registro productos");
                    if rItemJnlLine.find('-') then
                        rItemJnlLine.DeleteAll();
                    rItemJnlLine.LockTable();
                    if rItemJnlLine.FindLast() then;
                    LineNo := rItemJnlLine."Line No.";
                    cDocNo := PurchaseLine."Document No.";
                    rBOMComp.Reset();
                    rBOMComp.SetRange("Parent Item No.", PurchaseLine."No.");
                    rBOMComp.SetRange("Installed in Item No.", '');
                    if rBOMComp.FindSet() then begin
                        /*
                        if rImsi.get(rBOMComp."No.") then begin
                            ritem.Validate("Standard Cost", rImsi."unit cost" + PurchaseLine."Direct Unit Cost");
                            ritem.Modify();
                            if purchaseline."Unit Cost (LCY)" <> ritem."Standard Cost" then begin
                                if PurchaseHeader.Status <> PurchaseHeader.Status::Open then begin
                                    oEstado := PurchaseHeader.Status;
                                    PurchaseHeader.Status := PurchaseHeader.Status::Open;
                                end;
                                PurchaseLine.Validate("Unit Cost (LCY)", ritem."Standard Cost");
                                purchaseline.modify;
                                if PurchaseHeader.Status <> oEstado then
                                    PurchaseHeader.Status := oEstado;
                            end;
                        end;
                        */
                        /*rMovProd.Reset();
                        rMovProd.SetRange("Item No.", rBOMComp."No.");
                        rMovProd.Setfilter("Entry Type", '%1|%2', rMovProd."Entry Type"::Purchase, rMovProd."Entry Type"::"Positive Adjmt.");
                        rMovProd.Setfilter("Remaining Quantity", '<>%1', 0);
                        rMovProd.SetRange("Location Code", rBOMComp."Consumption Location");
                        if rMovProd.Find('-') then begin
                            repeat*/
                        rItemJnlLine.Init();
                        LineNo := LineNo + 10000;
                        rItemJnlLine."Line No." := LineNo;
                        rItemJnlLine."Journal Template Name" := rConfCont."Libro registro productos";
                        rItemJnlLine."Journal Batch Name" := rConfCont."Sección registro productos";
                        rItemJnlLine.Validate("Entry Type", rItemJnlLine."Entry Type"::"Negative Adjmt.");
                        /*
                        if PurchaseHeader."Receiving No." <> '' then
                            rPurchRcptHeader.Get(PurchaseHeader."Receiving No.")
                        else
                            rPurchRcptHeader.Get(PurchaseHeader."Last Receiving No.");
                        */
                        //rItemJnlLine.Validate("Document No.", PurchaseLine."Receipt No.");
                        rItemJnlLine.Validate("Document No.", PurchaseHeader."Posting No.");
                        //rItemJnlLine.Validate("Item No.", rMovProd."Item No.");
                        rItemJnlLine.Validate("Item No.", rBOMComp."No.");
                        rItemJnlLine.validate("Posting Date", PurchaseHeader."Posting Date");
                        rItemJnlLine.Validate(Quantity, PurchaseLine."Qty. to Invoice");
                        rItemJnlLine.Validate("Quantity (Base)", PurchaseLine."Qty. to Invoice (Base)");
                        //rItemJnlLine."Posting No. Series" := rMovProd."No. Series";
                        //rItemJnlLine.Validate(Description, rMovProd.Description);
                        //rItemJnlLine."Posting No. Series" := rPurchRcptHeader."No. Series";
                        rItemJnlLine.Validate(Description, rBOMComp.Description);
                        rItemJnlLine.Insert(true);
                        /*rItemJnlLine.Validate("Shortcut Dimension 1 Code", rMovProd."Global Dimension 1 Code");
                        rItemJnlLine.Validate("Shortcut Dimension 2 Code", rMovProd."Global Dimension 2 Code");
                        rItemJnlLine.Validate("Dimension Set ID", rMovProd."Dimension Set ID");
                        rItemJnlLine.Validate("Location Code", rMovProd."Location Code");*/
                        rItemJnlLine.Validate("Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 1 Code");
                        rItemJnlLine.Validate("Shortcut Dimension 2 Code", PurchaseLine."Shortcut Dimension 2 Code");
                        rItemJnlLine.Validate("Dimension Set ID", PurchaseLine."Dimension Set ID");
                        rItemJnlLine.Validate("Location Code", rBOMComp."Consumption Location");
                        //buscar en mov de almacén la ubic. si tiene obligatorio el almacen sino no se valida ubic.
                        //rLocation.Get(rMovProd."Location Code");
                        rLocation.Get(rBOMComp."Consumption Location");
                        if rLocation."Bin Mandatory" then begin
                            //rPurchRcptLine.Get(rMovProd."Document No.", rMovProd."Document Line No.");
                            rPurchRcptLine.Get(PurchaseLine."Receipt No.", PurchaseLine."Receipt Line No.");
                            rWarehouseEntry.Reset();
                            //rWarehouseEntry.SetRange("Location Code", rMovProd."Location Code");
                            //rWarehouseEntry.SetRange("Item No.", rMovProd."Item No.");
                            rWarehouseEntry.SetRange("Location Code", rBOMComp."Consumption Location");
                            rWarehouseEntry.SetRange("Item No.", rBOMComp."No.");
                            rWarehouseEntry.SetRange("Source No.", rPurchRcptLine."Order No.");
                            rWarehouseEntry.SetRange("Source Line No.", rPurchRcptLine."Order Line No.");
                            //rWarehouseEntry.SetRange("Registering Date", rMovProd."Posting Date");
                            rWarehouseEntry.SetRange("Registering Date", PurchaseHeader."Posting Date");
                            if rWarehouseEntry.Find('-') then
                                rItemJnlLine."Bin Code" := rWarehouseEntry."Bin Code";
                        end;
                        rItemJnlLine.Validate("Variant Code", PurchaseLine."Variant Code");
                        rItemJnlLine.Validate("Item Category Code", PurchaseLine."Item Category Code");
                        rItemJnlLine.Validate("Inventory Posting Group", PurchaseLine."Posting Group");
                        rItemJnlLine.Validate("Gen. Bus. Posting Group", PurchaseLine."Gen. Bus. Posting Group");
                        rItemJnlLine."Job No." := PurchaseLine."Job No.";
                        rItemJnlLine."Job Task No." := PurchaseLine."Job Task No.";
                        if rItemJnlLine."Job No." <> '' then
                            rItemJnlLine."Job Purchase" := true;
                        rItemJnlLine."Transaction Type" := PurchaseLine."Transaction Type";
                        rItemJnlLine."Transport Method" := PurchaseLine."Transport Method";
                        rItemJnlLine.Area := PurchaseLine.Area;
                        rItemJnlLine."Transaction Specification" := PurchaseLine."Transaction Specification";
                        rItemJnlLine."Drop Shipment" := PurchaseLine."Drop Shipment";
                        rItemJnlLine."Unit of Measure Code" := rBOMComp."Unit of Measure Code";
                        rItemJnlLine."Qty. per Unit of Measure" := rBOMComp."Quantity per";
                        rItemJnlLine."Value Entry Type" := rItemJnlLine."Value Entry Type"::"Direct Cost";
                        rItemJnlLine."Source Type" := rItemJnlLine."Source Type"::Vendor;
                        //rItemJnlLine."Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
                        /*rItemJnlLine."Job No." := rMovProd."Job No.";
                        rItemJnlLine."Job Task No." := rMovProd."Job Task No.";
                        if rItemJnlLine."Job No." <> '' then
                            rItemJnlLine."Job Purchase" := true;
                        rItemJnlLine."Transaction Type" := rMovProd."Transaction Type";
                        rItemJnlLine."Transport Method" := rMovProd."Transport Method";
                        rItemJnlLine.Area := rMovProd.Area;
                        rItemJnlLine."Transaction Specification" := rMovProd."Transaction Specification";
                        rItemJnlLine."Drop Shipment" := rMovProd."Drop Shipment";
                        rItemJnlLine."Unit of Measure Code" := rMovProd."Unit of Measure Code";
                        rItemJnlLine."Qty. per Unit of Measure" := rMovProd."Qty. per Unit of Measure";
                        rItemJnlLine."Item Reference No." := rMovProd."Item Reference No.";
                        rItemJnlLine."Document Line No." := rMovProd."Document Line No.";
                        rItemJnlLine."External Document No." := rMovProd."External Document No.";
                        rItemJnlLine."Value Entry Type" := rItemJnlLine."Value Entry Type"::"Direct Cost";
                        rItemJnlLine."Source Type" := rItemJnlLine."Source Type"::Vendor;
                        //rItemJnlLine."Source No." := PurchaseLine."Buy-from Vendor No.";
                        rItemJnlLine."Source No." := rMovProd."Source No.";
                        rItemJnlLine."Purchasing Code" := rMovProd."Purchasing Code";
                        rItemJnlLine."Return Reason Code" := rMovProd."Return Reason Code";*/
                        rItemJnlLine.Modify();
                        LineNo := LineNo + 10000;
                        if rItem."Item Tracking Code" <> '' then begin
                            CheckReservationEntry.Reset();
                            CheckReservationEntry.SetFilter("Entry No.", '<>%1', 0);
                            if CheckReservationEntry.FindLast() then
                                iEntryNo := 1 + CheckReservationEntry."Entry No."
                            ELSE
                                iEntryNo := 1;
                            recReservationEntry.INIT;
                            recReservationEntry."Entry No." := iEntryNo;
                            recReservationEntry.Positive := FALSE;
                            recReservationEntry."Item No." := rItemJnlLine."Item No.";
                            recReservationEntry."Location Code" := rItemJnlLine."Location Code";
                            recReservationEntry."Reservation Status" := recReservationEntry."Reservation Status"::Prospect;
                            recReservationEntry.Description := rItemJnlLine.Description;
                            recReservationEntry."Creation Date" := rItemJnlLine."Posting Date";
                            recReservationEntry."Source Type" := 83;
                            recReservationEntry."Source Batch Name" := rItemJnlLine."Journal Batch Name";
                            recReservationEntry."Source ID" := rItemJnlLine."Journal Template Name";
                            recReservationEntry."Source Subtype" := 3;
                            recReservationEntry."Source Ref. No." := rItemJnlLine."Line No.";
                            recReservationEntry."Expected Receipt Date" := rItemJnlLine."Posting Date";
                            //recReservationEntry."Lot No." := rMovProd."Lot No.";
                            recReservationEntry."Lot No." := rItemJnlLine."Lot No.";
                            //recReservationEntry.VALIDATE("Quantity (Base)", -ABS(rMovProd."Remaining Quantity"));
                            recReservationEntry.VALIDATE("Quantity (Base)", -ABS(PurchaseLine."Qty. to Invoice (Base)"));
                            recReservationEntry."Qty. per Unit of Measure" := 1;
                            recReservationEntry."Item Tracking" := recReservationEntry."Item Tracking"::"Lot No.";
                            recReservationEntry."Created By" := USERID;
                            recReservationEntry.INSERT;
                        end;
                        //until (rMovProd.Next() = 0) or (rMovProd."Remaining Quantity" = PurchaseLine."Qty. to Receive");
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", rItemJnlLine);
                        //RegistroActivaciones(cDocNo);
                        //end;
                    end;
                end;
            end;
        end;
    end;

    procedure BajaPaqDatos(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        rItem, rImsi : Record Item;
        rItemJnlLine: Record "Item Journal Line";
        //rMovProd: Record "Item Ledger Entry";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        rConfCont: Record "Containers Setup";
        LineNo, iEntryNo : Integer;
        recReservationEntry, CheckReservationEntry : record "Reservation Entry";
        rBOMComp: Record "BOM Component";
        cDocNo: Code[20];
        rWarehouseEntry: Record "Warehouse Entry";
        rLocation: Record Location;
        rPurchRcptLine: Record "Purch. Rcpt. Line";
        rPurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        if not PurchaseHeader.Receive then exit;
        if rItem.Get(PurchaseLine."No.") then begin
            if rItem."Gestión de contenedores" then begin
                if (rItem."Gestion IMEI") and not (rItem."Gestión de IMSIs") then begin
                    rConfCont.Get();
                    ItemJnlTemplate.Get(rConfCont."Libro registro productos");
                    ItemJnlBatch.Get(rConfCont."Libro registro productos", rConfCont."Sección registro productos");
                    rItemJnlLine.SetRange("Journal Template Name", rConfCont."Libro registro productos");
                    rItemJnlLine.SetRange("Journal Batch Name", rConfCont."Sección registro productos");
                    if rItemJnlLine.find('-') then
                        rItemJnlLine.DeleteAll();
                    rItemJnlLine.LockTable();
                    if rItemJnlLine.FindLast() then;
                    LineNo := rItemJnlLine."Line No.";
                    cDocNo := PurchaseLine."Document No.";
                    rBOMComp.Reset();
                    rBOMComp.SetRange("Parent Item No.", PurchaseLine."No.");
                    rBOMComp.SetRange("Installed in Item No.", '');
                    if rBOMComp.FindSet() then begin
                        if rImsi.get(rBOMComp."No.") then begin
                            ritem.Validate("Standard Cost", rImsi."unit cost" + PurchaseLine."Direct Unit Cost");
                            ritem.Modify();
                            if purchaseline."Unit Cost (LCY)" <> ritem."Standard Cost" then begin
                                PurchaseLine.Validate("Unit Cost (LCY)", ritem."Standard Cost");
                                purchaseline.modify;
                            end;
                        end;
                        /*rMovProd.Reset();
                        rMovProd.SetRange("Item No.", rBOMComp."No.");
                        rMovProd.Setfilter("Entry Type", '%1|%2', rMovProd."Entry Type"::Purchase, rMovProd."Entry Type"::"Positive Adjmt.");
                        rMovProd.Setfilter("Remaining Quantity", '<>%1', 0);
                        rMovProd.SetRange("Location Code", rBOMComp."Consumption Location");
                        if rMovProd.Find('-') then begin
                            repeat*/
                        rItemJnlLine.Init();
                        LineNo := LineNo + 10000;
                        rItemJnlLine."Line No." := LineNo;
                        rItemJnlLine."Journal Template Name" := rConfCont."Libro registro productos";
                        rItemJnlLine."Journal Batch Name" := rConfCont."Sección registro productos";
                        rItemJnlLine.Validate("Entry Type", rItemJnlLine."Entry Type"::"Negative Adjmt.");
                        if PurchaseHeader."Receiving No." <> '' then
                            rPurchRcptHeader.Get(PurchaseHeader."Receiving No.")
                        else
                            rPurchRcptHeader.Get(PurchaseHeader."Last Receiving No.");
                        rItemJnlLine.Validate("Document No.", rPurchRcptHeader."No.");
                        //rItemJnlLine.Validate("Item No.", rMovProd."Item No.");
                        rItemJnlLine.Validate("Item No.", rBOMComp."No.");
                        rItemJnlLine.validate("Posting Date", PurchaseHeader."Posting Date");
                        rItemJnlLine.Validate(Quantity, PurchaseLine."Qty. to Receive (Base)");
                        rItemJnlLine.Validate("Quantity (Base)", PurchaseLine."Qty. to Receive (Base)");
                        //rItemJnlLine."Posting No. Series" := rMovProd."No. Series";
                        //rItemJnlLine.Validate(Description, rMovProd.Description);
                        rItemJnlLine."Posting No. Series" := rPurchRcptHeader."No. Series";
                        rItemJnlLine.Validate(Description, rBOMComp.Description);
                        rItemJnlLine.Insert(true);
                        /*rItemJnlLine.Validate("Shortcut Dimension 1 Code", rMovProd."Global Dimension 1 Code");
                        rItemJnlLine.Validate("Shortcut Dimension 2 Code", rMovProd."Global Dimension 2 Code");
                        rItemJnlLine.Validate("Dimension Set ID", rMovProd."Dimension Set ID");
                        rItemJnlLine.Validate("Location Code", rMovProd."Location Code");*/
                        rItemJnlLine.Validate("Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 1 Code");
                        rItemJnlLine.Validate("Shortcut Dimension 2 Code", PurchaseLine."Shortcut Dimension 2 Code");
                        rItemJnlLine.Validate("Dimension Set ID", PurchaseLine."Dimension Set ID");
                        rItemJnlLine.Validate("Location Code", rBOMComp."Consumption Location");
                        //buscar en mov de almacén la ubic. si tiene obligatorio el almacen sino no se valida ubic.
                        //rLocation.Get(rMovProd."Location Code");
                        rLocation.Get(rBOMComp."Consumption Location");
                        if rLocation."Bin Mandatory" then begin
                            //rPurchRcptLine.Get(rMovProd."Document No.", rMovProd."Document Line No.");
                            rPurchRcptLine.Get(rPurchRcptHeader."No.", PurchaseLine."Line No.");
                            rWarehouseEntry.Reset();
                            //rWarehouseEntry.SetRange("Location Code", rMovProd."Location Code");
                            //rWarehouseEntry.SetRange("Item No.", rMovProd."Item No.");
                            rWarehouseEntry.SetRange("Location Code", rBOMComp."Consumption Location");
                            rWarehouseEntry.SetRange("Item No.", rBOMComp."No.");
                            rWarehouseEntry.SetRange("Source No.", rPurchRcptLine."Order No.");
                            rWarehouseEntry.SetRange("Source Line No.", rPurchRcptLine."Order Line No.");
                            //rWarehouseEntry.SetRange("Registering Date", rMovProd."Posting Date");
                            rWarehouseEntry.SetRange("Registering Date", PurchaseHeader."Posting Date");
                            if rWarehouseEntry.Find('-') then
                                rItemJnlLine."Bin Code" := rWarehouseEntry."Bin Code";
                        end;
                        rItemJnlLine.Validate("Variant Code", PurchaseLine."Variant Code");
                        rItemJnlLine.Validate("Item Category Code", PurchaseLine."Item Category Code");
                        rItemJnlLine.Validate("Inventory Posting Group", PurchaseLine."Posting Group");
                        rItemJnlLine.Validate("Gen. Bus. Posting Group", PurchaseLine."Gen. Bus. Posting Group");
                        rItemJnlLine."Job No." := PurchaseLine."Job No.";
                        rItemJnlLine."Job Task No." := PurchaseLine."Job Task No.";
                        if rItemJnlLine."Job No." <> '' then
                            rItemJnlLine."Job Purchase" := true;
                        rItemJnlLine."Transaction Type" := PurchaseLine."Transaction Type";
                        rItemJnlLine."Transport Method" := PurchaseLine."Transport Method";
                        rItemJnlLine.Area := PurchaseLine.Area;
                        rItemJnlLine."Transaction Specification" := PurchaseLine."Transaction Specification";
                        rItemJnlLine."Drop Shipment" := PurchaseLine."Drop Shipment";
                        rItemJnlLine."Unit of Measure Code" := rBOMComp."Unit of Measure Code";
                        rItemJnlLine."Qty. per Unit of Measure" := rBOMComp."Quantity per";
                        rItemJnlLine."Value Entry Type" := rItemJnlLine."Value Entry Type"::"Direct Cost";
                        rItemJnlLine."Source Type" := rItemJnlLine."Source Type"::Vendor;
                        //rItemJnlLine."Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
                        /*rItemJnlLine."Job No." := rMovProd."Job No.";
                        rItemJnlLine."Job Task No." := rMovProd."Job Task No.";
                        if rItemJnlLine."Job No." <> '' then
                            rItemJnlLine."Job Purchase" := true;
                        rItemJnlLine."Transaction Type" := rMovProd."Transaction Type";
                        rItemJnlLine."Transport Method" := rMovProd."Transport Method";
                        rItemJnlLine.Area := rMovProd.Area;
                        rItemJnlLine."Transaction Specification" := rMovProd."Transaction Specification";
                        rItemJnlLine."Drop Shipment" := rMovProd."Drop Shipment";
                        rItemJnlLine."Unit of Measure Code" := rMovProd."Unit of Measure Code";
                        rItemJnlLine."Qty. per Unit of Measure" := rMovProd."Qty. per Unit of Measure";
                        rItemJnlLine."Item Reference No." := rMovProd."Item Reference No.";
                        rItemJnlLine."Document Line No." := rMovProd."Document Line No.";
                        rItemJnlLine."External Document No." := rMovProd."External Document No.";
                        rItemJnlLine."Value Entry Type" := rItemJnlLine."Value Entry Type"::"Direct Cost";
                        rItemJnlLine."Source Type" := rItemJnlLine."Source Type"::Vendor;
                        //rItemJnlLine."Source No." := PurchaseLine."Buy-from Vendor No.";
                        rItemJnlLine."Source No." := rMovProd."Source No.";
                        rItemJnlLine."Purchasing Code" := rMovProd."Purchasing Code";
                        rItemJnlLine."Return Reason Code" := rMovProd."Return Reason Code";*/
                        rItemJnlLine.Modify();
                        LineNo := LineNo + 10000;
                        if rItem."Item Tracking Code" <> '' then begin
                            CheckReservationEntry.Reset();
                            CheckReservationEntry.SetFilter("Entry No.", '<>%1', 0);
                            if CheckReservationEntry.FindLast() then
                                iEntryNo := 1 + CheckReservationEntry."Entry No."
                            ELSE
                                iEntryNo := 1;
                            recReservationEntry.INIT;
                            recReservationEntry."Entry No." := iEntryNo;
                            recReservationEntry.Positive := FALSE;
                            recReservationEntry."Item No." := rItemJnlLine."Item No.";
                            recReservationEntry."Location Code" := rItemJnlLine."Location Code";
                            recReservationEntry."Reservation Status" := recReservationEntry."Reservation Status"::Prospect;
                            recReservationEntry.Description := rItemJnlLine.Description;
                            recReservationEntry."Creation Date" := rItemJnlLine."Posting Date";
                            recReservationEntry."Source Type" := 83;
                            recReservationEntry."Source Batch Name" := rItemJnlLine."Journal Batch Name";
                            recReservationEntry."Source ID" := rItemJnlLine."Journal Template Name";
                            recReservationEntry."Source Subtype" := 3;
                            recReservationEntry."Source Ref. No." := rItemJnlLine."Line No.";
                            recReservationEntry."Expected Receipt Date" := rItemJnlLine."Posting Date";
                            //recReservationEntry."Lot No." := rMovProd."Lot No.";
                            recReservationEntry."Lot No." := rItemJnlLine."Lot No.";
                            //recReservationEntry.VALIDATE("Quantity (Base)", -ABS(rMovProd."Remaining Quantity"));
                            recReservationEntry.VALIDATE("Quantity (Base)", -ABS(PurchaseLine."Qty. to Receive (Base)"));
                            recReservationEntry."Qty. per Unit of Measure" := 1;
                            recReservationEntry."Item Tracking" := recReservationEntry."Item Tracking"::"Lot No.";
                            recReservationEntry."Created By" := USERID;
                            recReservationEntry.INSERT;
                        end;
                        //until (rMovProd.Next() = 0) or (rMovProd."Remaining Quantity" = PurchaseLine."Qty. to Receive");
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", rItemJnlLine);
                        //RegistroActivaciones(cDocNo);
                        //end;
                    end;
                end;
            end;
        end;
    end;

    //Buscar el paquete de datos asociado al producto registrado y en el caso de que exista dar de baja
    procedure ConsumirPaqDatosRecep(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        rItem: Record Item;
        rItemJnlLine: Record "Item Journal Line";
        rMovProd: Record "Item Ledger Entry";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        rConfCont: Record "Containers Setup";
        LineNo, iEntryNo : Integer;
        recReservationEntry, CheckReservationEntry : record "Reservation Entry";
        rBOMComp: Record "BOM Component";
        cDocNo: Code[20];
        rWarehouseEntry: Record "Warehouse Entry";
        rLocation: Record Location;
        rPurchRcptLine: Record "Purch. Rcpt. Line";
        rPurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        if rItem.Get(WarehouseReceiptLine."No.") then begin
            if rItem."Gestión de contenedores" then begin
                if (rItem."Gestion IMEI") and not (rItem."Gestión de IMSIs") then begin
                    rConfCont.Get();
                    ItemJnlTemplate.Get(rConfCont."Libro registro productos");
                    ItemJnlBatch.Get(rConfCont."Libro registro productos", rConfCont."Sección registro productos");
                    rItemJnlLine.SetRange("Journal Template Name", rConfCont."Libro registro productos");
                    rItemJnlLine.SetRange("Journal Batch Name", rConfCont."Sección registro productos");
                    if rItemJnlLine.find('-') then
                        rItemJnlLine.DeleteAll();
                    rItemJnlLine.LockTable();
                    if rItemJnlLine.FindLast() then;
                    LineNo := rItemJnlLine."Line No.";
                    cDocNo := WarehouseReceiptLine."Source No.";
                    rBOMComp.Reset();
                    rBOMComp.SetRange("Parent Item No.", WarehouseReceiptLine."No.");
                    rBOMComp.SetRange("Installed in Item No.", '');
                    if rBOMComp.FindSet() then begin
                        /*rMovProd.Reset();
                        rMovProd.SetRange("Item No.", rBOMComp."No.");
                        rMovProd.Setfilter("Entry Type", '%1|%2', rMovProd."Entry Type"::Purchase, rMovProd."Entry Type"::"Positive Adjmt.");
                        rMovProd.SetRange("Location Code", rBOMComp."Consumption Location");
                        rMovProd.Setfilter("Remaining Quantity", '<>%1', 0);
                        if rMovProd.Find('-') then begin
                            repeat*/
                        rItemJnlLine.Init();
                        LineNo := LineNo + 10000;
                        rItemJnlLine."Line No." := LineNo;
                        rItemJnlLine."Journal Template Name" := rConfCont."Libro registro productos";
                        rItemJnlLine."Journal Batch Name" := rConfCont."Sección registro productos";
                        rItemJnlLine.Validate("Entry Type", rItemJnlLine."Entry Type"::"Negative Adjmt.");
                        if WarehouseReceiptHeader."Receiving No." <> '' then
                            rPurchRcptHeader.Get(WarehouseReceiptHeader."Receiving No.")
                        else
                            rPurchRcptHeader.Get(WarehouseReceiptHeader."Last Receiving No.");
                        rItemJnlLine.Validate("Document No.", rPurchRcptHeader."No.");
                        //rItemJnlLine.Validate("Item No.", rMovProd."Item No.");
                        rItemJnlLine.Validate("Item No.", rBOMComp."No.");
                        rItemJnlLine.validate("Posting Date", WarehouseReceiptHeader."Posting Date");
                        rItemJnlLine.Validate(Quantity, WarehouseReceiptLine."Qty. to Receive (Base)");
                        rItemJnlLine.Validate("Quantity (Base)", WarehouseReceiptLine."Qty. to Receive (Base)");
                        //rItemJnlLine."Posting No. Series" := rMovProd."No. Series";
                        //rItemJnlLine.Validate(Description, rMovProd.Description);
                        rItemJnlLine."Posting No. Series" := rPurchRcptHeader."No. Series";
                        rItemJnlLine.Validate(Description, rBOMComp.Description);
                        rItemJnlLine.Insert(true);
                        /*rItemJnlLine.Validate("Shortcut Dimension 1 Code", rMovProd."Global Dimension 1 Code");
                        rItemJnlLine.Validate("Shortcut Dimension 2 Code", rMovProd."Global Dimension 2 Code");
                        rItemJnlLine.Validate("Dimension Set ID", rMovProd."Dimension Set ID");*/
                        rItemJnlLine.Validate("Location Code", rBOMComp."Consumption Location");
                        //buscar en mov de almacén la ubic. si tiene obligatorio el almacen sino no se valida ubic.
                        rLocation.Get(rBOMComp."Consumption Location");
                        if rLocation."Bin Mandatory" then begin
                            //rPurchRcptLine.Get(rMovProd."Document No.", rMovProd."Document Line No.");
                            rPurchRcptLine.Get(rPurchRcptHeader."No.", WarehouseReceiptLine."Line No.");
                            rWarehouseEntry.Reset();
                            //rWarehouseEntry.SetRange("Location Code", rMovProd."Location Code");
                            //rWarehouseEntry.SetRange("Item No.", rMovProd."Item No.");
                            rWarehouseEntry.SetRange("Location Code", rBOMComp."Consumption Location");
                            rWarehouseEntry.SetRange("Item No.", rBOMComp."No.");
                            rWarehouseEntry.SetRange("Source No.", rPurchRcptLine."Order No.");
                            rWarehouseEntry.SetRange("Source Line No.", rPurchRcptLine."Order Line No.");
                            //rWarehouseEntry.SetRange("Registering Date", rMovProd."Posting Date");
                            rWarehouseEntry.SetRange("Registering Date", WarehouseReceiptHeader."Posting Date");
                            if rWarehouseEntry.Find('-') then
                                rItemJnlLine."Bin Code" := rWarehouseEntry."Bin Code";
                        end;
                        rItemJnlLine.Validate("Variant Code", WarehouseReceiptLine."Variant Code");
                        rItemJnlLine."Drop Shipment" := rMovProd."Drop Shipment";
                        rItemJnlLine."Unit of Measure Code" := rBOMComp."Unit of Measure Code";
                        rItemJnlLine."Qty. per Unit of Measure" := rBOMComp."Quantity per";
                        rItemJnlLine."Value Entry Type" := rItemJnlLine."Value Entry Type"::"Direct Cost";
                        rItemJnlLine."Source Type" := rItemJnlLine."Source Type"::Vendor;
                        rItemJnlLine.Modify();
                        LineNo := LineNo + 10000;
                        if rItem."Item Tracking Code" <> '' then begin
                            CheckReservationEntry.Reset();
                            CheckReservationEntry.SetFilter("Entry No.", '<>%1', 0);
                            if CheckReservationEntry.FindLast() then
                                iEntryNo := 1 + CheckReservationEntry."Entry No."
                            ELSE
                                iEntryNo := 1;
                            recReservationEntry.INIT;
                            recReservationEntry."Entry No." := iEntryNo;
                            recReservationEntry.Positive := FALSE;
                            recReservationEntry."Item No." := rItemJnlLine."Item No.";
                            recReservationEntry."Location Code" := rItemJnlLine."Location Code";
                            recReservationEntry."Reservation Status" := recReservationEntry."Reservation Status"::Prospect;
                            recReservationEntry.Description := rItemJnlLine.Description;
                            recReservationEntry."Creation Date" := rItemJnlLine."Posting Date";
                            recReservationEntry."Source Type" := 83;
                            recReservationEntry."Source Batch Name" := rItemJnlLine."Journal Batch Name";
                            recReservationEntry."Source ID" := rItemJnlLine."Journal Template Name";
                            recReservationEntry."Source Subtype" := 3;
                            recReservationEntry."Source Ref. No." := rItemJnlLine."Line No.";
                            recReservationEntry."Expected Receipt Date" := rItemJnlLine."Posting Date";
                            recReservationEntry."Lot No." := rItemJnlLine."Lot No.";
                            //recReservationEntry.VALIDATE("Quantity (Base)", -ABS(rMovProd."Remaining Quantity"));
                            recReservationEntry.VALIDATE("Quantity (Base)", -ABS(WarehouseReceiptLine."Qty. to Receive (Base)"));
                            recReservationEntry."Qty. per Unit of Measure" := 1;
                            recReservationEntry."Item Tracking" := recReservationEntry."Item Tracking"::"Lot No.";
                            recReservationEntry."Created By" := USERID;
                            recReservationEntry.INSERT;
                        end;
                        //until (rMovProd.Next() = 0) or (rMovProd."Remaining Quantity" = WarehouseReceiptLine."Qty. to Receive");
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", rItemJnlLine);
                        //RegistroActivaciones(cDocNo);
                        //end;
                    end;
                end;
            end;
        end;
    end;

    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostInvoice', '', false, false)]
    local procedure ActualizarCoste(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean; var Window: Dialog; HideProgressWindow: Boolean; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var InvoicePostingInterface: Interface "Invoice Posting"; var InvoicePostingParameters: Record "Invoice Posting Parameters"; GenJnlLineDocNo: Code[20]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocType: Enum "Gen. Journal Document Type"; SrcCode: Code[10])
    var
        rLinCompra: Record "Purchase Line";
        rItem, rImsi : Record Item;
        rBOMC: Record "BOM Component";
    begin
        if (PreviewMode) then exit;
        rLinCompra.reset;
        rLinCompra.setrange(rLinCompra."Document Type", PurchHeader."Document Type");
        rLinCompra.setrange(rLinCompra."Document No.", PurchHeader."No.");
        if rLinCompra.find('-') then
            repeat
                if ritem.get(rLinCompra."No.") then
                    if (ritem."Gestion IMEI") and not (ritem."Gestión de IMSIs") then begin
                        //Buscamos el IMSI asociado y le ponemos en el coste directo de la ficha de producto la suma del coste
                        //del producto IMSI y el coste que tengamos en la línea del pedido/factura
                        rBOMC.reset;
                        rbomc.SetRange("Parent Item No.", ritem."No.");
                        rbomc.setfilter("Installed in Item No.", '');
                        if rBOMC.find('-') then
                            if rImsi.get(rbomc."No.") then begin
                                //ritem.Validate("Standard Cost", rImsi."Standard Cost" + rLinCompra."Direct Unit Cost");
                                ritem.Validate("Standard Cost", rImsi."unit cost" + rLinCompra."Direct Unit Cost");
                                ritem.Modify();
                            end;
                    end;
            until rLinCompra.Next() = 0;
    end;*/


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnCheckAndUpdateOnBeforeCalcInvDiscount', '', false, false)]
    procedure ActualizarCostesLinCompra(var PurchaseHeader: Record "Purchase Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseReceive: Boolean; WhseShip: Boolean; var RefreshNeeded: Boolean)
    begin
        ActualizarCosteLinCompra(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostItemLine', '', false, false)]
    procedure ContenedoresPedCompra(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; RemQtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal; sender: Codeunit "Purch.-Post"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    begin
        CrearContPedComp(PurchaseHeader, PurchaseLine);
        BajaPaqDatosFact(PurchaseHeader, PurchaseLine);
        //BajaPaqDatos(PurchaseHeader, PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeInsertValueEntry', '', false, false)]
    local procedure AlInsertarValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean; var OldItemLedgEntry: Record "Item Ledger Entry"; var Item: Record Item; TransferItem: Boolean; var GlobalValueEntry: Record "Value Entry")
    var
        rValueEntry: Record "Value Entry";
    begin
        if rValueEntry.get(ValueEntry."Entry No.") then begin
            rValueEntry.Reset();
            rValueEntry.FindLast();
            ValueEntry."Entry No." := rValueEntry."Entry No." + 1;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnAfterCode', '', false, false)]
    procedure ContenedoresRecepAlm(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; CounterSourceDocOK: Integer; CounterSourceDocTotal: Integer)
    begin
        ComprobCantDetallPaletRecep(WarehouseReceiptLine, WarehouseReceiptHeader);
        //ConsumirPaqDatosRecep(WarehouseReceiptLine, WarehouseReceiptHeader);
    end;

    /*procedure RegistroActivaciones(cDocNo: Code[20])
    var
        rDetallPal: Record AzmHFBreakdownPallet;
        rActIMEI: Record "Activaciones IMEI";
    begin
        rDetallPal.Reset();
        rDetallPal.SetRange("Contenedor generado", true);
        rDetallPal.SetRange(OrderNo, cDocNo);
        if rDetallPal.FindSet() then
            repeat
                rActIMEI.Init();
                rActIMEI.Validate(IMEI, rDetallPal.UnitNo);
                rActIMEI.Validate("Fecha activación", rDetallPal."Manufacturing Date");
                rActIMEI.Validate(Coste, rDetallPal."Unit Cost");
                rActIMEI.Validate("Fecha caducidad", rDetallPal."Expiration Date");
                if not rActIMEI.Insert(true) then rActIMEI.Modify(true);
            until rDetallPal.Next() = 0;
    end;*/

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnAfterNewPurchRcptLineInsert', '', false, false)]
    procedure DeshacerRecep(var NewPurchRcptLine: Record "Purch. Rcpt. Line"; OldPurchRcptLine: Record "Purch. Rcpt. Line")
    var
        rDetallPal, rBox : Record AzmHFBreakdownPallet;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        cPalletNo, cBoxNo, cDetPallet : Code[20];
        rPurchaseLine: Record "Purchase Line";
        rContenedor, rContenedor2 : Record Contenedores;
        rContCont: Record "Contenido contenedor";
    begin
        rDetallPal.reset();
        rDetallPal.SetRange("Nº Albarán Compra", NewPurchRcptLine."Document No.");
        rDetallPal.SetRange(ItemNo, NewPurchRcptLine."No.");
        rDetallPal.SetRange("Contenedor generado", true);
        if rDetallPal.find('-') then
            repeat
                if rContenedor.Get(rDetallPal.PalletNo) then begin
                    rContCont.reset;
                    rContCont.SetRange(Padre, rContenedor."Código");
                    rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                    //rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                    if rContCont.find('-') then begin
                        repeat
                            rContCont.Delete();
                        until rContCont.Next() = 0;
                    end;
                    rContenedor.Delete();
                end;
                if rContenedor2.Get(rDetallPal.BoxNo) then begin
                    if rDetallPal.PalletNo = rContenedor2.Padre then begin
                        rContCont.reset;
                        rContCont.SetRange("Código", rContenedor2."Código");
                        rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                        //rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                        if rContCont.find('-') then
                            repeat
                                rContCont.Delete();
                            until rContCont.Next() = 0;
                        rContenedor2.Delete();
                    end;
                end;
                rDetallPal."Contenedor generado" := false;
                rDetallPal.Validate("Nº Albarán Compra", '');
                rDetallPal.Modify();
            until rDetallPal.Next() = 0;
    end;

    //Campos que se cubren en este punto: N.º pedido IMSI y Precio IMSI, al registrar el pedido con el paquete de datos
    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnAfterPost', '', false, false)]
    procedure RegistroPedIMSI(var PurchaseHeader: Record "Purchase Header")
    var
        rDetallPal: Record AzmHFBreakdownPallet;
        rPurchaseLine: Record "Purchase Line";
        dCantIMSI: Decimal;
        rItem: Record Item;
    begin
        rPurchaseLine.Reset();
        rPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        rPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if rPurchaseLine.FindSet() then
            repeat
                if rItem.Get(rPurchaseLine."No.") then
                    if rItem."Gestión de IMSIs" then begin
                        dCantIMSI := 0;
                        rDetallPal.Reset();
                        rDetallPal.SetCurrentKey(EntryNo);
                        rDetallPal.SetFilter(IMSI, '<>%1', '');
                        rDetallPal.SetRange("Nº pedido IMSI", '');
                        rDetallPal.SetRange(OnlyIMSI, true);
                        if rDetallPal.FindSet() then
                            repeat
                                //if rPurchaseLine."Qty. to Receive" > dCantIMSI then begin
                                if rPurchaseLine."Quantity Received" > dCantIMSI then begin
                                    rDetallPal.Validate("Nº pedido IMSI", rPurchaseLine."Document No.");
                                    rDetallPal.Validate("Unit Cost", rPurchaseLine."Direct Unit Cost");
                                    if rDetallPal.Modify(true) then
                                        dCantIMSI += 1;
                                end;
                            until (rDetallPal.Next() = 0) or (rPurchaseLine."Quantity Received" = dCantIMSI);
                        //until (rDetallPal.Next() = 0) or (rPurchaseLine."Qty. to Receive" = dCantIMSI);
                    end;
            until rPurchaseLine.Next() = 0;
    end;*/

    procedure VerificarCdadContenedor(cPedNo: code[20]; var rPLine: Record "Purchase Line")
    var
        rProd: record item;
        rLinped: Record "Purchase Line";
        dCdadPed: Decimal;
        cProd: code[20];
    begin
        rLinped.reset;
        rLinped.SetCurrentKey("No.");
        //rLinped.SetAscending("No.", true);
        rLinped.SetRange("Document Type", rLinped."Document Type"::Order);
        rLinped.SetRange("Document No.", cPedNo);
        rLinped.SetRange(Type, rLinped.Type::Item);
        rlinped.SetRange("Line No.", rPLine."Line No.");
        if rlinped.Find('-') then
            repeat
                rprod.get(rlinped."No.");
                if rprod."Gestión de contenedores" then begin
                    if cprod <> rLinped."No." then begin
                        if Cprod <> '' then begin
                            VerificaContenedor(cpedno, dCdadPed, cProd);
                        end;
                        cProd := rLinped."No.";
                        dCdadPed := 0;
                    end;
                    dCdadPed += rLinped."Qty. to Receive (Base)";
                end;
            until rLinped.next = 0;
        /*
        if (dCdadPed <> 0) and (cprod <> '') then
            VerificaContenedor(cpedno, dCdadPed, cProd);
        */
    end;

    Procedure VerificaContenedor(cPed: code[20]; dCdadRec: Decimal; cProd: code[20])
    var
        rProd: record item;
        rDet: record AzmHFBreakdownPallet;
        lText0001: Label 'The merchandise receipt cannot be generated. We only have %1 units in the pallet detail table pending to be generated.', comment = 'ESP="No se puede generar la recepción de mercancía. Solo tenemos %1 unidades en la tabla detalle palet pendientes de generar."';
        lText0002: Label 'The merchandise receipt cannot be generated. There are no units in the pallet detail table to be generated.', comment = 'ESP="No se puede generar la recepción de mercancía. No disponemos de unidades en la tabla detalle palet pendientes de generar."';
    begin
        rprod.get(cprod);
        if rprod."Gestión de contenedores" then begin
            rdet.reset;
            rdet.SetRange(OrderNo, cped);
            rdet.SetRange(ItemNo, cProd);
            rdet.SetRange("Contenedor generado", false);
            if rdet.Find('-') then begin
                if rdet.Count < dCdadRec then
                    error(lText0001, format(rdet.count));
            end else
                error(lText0002, format(rdet.count));
        end;
    end;

    // Pedidos Ventas

    //OnBeforePostSourceDocument    OnCodeOnAfterWhseRcptHeaderModify   OnAfterGetInboundDocs   OnAfterPostSourceDocument OnAfterConfirmPost
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnCodeOnAfterWhseRcptHeaderModify', '', false, false)]
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Inbound", 'OnAfterCreateWhseReceiptHeaderFromWhseRequest', '', false, false)]
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnBeforePostSourceDocument', '', false, false)]
    //procedure validRecepReg(TransferHeader: Record "Transfer Header"; var WhseRcptLine: Record "Warehouse Receipt Line")
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt (Yes/No)", 'OnAfterConfirmPost', '', false, false)]
    procedure validRecepReg(WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    var
        rContSetup: Record "Containers Setup";
        rContCont, rcontenido : Record "Contenido contenedor";
        rWarehouseReceiptLineReg: Record "Posted Whse. Receipt Line";
        rWarehouseReceiptLine: Record "Warehouse Receipt Line";
        rContenedor, rContenedor3, rContenedor2 : Record Contenedores;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        cPadre, cPalet : Code[20];
        bProd: Boolean;
        rLocation: Record Location;
        dCantCont, dCantContPal : Decimal;
        TransferHeader: Record "Transfer Header";
    begin
        bProd := false;
        dCantContPal := 0;
        if TransferHeader.Get(WhseReceiptLine."Source No.") then begin
            rWarehouseReceiptLine.Reset();
            rWarehouseReceiptLine.SetRange("No.", WhseReceiptLine."No.");
            if rWarehouseReceiptLine.FindSet() then
                repeat
                    rContSetup.Get();
                    if rContSetup."Comprobación pallets/cajas" then begin
                        //Cuando llegamos a este punto, ya se ha seleccionado correctamente los contenedores, solo se debe modificar el almacén en cajas y pallets si están completos
                        rContCont.reset();
                        rContCont.SetRange("Nº producto", rWarehouseReceiptLine."Item No.");
                        rContCont.SetRange(RecepAlm, rWarehouseReceiptLine."No.");
                        rContCont.SetRange(LinRecep, rWarehouseReceiptLine."Line No.");
                        //rContCont.SetRange("Cód. Almacén", TransferHeader."In-Transit Code");
                        if rContCont.find('-') then begin
                            rProdUdMedPal.Get(rContCont."Nº producto", rContSetup."Ud. medida Pallet");
                            rProdUdMedCaja.Get(rContCont."Nº producto", rContSetup."Ud. medida. Caja");
                            repeat
                                rContenedor.Get(rContCont."Código");
                                if (rContenedor2.Get(rContenedor.Padre)) and (rcontenedor.padre <> '') then begin
                                    if rContenedor2."Almacén" <> TransferHeader."Transfer-to Code" then begin
                                        dCantContPal := VerificarCdadContPalRecep(rContenedor2."Código", rWarehouseReceiptLine."No.", rWarehouseReceiptLine."Line No.", rWarehouseReceiptLine."Item No.");
                                        cPalet := rContenedor2."Código";
                                        if dCantContPal = rProdUdMedPal."Qty. per Unit of Measure" then begin
                                            rContenedor3.Get(rContCont."Código");
                                            rContenedor.Get(rContenedor3.Padre);
                                            rContenedor.Validate("Almacén", TransferHeader."Transfer-to Code");
                                            rContenedor.Modify(true);
                                            rContenedor3.Reset();
                                            rContenedor3.SetRange(Padre, rContenedor."Código");
                                            if rContenedor3.FindSet() then
                                                repeat
                                                    rContenedor3.Validate("Almacén", TransferHeader."Transfer-to Code");
                                                    rContenedor3.Modify(true);
                                                until rContenedor3.Next() = 0;
                                        end;
                                    end;
                                    if rcontenedor."Almacén" <> TransferHeader."Transfer-to Code" then
                                        if dCantContPal < rProdUdMedPal."Qty. per Unit of Measure" then begin
                                            dCantCont := VerificarCdadContRecep(rContCont."Código", rWarehouseReceiptLine."No.", rWarehouseReceiptLine."Line No.", rWarehouseReceiptLine."Item No.");
                                            if (dCantContPal < rProdUdMedPal."Qty. per Unit of Measure") and (dCantCont = rProdUdMedCaja."Qty. per Unit of Measure") then
                                                bProd := true
                                            else
                                                bprod := false;
                                        end;
                                end;
                                //rContCont.Validate("Cód. Almacén", TransferHeader."Transfer-to Code");
                                rContCont.Validate(RecepAlm, '');
                                rContCont.Validate(LinRecep, 0);
                                rContCont.Modify(true);
                                if bProd then begin
                                    rContenedor.Get(rContCont."Código");
                                    rContenedor.Validate("Almacén", TransferHeader."Transfer-to Code");
                                    rContenedor.Modify(true);
                                end;
                            until rContCont.Next() = 0;
                        end;
                    end;
                until rWarehouseReceiptLine.Next() = 0
        end;
    end;

    procedure VerificarCdadContRecep(cCodNo: code[20];
            cDocNo: code[20];
            cLin: Integer;
            cProd: code[20]) dCantCont: Decimal
    var
        rContCont: Record "Contenido contenedor";
    begin
        dCantCont := 0;
        rContCont.reset;
        rContCont.SetRange("Código", cCodNo);
        rContCont.SetRange(RecepAlm, cDocNo);
        rContCont.SetRange(LinRecep, cLin);
        rContCont.SetRange("Nº producto", cProd);
        if rContCont.Find('-') then begin
            if rContCont.CalcSums(Cantidad) then
                dCantCont := rContCont.Cantidad;
        end;
    end;

    procedure VerificarCdadContPalRecep(cCodNo: code[20]; cDocNo: code[20]; cLin: Integer; cProd: code[20]) dCantCont: Decimal
    var
        rContCont: Record "Contenido contenedor";
    begin
        dCantCont := 0;
        rContCont.reset;
        rContCont.SetRange(Padre, cCodNo);
        rContCont.SetRange(RecepAlm, cDocNo);
        rContCont.SetRange(LinRecep, cLin);
        rContCont.SetRange("Nº producto", cProd);
        if rContCont.Find('-') then begin
            if rContCont.CalcSums(Cantidad) then
                dCantCont := rContCont.Cantidad;
        end;
    end;

    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", 'OnAfterCode', '', false, false)]
    procedure validEnvReg(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        rContSetup: Record "Containers Setup";
        rContCont, rcontenido : Record "Contenido contenedor";
        rWarehouseShipmentLine: Record "Warehouse Shipment Line";
        rContenedor, rContenedor2 : Record Contenedores;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        cPadre: Code[20];
        bProd: Boolean;
        rLocation: Record Location;
        dCantCont, dCantContPal : Decimal;
    begin
        rWarehouseShipmentLine.Reset();
        rWarehouseShipmentLine.SetRange("No.", WarehouseShipmentLine."No.");
        if rWarehouseShipmentLine.FindSet() then
            repeat
                rContSetup.Get();
                if rContSetup."Comprobación pallets/cajas" then begin
                    rContCont.reset();
                    rContCont.SetRange("Nº producto", WarehouseShipmentLine."Item No.");
                    rContCont.SetRange(PedVenta, WarehouseShipmentLine."Source No.");
                    rContCont.SetRange(LinPedVenta, WarehouseShipmentLine."Source Line No.");
                    if rContCont.find('-') then begin
                        rProdUdMedPal.Get(rContCont."Nº producto", rContSetup."Ud. medida Pallet");
                        rProdUdMedCaja.Get(rContCont."Nº producto", rContSetup."Ud. medida. Caja");
                        repeat
                            rContenedor.Get(rContCont."Código");
                            if rContenedor2.Get(rContenedor.Padre) then
                                dCantContPal := VerificarCdadContPalPed(rContenedor2."Código", WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.", WarehouseShipmentLine."Item No.")
                            else
                                dCantContPal := 0;
                            dCantCont := VerificarCdadContPed(rContCont."Código", WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.", WarehouseShipmentLine."Item No.");
                            if (dCantContPal < rProdUdMedPal."Qty. per Unit of Measure") and (dCantCont = rProdUdMedCaja."Qty. per Unit of Measure") then begin
                                cPadre := '';
                                rContenedor.Get(rContCont."Código");
                                rContenedor.Validate(Padre, cPadre);
                                rContenedor.Modify(true);
                            end else
                                if dCantCont < rProdUdMedCaja."Qty. per Unit of Measure" then begin
                                    bProd := true;
                                end;
                            if bProd then begin
                                rLocation.Get(rContenedor."Almacén");
                                rcontenido.Copy(rContCont);
                                rcontenido.Rename(rLocation."Contenedor devoluciones", rContCont."Nº producto", rContCont.IMEI);
                            end;
                        until rContCont.Next() = 0;
                    end;
                end;
            until rWarehouseShipmentLine.Next() = 0
    end;*/


    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertShipmentLine', '', false, false)] OnAfterPostSalesLines, OnAfterPostSalesDoc
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnPostSalesLineOnBeforeUpdateSalesLineBeforePost', '', false, false)]
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnAfterPost', '', false, false)]
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnRunOnBeforeFinalizePosting', '', false, false)]
    //procedure validAlbVendReg(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line"; PreviewMode: Boolean)
    //procedure validAlbVendReg(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; WhseReceive: Boolean; WhseShip: Boolean; CommitIsSuppressed: Boolean; RoundingLineInserted: Boolean)
    //procedure validContReg(var SalesHeader: Record "Sales Header")
    //procedure validContReg(var SalesHeader: Record "Sales Header"; SalesShptHdrNo: Code[20])
    procedure validContReg(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        rContSetup: Record "Containers Setup";
        rContCont, rcontenido, rContCont2 : Record "Contenido contenedor";
        rSalesShptLine: Record "Sales Shipment Line";
        rSalesCrMemoLine: record "Sales Cr.Memo Line";
        SalesLine: Record "Sales Line";
        rContenedor, rContenedor2 : Record Contenedores;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        cPadre: Code[20];
        bProd: Boolean;
        rLocation: Record Location;
        dCantCont, dCantContPal : Decimal;
        dCdadAlb: Decimal;
    begin
        //Solo tenemos que registar las líneas que han sido registradas en el albarán
        rSalesShptLine.reset();
        rSalesShptLine.SetRange(Type, rSalesShptLine.Type::Item);
        rSalesShptLine.SetRange("Document No.", SalesShipmentHeader."No.");
        rSalesShptLine.SetFilter("Quantity (Base)", '<>0');
        if rSalesShptLine.Find('-') then
            repeat
                dCdadAlb := rSalesShptLine."Quantity (Base)";
                rContSetup.Get();
                if rContSetup."Comprobación pallets/cajas" then begin
                    rContCont.reset();
                    rContCont.SetRange(PedVenta, rSalesShptLine."Order No.");
                    rContCont.SetRange(LinPedVenta, rSalesShptLine."Order Line No.");
                    rContCont.SetRange("Nº producto", rSalesShptLine."No.");
                    if rContCont.find('-') then begin
                        repeat
                            if rContCont."Nº albarán venta" = '' then begin
                                rContCont.Validate("Nº albarán venta", SalesShipmentHeader."No.");
                                rContCont.Validate(Vendido, true);
                                rContCont.Modify(true);
                                dCdadAlb -= rContCont.Cantidad;
                            end;
                        until (rContCont.Next() = 0) or (dCdadAlb <= 0);
                    end;
                end;
            until rSalesShptLine.Next() = 0;

        //Tenemos que modificar las lineas que hemos abonado eliminando el pedido venta, linea, albaran y dejando vendido a false
        rSalesCrMemoLine.Reset();
        rSalesCrMemoLine.SetRange(Type, rSalesCrMemoLine.Type::Item);
        rSalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if rSalesCrMemoLine.FindSet() then
            repeat

                rContCont.reset();
                rContCont.SetRange("Nº abono venta", SalesHeader."No.");
                rContCont.SetRange("Nº linea abono venta", rSalesCrMemoLine."Line No.");
                rContCont.SetRange("Nº producto", rSalesCrMemoLine."No.");
                if rContCont.FindSet() then
                    repeat
                        rContCont.Validate(Pedventa, '');
                        rContCont.Validate(LinPedVenta, 0);
                        rContCont.Validate("Nº albarán venta", '');
                        rContCont.Validate(Vendido, false);
                        rContCont.Validate("Nº abono venta", SalesCrMemoHeader."No.");
                        rContCont.Validate("Nº linea abono venta", rSalesCrMemoLine."Line No.");
                        rContCont.Modify(true);
                    until rContCont.Next() = 0;

            until rSalesCrMemoLine.Next() = 0;

        /*
        //bProd := false;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                rContSetup.Get();
                if rContSetup."Comprobación pallets/cajas" then begin
                    rContCont.reset();
                    rContCont.SetRange(PedVenta, SalesLine."Document No.");
                    rContCont.SetRange(LinPedVenta, SalesLine."Line No.");
                    rContCont.SetRange("Nº producto", SalesLine."No.");
                    if rContCont.find('-') then begin                    
                        repeat
                            if rContCont."Nº albarán venta" = '' then begin
                                rContCont.Validate("Nº albarán venta", SalesShipmentHeader."No.");
                                rContCont.Validate(Vendido, true);
                                rContCont.Modify(true);
                            end;
                        until rContCont.Next() = 0;
                    end;
                end;
            until SalesLine.Next() = 0;
        */
    end;

    /*procedure VerificarCdadContPed(cCodNo: code[20]; cDocNo: code[20]; cLin: Integer; cProd: code[20]) dCantCont: Decimal
    var
        rContCont: Record "Contenido contenedor";
    begin
        dCantCont := 0;
        rContCont.reset;
        rContCont.SetRange("Código", cCodNo);
        rContCont.SetRange(PedVenta, cDocNo);
        rContCont.SetRange(LinPedVenta, cLin);
        rContCont.SetRange("Nº producto", cProd);
        if rContCont.Find('-') then begin
            if rContCont.CalcSums(Cantidad) then
                dCantCont := rContCont.Cantidad;
        end;
    end;

    procedure VerificarCdadContPalPed(cCodNo: code[20]; cDocNo: code[20]; cLin: Integer; cProd: code[20]) dCantCont: Decimal
    var
        rContCont: Record "Contenido contenedor";
    begin
        dCantCont := 0;
        rContCont.reset;
        rContCont.SetRange(Padre, cCodNo);
        rContCont.SetRange(PedVenta, cDocNo);
        rContCont.SetRange(LinPedVenta, cLin);
        rContCont.SetRange("Nº producto", cProd);
        if rContCont.Find('-') then begin
            if rContCont.CalcSums(Cantidad) then
                dCantCont := rContCont.Cantidad;
        end;
    end;*/

    //Ped Transferencia 

    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransferOrderPostShipment', '', false, false)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransLineModify', '', false, false)]
    //procedure ValidAlmRegPedTransfEnv(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header"; InvtPickPutaway: Boolean; CommitIsSuppressed: Boolean)
    procedure ValidAlmRegPedTransfEnv(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        rContSetup: Record "Containers Setup";
        rContCont, rcontenido : Record "Contenido contenedor";
        rTransferLine: Record "Transfer Line";
        rContenedor, rContenedor2, rContenedor3, rContenedor4 : Record Contenedores;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        cPadre, cCaja, cPalet : Code[20];
        bProd: Boolean;
        rLocation: Record Location;
        dCantCont, dCantContPal : Decimal;
    begin
        //cCaja := '';
        cPalet := '';
        //bProd := false;
        dCantContPal := 0;
        dCantCont := 0;
        rContSetup.Get();
        if rContSetup."Comprobación pallets/cajas" then begin
            rContCont.reset();
            rContCont.SetCurrentKey(Padre);
            rContCont.SetRange(PedTrans, TransferLine."Document No.");
            rContCont.SetRange(LinPedTrans, TransferLine."Line No.");
            rContCont.SetRange("Nº producto", TransferLine."Item No.");
            //rContCont.SetRange("Cód. Almacén", TransferLine."Transfer-from Code");
            if rContCont.FindSet() then begin
                rProdUdMedPal.Get(rContCont."Nº producto", rContSetup."Ud. medida Pallet");
                rProdUdMedCaja.Get(rContCont."Nº producto", rContSetup."Ud. medida. Caja");
                repeat
                    rContenedor.Get(rContCont."Código");
                    if rContenedor4.Get(rContenedor.Padre) then begin
                        if (rContSetup."Tipo pallet" = rContenedor4.Tipo) and (cPalet = '') or (cPalet <> rContenedor4."Código") then begin
                            dCantContPal := VerificarCdadContPalTransf(rContenedor4."Código", TransferLine."Document No.", TransferLine."Line No.", TransferLine."Item No.");
                            cPalet := rContenedor4."Código";
                        end;
                        if dCantContPal = rProdUdMedPal."Qty. per Unit of Measure" then begin
                            rContenedor3.Get(rContCont."Código");
                            rContenedor2.Get(rContenedor3.Padre);
                            if rContenedor2."Almacén" <> TransferLine."In-Transit Code" then begin
                                rContenedor2.Validate("Almacén", TransferLine."In-Transit Code");
                                rContenedor2.Modify(true);
                                rContenedor3.Reset();
                                rContenedor3.SetRange(Padre, rContenedor2."Código");
                                if rContenedor3.FindSet() then
                                    repeat
                                        rContenedor3.Validate("Almacén", TransferLine."In-Transit Code");
                                        rContenedor3.Modify(true);
                                    until rContenedor3.Next() = 0;
                            end;
                        end
                    end;
                    if dCantContPal < rProdUdMedPal."Qty. per Unit of Measure" then begin
                        dCantCont := VerificarCdadContTransf(rContCont."Código", TransferLine."Document No.", TransferLine."Line No.", TransferLine."Item No.");
                        //cCaja := rContCont."Código";
                        rlocation.get(TransferLine."In-Transit Code");
                        rlocation.TestField(rLocation."Contenedor devoluciones");
                        if dCantCont = rProdUdMedCaja."Qty. per Unit of Measure" then begin
                            cPadre := '';
                            rContenedor.Get(rContCont."Código");
                            rContenedor.Validate(Padre, cPadre);
                            rContenedor.Validate("Almacén", TransferLine."In-Transit Code");
                            rContenedor.Modify(true);
                        end else
                            if dCantCont < rProdUdMedCaja."Qty. per Unit of Measure" then begin
                                rcontenido.Copy(rContCont);
                                rcontenido.Rename(rLocation."Contenedor devoluciones", rContCont."Nº producto", rContCont.IMEI);
                            end;
                    end;
                until rContCont.Next() = 0;
            end;
        end;
    end;

    procedure VerificarCdadContTransf(cCodNo: code[20]; cDocNo: code[20]; cLin: Integer; cProd: code[20]) dCantCont: Decimal
    var
        rContCont: Record "Contenido contenedor";
    begin
        dCantCont := 0;
        rContCont.reset;
        rContCont.SetRange("Código", cCodNo);
        rContCont.SetRange(PedTrans, cDocNo);
        rContCont.SetRange(LinPedTrans, cLin);
        rContCont.SetRange("Nº producto", cProd);
        //rContCont.SetRange("Cód. Almacén", cAlm);
        if rContCont.Find('-') then begin
            if rContCont.CalcSums(Cantidad) then
                dCantCont := rContCont.Cantidad;
        end;
    end;

    procedure VerificarCdadContPalTransf(cCodNo: code[20]; cDocNo: code[20]; cLin: Integer; cProd: code[20]) dCantCont: Decimal
    var
        rContCont: Record "Contenido contenedor";
    begin
        dCantCont := 0;
        rContCont.reset;
        rContCont.SetRange(Padre, cCodNo);
        rContCont.SetRange(PedTrans, cDocNo);
        rContCont.SetRange(LinPedTrans, cLin);
        rContCont.SetRange("Nº producto", cProd);
        //rContCont.SetRange("Cód. Almacén", cAlm);
        if rContCont.Find('-') then begin
            if rContCont.CalcSums(Cantidad) then
                dCantCont := rContCont.Cantidad;
        end;
    end;

    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterTransferOrderPostReceipt', '', false, false)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterTransLineUpdateQtyReceived', '', false, false)]
    procedure ValidAlmRegPedTransfRecep(CommitIsSuppressed: Boolean; var TransferLine: Record "Transfer Line")
    //procedure ValidAlmRegPedTransfRecep(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        rContSetup: Record "Containers Setup";
        rContCont, rContenido : Record "Contenido contenedor";
        rContenedor, rContenedor3, rContenedor2, rContenedor4 : Record Contenedores;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        cPadre, cCaja, cPalet : Code[20];
        dCantContPal, dCantCont : Decimal;
        rLocation: Record Location;
    begin
        //cCaja := '';
        cPalet := '';
        dCantContPal := 0;
        rContSetup.Get();
        if rContSetup."Comprobación pallets/cajas" then begin
            rContCont.reset();
            rContCont.SetCurrentKey(Padre);
            rContCont.SetRange(PedTrans, TransferLine."Document No.");
            rContCont.SetRange(LinPedTrans, TransferLine."Line No.");
            rContCont.SetRange("Nº producto", TransferLine."Item No.");
            //rContCont.SetRange("Cód. Almacén", TransferLine."Transfer-from Code");
            //rContCont.SetRange("Cód. Almacén", TransferLine."In-Transit Code");
            if rContCont.find('-') then begin
                rProdUdMedPal.Get(rContCont."Nº producto", rContSetup."Ud. medida Pallet");
                rProdUdMedCaja.Get(rContCont."Nº producto", rContSetup."Ud. medida. Caja");
                repeat
                    rContenedor.Get(rContCont."Código");
                    if (rContenedor4.Get(rContenedor.Padre)) and (rContenedor.padre <> '') then begin
                        if rContenedor4."Almacén" <> TransferLine."Transfer-to Code" then begin
                            if (rContSetup."Tipo pallet" = rContenedor4.Tipo) and (cPalet = '') or (cPalet <> rContenedor4."Código") then begin
                                dCantContPal := VerificarCdadContPalTransf(rContenedor4."Código", TransferLine."Document No.", TransferLine."Line No.", TransferLine."Item No.");
                                cPalet := rContenedor4."Código";
                            end;
                            if dCantContPal = rProdUdMedPal."Qty. per Unit of Measure" then begin
                                rContenedor3.Get(rContCont."Código");
                                if rContenedor.Get(rContenedor3.Padre) then begin
                                    rContenedor.Validate("Almacén", TransferLine."Transfer-to Code");
                                    rContenedor.Modify(true);
                                    rContenedor3.Reset();
                                    rContenedor3.SetRange(Padre, rContenedor."Código");
                                    if rContenedor3.FindSet() then
                                        repeat
                                            rContenedor3.Validate("Almacén", TransferLine."Transfer-to Code");
                                            rContenedor3.Modify(true);
                                        until rContenedor3.Next() = 0;
                                end;
                            end
                        end;
                    end;
                    if dCantContPal < rProdUdMedPal."Qty. per Unit of Measure" then begin
                        dCantCont := VerificarCdadContTransf(rContCont."Código", TransferLine."Document No.", TransferLine."Line No.", TransferLine."Item No.");
                        if dCantCont = rProdUdMedCaja."Qty. per Unit of Measure" then begin
                            cPadre := '';
                            rContenedor.Get(rContCont."Código");
                            rContenedor.Validate(Padre, cPadre);
                            rContenedor.Validate("Almacén", TransferLine."Transfer-to Code");
                            rContenedor.Modify(true);
                        end else
                            if dCantCont < rProdUdMedCaja."Qty. per Unit of Measure" then begin
                                rLocation.get(TransferLine."Transfer-to Code");
                                rLocation.TestField("Contenedor devoluciones");
                                rContenido.get(rContCont."Código", rContCont."Nº producto", rContCont.IMEI);
                                rContenido.Rename(rLocation."Contenedor devoluciones", rContCont."Nº producto", rContCont.IMEI);
                                rContenedor.Validate(Padre, cPadre);
                                rContenedor.Validate("Almacén", TransferLine."Transfer-to Code");
                                rContenedor.Modify(true);
                            end;
                    end;
                /*
                if rContenedor."Almacén" <> TransferLine."Transfer-to Code" then
                    if dCantContPal < rProdUdMedPal."Qty. per Unit of Measure" then begin
                        dCantCont := VerificarCdadContTransf(rContCont."Código", TransferLine."Document No.", TransferLine."Line No.", TransferLine."Item No.");
                        //cCaja := rContCont."Código";
                        if (dCantContPal < rProdUdMedPal."Qty. per Unit of Measure") and (dCantCont = rProdUdMedCaja."Qty. per Unit of Measure") then begin
                            rContenedor2.Get(rContCont."Código");
                            rContenedor2.Validate("Almacén", TransferLine."Transfer-to Code");
                            rContenedor2.Modify(true);
                        end;
                    end;
                //rContenedor4.Get(rContCont."Código");
                //rLocation.Get(rContenedor4."Almacén");
                //rLocation.Get(TransferLine."Transfer-from Code");
                //rContCont.Validate("Cód. Almacén", TransferLine."Transfer-to Code");
                if not rLocation."Require Receive" then begin
                    rContCont.Validate(PedTrans, '');
                    rContCont.Validate(LinPedTrans, 0);
                    rContCont.Modify(true);
                end;
                */
                //rContCont.Modify(true);
                until rContCont.Next() = 0;
            end;
        end;
    end;

    //Comprobar antes de registrar en casa de que el producto en las líneas tenga gestión de contenedores que tenga contenedor asignado
    //Pedidos venta

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnBeforeConfirmSalesPost', '', false, false)]
    procedure ComprobContPedVenta(var SalesHeader: Record "Sales Header"; var PostAndSend: Boolean; var DefaultOption: Integer; var HideDialog: Boolean; var IsHandled: Boolean)
    var
        rSalesLine: Record "Sales Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rContenedor: Record Contenedores;
        dCant: Decimal;
    begin
        dCant := 0;
        rSalesLine.Reset();
        rSalesLine.SetRange("Document Type", rSalesLine."Document Type"::Order);
        rSalesLine.SetRange(Type, rSalesLine.Type::Item);
        rSalesLine.SetRange("Document No.", SalesHeader."No.");
        rSalesLine.SetFilter("Qty. to Ship", '<>%1', 0);
        if rSalesLine.FindSet() then
            repeat
                rProd.Get(rSalesLine."No.");
                if rProd."Gestión de contenedores" then begin
                    dcant := 0;
                    rContCont.reset();
                    rContCont.SetRange(PedVenta, rSalesLine."Document No.");
                    rContCont.SetRange(LinPedVenta, rSalesLine."Line No.");
                    rContCont.SetRange("Nº producto", rSalesLine."No.");
                    //rContCont.SetRange("Cód. Almacén", rSalesLine."Location Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if (dCant <> rSalesLine."Qty. to Ship (Base)") or (dCant <> rSalesLine."Qty. to Ship (Base)" + rSalesLine."Qty. Shipped (Base)") then
                        if dCant <> rSalesLine."Qty. to Ship (Base)" + rSalesLine."Qty. Shipped (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rSalesLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post and Send", 'OnBeforePostAndSend', '', false, false)]
    procedure ComprobContPedVentaEnv(var SalesHeader: Record "Sales Header"; var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var HideDialog: Boolean)
    var
        rSalesLine: Record "Sales Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        dCant: Decimal;
    begin
        dCant := 0;
        rSalesLine.Reset();
        rSalesLine.SetRange("Document Type", rSalesLine."Document Type"::Order);
        rSalesLine.SetRange(Type, rSalesLine.Type::Item);
        rSalesLine.SetRange("Document No.", SalesHeader."No.");
        rSalesLine.SetFilter("Qty. to Ship", '<>%1', 0);
        if rSalesLine.FindSet() then
            repeat
                rProd.Get(rSalesLine."No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange(PedVenta, rSalesLine."Document No.");
                    rContCont.SetRange(LinPedVenta, rSalesLine."Line No.");
                    rContCont.SetRange("Nº producto", rSalesLine."No.");
                    //rContCont.SetRange("Cód. Almacén", rSalesLine."Location Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rSalesLine."Qty. to Ship (Base)" then
                        if dCant <> rSalesLine."Qty. to Ship (Base)" + rSalesLine."Qty. Shipped (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rSalesLine.Next() = 0;
    end;

    //Pedidos transferencia

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post (Yes/No)", 'OnBeforePost', '', false, false)]
    procedure ComprobContPedTransf(var TransHeader: Record "Transfer Header"; var TransferOrderPost: Enum "Transfer Order Post"; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt"; var IsHandled: Boolean; var PostBatch: Boolean)
    var
        rTransferLine: Record "Transfer Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rContenedor: Record Contenedores;
        dCant: Decimal;
    begin
        dCant := 0;
        rTransferLine.Reset();
        rTransferLine.SetRange("Document No.", TransHeader."No.");
        rTransferLine.SetFilter("Qty. to Ship", '<>%1', 0);
        rTransferLine.SetRange("Derived From Line No.", 0);
        if rTransferLine.FindSet() then
            repeat
                rProd.Get(rTransferLine."Item No.");
                if (rProd."Gestión de contenedores") and (rTransferLine.Quantity <> rTransferLine."Quantity Shipped") then begin
                    rContCont.reset();
                    rContCont.SetRange(PedTrans, rTransferLine."Document No.");
                    rContCont.SetRange(LinPedTrans, rTransferLine."Line No.");
                    rContCont.SetRange("Nº producto", rTransferLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rTransferLine."Transfer-from Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rTransferLine."Qty. to Ship (Base)" then
                        if dCant <> rTransferLine."Qty. to Ship (Base)" + rTransferLine."Qty. Shipped (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rTransferLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post + Print", 'OnBeforePost', '', false, false)]
    procedure ComprobContPedTransfEnv(var TransHeader: Record "Transfer Header"; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt"; var IsHandled: Boolean)
    var
        rTransferLine: Record "Transfer Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        dCant: Decimal;
    begin
        dCant := 0;
        rTransferLine.Reset();
        rTransferLine.SetRange("Document No.", TransHeader."No.");
        rTransferLine.SetFilter("Qty. to Ship", '<>%1', 0);
        rTransferLine.SetRange("Derived From Line No.", 0);
        if rTransferLine.FindSet() then
            repeat
                rProd.Get(rTransferLine."Item No.");
                if (rProd."Gestión de contenedores") and (rTransferLine.Quantity <> rTransferLine."Quantity Shipped") then begin
                    rContCont.reset();
                    rContCont.SetRange(PedTrans, rTransferLine."Document No.");
                    rContCont.SetRange(LinPedTrans, rTransferLine."Line No.");
                    rContCont.SetRange("Nº producto", rTransferLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rTransferLine."Transfer-from Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rTransferLine."Qty. to Ship (Base)" then
                        if dCant <> rTransferLine."Qty. to Ship (Base)" + rTransferLine."Qty. Shipped (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rTransferLine.Next() = 0;
    end;

    //Recepción almacén

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt (Yes/No)", 'OnBeforeConfirmWhseReceiptPost', '', false, false)]
    procedure ComprobContRecep(var WhseReceiptLine: Record "Warehouse Receipt Line"; var HideDialog: Boolean; var IsPosted: Boolean)
    var
        rWarehouseReceiptLine: Record "Warehouse Receipt Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rContenedor: Record Contenedores;
        rTransHeader: Record "Transfer Header";
        dCant: Decimal;
    begin
        dCant := 0;
        rTransHeader.Get(WhseReceiptLine."Source No.");
        rWarehouseReceiptLine.Reset();
        rWarehouseReceiptLine.SetRange("No.", WhseReceiptLine."No.");
        rWarehouseReceiptLine.SetFilter("Qty. to Receive", '<>%1', 0);
        if rWarehouseReceiptLine.FindSet() then
            repeat
                rProd.Get(rWarehouseReceiptLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange(RecepAlm, rWarehouseReceiptLine."No.");
                    rContCont.SetRange(LinRecep, rWarehouseReceiptLine."Line No.");
                    rContCont.SetRange("Nº producto", rWarehouseReceiptLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rTransHeader."In-Transit Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rWarehouseReceiptLine."Qty. to Receive (Base)" then
                        if dCant <> rWarehouseReceiptLine."Qty. to Receive (Base)" + rWarehouseReceiptLine."Qty. Received (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rWarehouseReceiptLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt + Pr. Pos.", 'OnBeforeCode', '', false, false)]
    procedure ComprobContRecepImpr(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    var
        rWarehouseReceiptLine: Record "Warehouse Receipt Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rTransHeader: Record "Transfer Header";
        dCant: Decimal;
    begin
        dCant := 0;
        rTransHeader.Get(WarehouseReceiptLine."Source No.");
        rWarehouseReceiptLine.Reset();
        rWarehouseReceiptLine.SetRange("No.", WarehouseReceiptLine."No.");
        rWarehouseReceiptLine.SetFilter("Qty. to Receive", '<>%1', 0);
        if rWarehouseReceiptLine.FindSet() then
            repeat
                rProd.Get(rWarehouseReceiptLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange(RecepAlm, rWarehouseReceiptLine."No.");
                    rContCont.SetRange(LinRecep, rWarehouseReceiptLine."Line No.");
                    rContCont.SetRange("Nº producto", rWarehouseReceiptLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rTransHeader."In-Transit Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rWarehouseReceiptLine."Qty. to Receive (Base)" then
                        if dCant <> rWarehouseReceiptLine."Qty. to Receive (Base)" + rWarehouseReceiptLine."Qty. Received (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rWarehouseReceiptLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt + Print", 'OnBeforeCode', '', false, false)]
    procedure ComprobContRecepUbic(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    var
        rWarehouseReceiptLine: Record "Warehouse Receipt Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rTransHeader: Record "Transfer Header";
        dCant: Integer;
    begin
        dCant := 0;
        rTransHeader.Get(WhseReceiptLine."Source No.");
        rWarehouseReceiptLine.Reset();
        rWarehouseReceiptLine.SetRange("No.", WhseReceiptLine."No.");
        rWarehouseReceiptLine.SetFilter("Qty. to Receive", '<>%1', 0);
        if rWarehouseReceiptLine.FindSet() then
            repeat
                rProd.Get(rWarehouseReceiptLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange(RecepAlm, rWarehouseReceiptLine."No.");
                    rContCont.SetRange(LinRecep, rWarehouseReceiptLine."Line No.");
                    rContCont.SetRange("Nº producto", rWarehouseReceiptLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rTransHeader."In-Transit Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rWarehouseReceiptLine."Qty. to Receive (Base)" then
                        if dCant <> rWarehouseReceiptLine."Qty. to Receive (Base)" + rWarehouseReceiptLine."Qty. Received (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rWarehouseReceiptLine.Next() = 0;
    end;

    //Envío almacén

    //OnBeforeRun(Rec, SuppressCommit, PreviewMode);
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforeRun', '', false, false)]
    procedure ComprobaContEnvio1(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SuppressCommit: Boolean; PreviewMode: Boolean)
    var
        bBool: Boolean;
        iSel: Integer;
    begin
        bBool := false;
        iSel := 0;
        ComprobContEnvio(WarehouseShipmentLine, bBool, bBool, bbool, iSel);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", 'OnBeforeConfirmWhseShipmentPost', '', false, false)]
    procedure ComprobContEnvio(var WhseShptLine: Record "Warehouse Shipment Line"; var HideDialog: Boolean; var Invoice: Boolean; var IsPosted: Boolean; var Selection: Integer)
    var
        rWhseShptLine: Record "Warehouse Shipment Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rContenedor: Record Contenedores;
        dCant, dCantEnv : Decimal;
        rLinVenta: record "Sales Line";
        rlinTrasn: Record "Transfer Line";
    begin
        dCant := 0;
        rWhseShptLine.Reset();
        rWhseShptLine.SetRange("No.", WhseShptLine."No.");
        rWhseShptLine.SetFilter("Qty. to Ship", '<>%1', 0);
        if rWhseShptLine.FindSet() then
            repeat
                dCant := 0;
                rProd.Get(rWhseShptLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    /*
                    rContCont.SetRange(EnvioAlm, rWhseShptLine."No.");
                    rContCont.SetRange(LinEnvio, rWhseShptLine."Line No.");
                    
                    rContCont.SetRange(EnvioAlm, rWhseShptLine."Source No.");
                    rContCont.SetRange(LinEnvio, rWhseShptLine."Source Line No.");
                    
                    rContCont.SetRange(PedVenta, rWhseShptLine."Source No.");
                    rContCont.SetRange(LinPedVenta, rWhseShptLine."Source Line No.");
                    */
                    rContCont.SetRange("Nº producto", rWhseShptLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rWhseShptLine."Location Code");
                    case rWhseShptLine."Source Type" of
                        37:
                            begin
                                rContCont.SetRange(PedVenta, rWhseShptLine."Source No.");
                                rContCont.SetRange(LinPedVenta, rWhseShptLine."Source Line No.");
                                rlinventa.get(rlinventa."Document Type"::Order, rWhseShptLine."Source No.", rWhseShptLine."Source Line No.");
                                dCantEnv := rLinVenta."Qty. Shipped (Base)";
                            end;
                        5741:
                            begin
                                rContCont.SetRange(PedTrans, rWhseShptLine."Source No.");
                                rContCont.SetRange(LinPedTrans, rWhseShptLine."Source Line No.");
                                rlinTrasn.get(rWhseShptLine."Source No.", rWhseShptLine."Source Line No.");
                                dCantEnv := rlinTrasn."Qty. Shipped (Base)";
                            end;
                    end;
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rWhseShptLine."Qty. to Ship (Base)" then
                        if dCant <> rWhseShptLine."Qty. to Ship (Base)" + dCantEnv then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rWhseShptLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment + Print", 'OnBeforeCode', '', false, false)]
    procedure ComprobContEnvioImpr(var WhseShptLine: Record "Warehouse Shipment Line"; var HideDialog: Boolean; var Invoice: Boolean; var IsPosted: Boolean; var Selection: Integer)
    var
        rWhseShptLine: Record "Warehouse Shipment Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        dCant: Decimal;
    begin
        dCant := 0;
        rWhseShptLine.Reset();
        rWhseShptLine.SetRange("No.", WhseShptLine."No.");
        rWhseShptLine.SetFilter("Qty. to Ship", '<>%1', 0);
        if rWhseShptLine.FindSet() then
            repeat
                rProd.Get(rWhseShptLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    //rContCont.SetRange(EnvioAlm, rWhseShptLine."No.");
                    //rContCont.SetRange(LinEnvio, rWhseShptLine."Line No.");
                    rContCont.SetRange(EnvioAlm, rWhseShptLine."Source No.");
                    rContCont.SetRange(LinEnvio, rWhseShptLine."Source Line No.");
                    /*
                    rContCont.SetRange(PedVenta, rWhseShptLine."Source No.");
                    rContCont.SetRange(LinPedVenta, rWhseShptLine."Source Line No.");
                    */
                    rContCont.SetRange("Nº producto", rWhseShptLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rWhseShptLine."Location Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        //if dCant <> rWhseShptLine."Qty. to Ship (Base)" then
                        if dCant <> rWhseShptLine."Qty. to Ship (Base)" + rWhseShptLine."Qty. Shipped (Base)" then
                            Error(lError002, rProd."No.");
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rWhseShptLine.Next() = 0;
    end;

    //Diario de productos

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", 'OnBeforeCode', '', false, false)]
    procedure ComprobContDiarioProd(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var IsHandled: Boolean; var SuppressCommit: Boolean)
    var
        rItemJournalLine: Record "Item Journal Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rContenedor: Record Contenedores;
        dCant: Decimal;
    begin

        if not bAnularGlobal then begin

            dCant := 0;
            rItemJournalLine.Reset();
            rItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
            rItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
            if rItemJournalLine.FindSet() then
                repeat
                    rProd.Get(rItemJournalLine."Item No.");
                    if rProd."Gestión de contenedores" then begin
                        rContCont.reset();
                        rContCont.SetRange("Libro registro productos", rItemJournalLine."Journal Template Name");
                        rContCont.SetRange("Sección registro productos", rItemJournalLine."Journal Batch Name");
                        rContCont.SetRange(LinDiario, ItemJournalLine."Line No.");
                        rContCont.SetRange("Nº producto", rItemJournalLine."Item No.");
                        //rContCont.SetRange("Cód. Almacén", rItemJournalLine."Location Code");                    
                        if rContCont.findset then begin
                            repeat
                                dCant += rContCont.Cantidad;
                            until rContCont.Next() = 0;
                            if dCant <> rItemJournalLine.Quantity then
                                Error(lError002, rProd."No.");
                            ProcesarLinDiario(ItemJournalLine, rContCont);
                        end else
                            Error(lError001, rProd."No.");
                    end;
                until rItemJournalLine.Next() = 0;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post+Print", 'OnBeforePostJournalBatch', '', false, false)]
    procedure ComprobContDiarioProdImpr(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var IsHandled: Boolean; var SuppressCommit: Boolean)
    var
        rItemJournalLine: Record "Item Journal Line";
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        dCant: Decimal;
    begin
        dCant := 0;
        rItemJournalLine.Reset();
        rItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        rItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        if rItemJournalLine.FindSet() then
            repeat
                rProd.Get(rItemJournalLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange("Libro registro productos", rItemJournalLine."Journal Template Name");
                    rContCont.SetRange("Sección registro productos", rItemJournalLine."Journal Batch Name");
                    rContCont.SetRange(LinDiario, ItemJournalLine."Line No.");
                    rContCont.SetRange("Nº producto", rItemJournalLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rItemJournalLine."Location Code");
                    if rContCont.findset then begin
                        repeat
                            dCant += rContCont.Cantidad;
                        until rContCont.Next() = 0;
                        if dCant <> rItemJournalLine.Quantity then
                            Error(lError002, rProd."No.");
                        ProcesarLinDiario(ItemJournalLine, rContCont);
                    end else
                        Error(lError001, rProd."No.");
                end;
            until rItemJournalLine.Next() = 0;
    end;

    //Meter no. y línea de recepción en contenido contenedor al crear la recepción desde el ped. de transferencia 

    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", 'OnAfterCreateRcptLineFromTransLine', '', false, false)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Warehouse Mgt.", 'OnAfterCreateRcptLineFromTransLine', '', false, false)]
    procedure CrearRecepPedTransf(TransferLine: Record "Transfer Line"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rWarehouseReceiptLine: Record "Warehouse Receipt Line";
        rTransHeader: Record "Transfer Header";
    begin
        rWarehouseReceiptLine.Reset();
        rWarehouseReceiptLine.SetRange("No.", WarehouseReceiptLine."No.");
        rWarehouseReceiptLine.SetRange("Source No.", TransferLine."Document No.");
        if rWarehouseReceiptLine.FindSet() then
            repeat
                rProd.Get(rWarehouseReceiptLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange("Nº producto", rWarehouseReceiptLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", TransferLine."In-Transit Code");
                    rContCont.SetRange(PedTrans, rWarehouseReceiptLine."Source No.");
                    rContCont.SetRange(LinPedTrans, rWarehouseReceiptLine."Source Line No.");
                    if rContCont.findset then
                        repeat
                            rContCont.Validate(PedTrans, '');
                            rContCont.Validate(LinPedTrans, 0);
                            rContCont.Validate(RecepAlm, rWarehouseReceiptLine."No.");
                            rContCont.Validate(LinRecep, rWarehouseReceiptLine."Line No.");
                            rContCont.Modify(true);
                        until rContCont.Next() = 0;
                end;
            until rWarehouseReceiptLine.Next() = 0;
    end;

    //Meter no. y línea de envío en contenido contenedor al crear el envío de almacén desde el ped. de venta

    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", 'OnAfterCreateShptLineFromSalesLine', '', false, false)]
    procedure CrearEnvioPedVenta(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        rProd: Record Item;
        rContCont: Record "Contenido contenedor";
        rWarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        rWarehouseShipmentLine.Reset();
        rWarehouseShipmentLine.SetRange("No.", WarehouseShipmentLine."No.");
        if rWarehouseShipmentLine.FindSet() then
            repeat
                rProd.Get(rWarehouseShipmentLine."Item No.");
                if rProd."Gestión de contenedores" then begin
                    rContCont.reset();
                    rContCont.SetRange("Nº producto", rWarehouseShipmentLine."Item No.");
                    rContCont.SetRange("Cód. Almacén", rWarehouseShipmentLine."Location Code");
                    rContCont.SetRange(PedVenta, rWarehouseShipmentLine."Source No.");
                    rContCont.SetRange(LinPedVenta, rWarehouseShipmentLine."Source Line No.");
                    if rContCont.findset then
                        repeat
                            rContCont.Validate(PedVenta, '');
                            rContCont.Validate(LinPedVenta, 0);
                            rContCont.Validate(EnvioAlm, rWarehouseShipmentLine."No.");
                            rContCont.Validate(LinEnvio, rWarehouseShipmentLine."Line No.");
                            rContCont.Modify(true);
                        until rContCont.Next() = 0;
                end;
            until rWarehouseShipmentLine.Next() = 0;
    end;*/


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnAfterNewSalesShptLineInsert', '', false, false)]
    procedure DeshacerPedVenta(var NewSalesShipmentLine: Record "Sales Shipment Line"; OldSalesShipmentLine: Record "Sales Shipment Line")
    var
        rContCont: Record "Contenido contenedor";
    begin
        rContCont.reset;
        //rContCont.SetRange(PedVenta, NewSalesShipmentLine."Order No.");
        //rContCont.SetRange(LinPedVenta, NewSalesShipmentLine."Order Line No.");
        rContCont.SetRange("Nº albarán venta", NewSalesShipmentLine."Document No.");
        rContCont.SetRange("Nº producto", NewSalesShipmentLine."No.");
        if rContCont.FindSet() then
            repeat
                rContCont.Validate("Nº albarán venta", '');
                rContCont.Validate(Vendido, false);
                rContCont.Modify(true);
            until rContCont.Next() = 0;
    end;

    //Al registrar manualmente la línea del diario borramos el nombre y la sección del diario del contenido, dependiendo de la cantidad lo sacamos del contenedor padre(si sacamos cajas sueltas) o lo
    // metemos en el contenedor de devoluciones si estamos cogiendo del contenedor por producto 

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Batch", 'OnAfterPostLines', '', false, false)]
    procedure ValidContenidoContDiario(var ItemJournalLine: Record "Item Journal Line")
    var
        rContSetup: Record "Containers Setup";
        rContCont, rcontenido : Record "Contenido contenedor";
        rTipoCont: Record "Tipo contenedor";
        rContenedor: Record Contenedores;
        rItemJournalLine: Record "Item Journal Line";
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        cPadre: Code[20];
        bPadre, bProd : Boolean;
        rLocation: Record Location;
        dCant: Decimal;
    begin
        rItemJournalLine.DeleteAll();
        rItemJournalLine.Reset();
        rItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        rItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        if rItemJournalLine.FindSet() then
            repeat
                bPadre := false;
                bProd := false;
                rContSetup.Get();
                if rContSetup."Comprobación pallets/cajas" then begin
                    rContCont.reset();
                    rContCont.SetRange("Libro registro productos", rItemJournalLine."Journal Template Name");
                    rContCont.SetRange("Sección registro productos", rItemJournalLine."Journal Batch Name");
                    rContCont.SetRange(LinDiario, ItemJournalLine."Line No.");
                    rContCont.SetRange("Nº producto", rItemJournalLine."Item No.");
                    //rContCont.SetRange("Cód. Almacén", rItemJournalLine."Location Code");
                    if rContCont.findset then begin
                        if rContCont.CalcSums(Cantidad) then
                            dCant := rContCont.Cantidad;
                    end;
                    if rContCont.FindSet() then begin
                        rProdUdMedPal.Get(rContCont."Nº producto", rContSetup."Ud. medida Pallet");
                        rProdUdMedCaja.Get(rContCont."Nº producto", rContSetup."Ud. medida. Caja");
                        if (dCant < rProdUdMedPal."Qty. per Unit of Measure") and (dCant >= rProdUdMedCaja."Qty. per Unit of Measure") then begin
                            cPadre := '';
                            bPadre := true;
                        end else
                            if dCant < rProdUdMedCaja."Qty. per Unit of Measure" then begin
                                bProd := true;
                            end;
                        repeat
                            rContenedor.Get(rContCont."Código");
                            rContCont.Validate("Libro registro productos", '');
                            rContCont.Validate("Sección registro productos", '');
                            rContCont.Validate(LinDiario, 0);
                            rContCont.Modify(true);
                            if bPadre then begin
                                rContenedor.Validate(Padre, cPadre);
                                rContenedor.Modify(true);
                            end;
                            if bProd then begin
                                rLocation.Get(rContenedor."Almacén");
                                rlocation.TestField(rLocation."Contenedor devoluciones");
                                rcontenido.Copy(rContCont);
                                rcontenido.Rename(rLocation."Contenedor devoluciones", rContCont."Nº producto", rContCont.IMEI);
                            end;
                        until rContCont.Next() = 0;
                    end;
                end;
            until rItemJournalLine.Next() = 0;
    end;

    //Suscripciones de eliminación de datos para eliminar asignación de contendores (lin. venta, lin. trans., diario)
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnAfterDeleteEvent, '', false, false)]
    local procedure AlEliminarLinVenta(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        rCC: Record "Contenido contenedor";
    begin
        if rec.IsTemporary then exit;
        if rec.Type <> rec.Type::Item then exit;
        if (Rec."Document Type" <> rec."Document Type"::Order) and (Rec."Document Type" <> rec."Document Type"::"Return Order") then exit;
        if rec."Completely Shipped" then exit;
        rcc.reset;
        rcc.setrange(PedVenta, Rec."Document No.");
        rcc.SetRange(LinPedVenta, rec."Line No.");
        rcc.SetRange("Nº producto", rec."No.");
        rcc.SetRange(vendido, false);
        if rcc.Find('-') then
            repeat
                rcc.PedVenta := '';
                rcc.LinPedVenta := 0;
                rcc.Modify(true);
            until rcc.next = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterDeleteEvent, '', false, false)]
    local procedure AlEliminarLinTransferencia(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    var
        rCC: Record "Contenido contenedor";
    begin
        rcc.reset;
        rcc.SetRange(PedTrans, rec."Document No.");
        rcc.SetRange(LinPedTrans, rec."Line No.");
        rcc.SetRange("Nº producto", rec."Item No.");
        if rcc.find('-') then
            repeat
                rcc.PedTrans := '';
                rcc.LinPedTrans := 0;
                rcc.Modify(true);
            until rcc.next = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", OnAfterDeleteEvent, '', false, false)]
    local procedure AlEliminarLinDiario(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    var
        rCC: record "Contenido contenedor";
    begin
        if Rec.IsTemporary then exit;
        if rec."Journal Template Name" = '' then exit;
        if rec."Journal Batch Name" = '' then exit;
        if rec."Line No." = 0 then exit;
        rcc.reset;
        rcc.SetRange("Libro registro productos", rec."Journal Template Name");
        rcc.SetRange("Sección registro productos", rec."Journal Batch Name");
        rcc.SetRange(LinDiario, rec."Line No.");
        rcc.SetRange("Nº producto", rec."Item No.");
        if rcc.Find('-') then
            repeat
                rcc."Libro registro productos" := '';
                rcc."Sección registro productos" := '';
                rcc.LinDiario := 0;
                rcc.Modify(true);
            until rcc.next = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnBeforeOnRun', '', false, false)]
    local procedure c900OnBeforeOnRun(var AssemblyHeader: Record "Assembly Header"; sender: Codeunit "Assembly-Post"; SuppressCommit: Boolean)
    var
        rItem: record Item;
        rContenidocontenedor: record "Contenido contenedor";
        rAssemblyLine: record "Assembly Line";
    begin
        //COMPROBACION DE QUE ESTAN CUBIERTOS TODOS LAS LINEAS DEL CONTENIDO CONTENEDOS CUANDO EL PRODUCTOS TIENE ACTIVADO LA GESTION DE CONTENEDORES


        rAssemblyLine.Reset();
        rAssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        rAssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        if rAssemblyLine.FindSet() then
            repeat
                rItem.Reset();
                rItem.SetRange("No.", rAssemblyLine."No.");
                rItem.SetRange("Gestión de contenedores", true);
                if rItem.FindFirst() then begin

                    rContenidocontenedor.Reset();
                    rContenidocontenedor.SetRange("Nº pedido ensamblado", AssemblyHeader."No.");
                    rContenidocontenedor.SetRange("Nº linea pedido ensamblado", rAssemblyLine."Line No.");
                    if not rContenidocontenedor.FindFirst() then
                        Error(lError004, rAssemblyLine."No.");

                end;

                if AssemblyHeader."Location Code" <> rAssemblyLine."Location Code" then
                    AssemblyHeader.TestField("Location Code", rAssemblyLine."Location Code");

            until rAssemblyLine.Next() = 0;
        //COMPROBACION DE QUE ESTAN CUBIERTOS TODOS LAS LINEAS DEL CONTENIDO CONTENEDOS CUANDO EL PRODUCTOS TIENE ACTIVADO LA GESTION DE CONTENEDORES

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnAfterPost', '', false, false)]
    local procedure c900OnAfterPost(var AssemblyHeader: Record "Assembly Header"; PostedAssemblyHeader: Record "Posted Assembly Header"; var AssemblyLine: Record "Assembly Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        rContenidocontenedor: record "Contenido contenedor";
        rContenidocontenedor2: record "Contenido contenedor";
    begin
        //MODIFICAMOS EL PRODUCTO EN LOS CONTENIDOS DE CONTENEDOR DEL PEDIDO DE ENSAMBLADO POR EL PRODUCTO FINAL GENERADO
        rContenidocontenedor.Reset();
        rContenidocontenedor.SetRange("Nº pedido ensamblado", AssemblyHeader."No.");
        if rContenidocontenedor.FindSet() then
            repeat
                rContenidocontenedor2.Reset();
                rContenidocontenedor2.SetRange("Código", rContenidocontenedor."Código");
                rContenidocontenedor2.SetRange("Nº producto", rContenidocontenedor."Nº producto");
                rContenidocontenedor2.SetRange(IMEI, rContenidocontenedor.IMEI);
                if rContenidocontenedor2.FindFirst() then begin
                    rContenidocontenedor2.Rename(rContenidocontenedor2."Código", AssemblyHeader."Item No.", rContenidocontenedor2.IMEI);
                    rContenidocontenedor2.get(rContenidocontenedor2."Código", AssemblyHeader."Item No.", rContenidocontenedor2.IMEI);
                    rContenidocontenedor2.validate("Nº pedido ensamblado", '');
                    rContenidocontenedor2.validate("Nº linea pedido ensamblado", 0);
                    rContenidocontenedor2.Modify(true);
                end;

            until rContenidocontenedor.Next() = 0;
        //MODIFICAMOS EL PRODUCTO EN LOS CONTENIDOS DE CONTENEDOR DEL PEDIDO DE ENSAMBLADO POR EL PRODUCTO FINAL GENERADO

    end;

    procedure AnularPedido(bAnularLocal: Boolean)
    var
    begin
        bAnularGlobal := bAnularLocal;
    end;

    var

        cEntorno: Codeunit "Environment Information";
        lError001: Label 'Item %1 has no container assigned to it.', comment = 'ESP="El producto %1 no tiene contenedor asignado."';
        lError002: Label 'Item %1 is not completely assigned to a container.', comment = 'ESP="El producto %1 no está totalmente asignado a un contenedor."';
        lError003: Label 'The quantity to be received is greater than the quantity available to be created in containers.', comment = 'ESP="La cantidad a recibir es superior a la cantidad disponible para crear en contenedores."';
        lError004: Label 'There are missing containers to be assigned on the lines with product %1', comment = 'ESP="Faltan contenedores por asignar en las línea con producto %1"';
}

