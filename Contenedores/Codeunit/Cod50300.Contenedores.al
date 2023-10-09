codeunit 50300 Contenedores
{
    internal procedure VerificarAsignacionContenedor(cContenedor: Code[20]; cPadre: Code[20]): Boolean
    var
        rCont, rPadre : record Contenedores;
    begin
        if (cContenedor = '') or (cpadre = '') then exit(true);
        //rcont.get(cContenedor);
        rpadre.Get(cPadre);
    end;


    //Crear contendores de manera manual

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

    //Pedidos compras, recepción almacén

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt (Yes/No)", 'OnBeforeConfirmWhseReceiptPost', '', false, false)]
    procedure ComprobCantDetallPaletRecep(var WhseReceiptLine: Record "Warehouse Receipt Line"; var HideDialog: Boolean; var IsPosted: Boolean)
    var
        rDetallPal, rDetallPalBox, rDetallPalCant, rBox, rDetallBoxCant, rBoxContCont : Record AzmHFBreakdownPallet;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        dCantPallet, dCantCaja, dCant : Decimal;
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
        if rContSetup."Comprobación pallets/cajas" then begin
            VerificaContenedor(WhseReceiptLine."Source No.", WhseReceiptLine."Qty. to Receive (Base)", WhseReceiptLine."Item No.");
            dCant := 0;
            rWhseReceiptLine.Reset();
            rWhseReceiptLine.SetRange("No.", WhseReceiptLine."No.");
            rWhseReceiptLine.SetFilter("Qty. to Receive", '<>%1', 0);
            if rWhseReceiptLine.FindSet() then
                repeat
                    dCant += rWhseReceiptLine."Qty. to Receive";
                until rWhseReceiptLine.Next() = 0;
            dCantPallet := 0;
            rDetallPal.reset();
            rDetallPal.SetRange(OrderNo, WhseReceiptLine."Source No.");
            rDetallPal.SetRange("Contenedor generado", false);
            if rDetallPal.find('-') then begin
                repeat
                    dCantPallet := 0;
                    if not rContenedor.Get(rDetallPal.PalletNo) then begin
                        dCantPallet := 0;
                        rDetallPalCant.Reset();
                        rDetallPalCant.SetRange(PalletNo, rDetallPal.PalletNo);
                        if rDetallPalCant.FindSet() then begin
                            /*repeat
                                rProdUdMedPal.Get(rDetallPalCant.ItemNo, rContSetup."Ud. medida Pallet");
                                dCantPallet += rDetallPalCant.Quantity;
                                cPalletNo := rDetallPalCant.PalletNo;
                            until rDetallPalCant.Next() = 0;*/
                            //if dCantPallet = rProdUdMedPal."Qty. per Unit of Measure" then begin
                            rProdUdMedPal.Get(rDetallPalCant.ItemNo, rContSetup."Ud. medida Pallet");
                            if rDetallPalCant.Count = rProdUdMedPal."Qty. per Unit of Measure" then begin
                                rContenedor.Init();
                                rContenedor.Validate(Tipo, rContSetup."Tipo pallet");
                                rContenedor.Validate("Código", rDetallPal.PalletNo);
                                rContenedor.Validate("Descripción");
                                rContenedor.Validate("Almacén", rDetallPal.LocationCode);
                                rContenedor.Validate(Ubicacion, rDetallPal.BinCode);
                                dCantPallet += 1;
                            end else
                                error(lErr001, rDetallPalCant.PalletNo, rDetallPalCant.Count, rProdUdMedPal."Qty. per Unit of Measure");
                            if not rContenedor.Insert(true) then
                                rContenedor.Modify(true);
                        end;
                        //COMMIT;
                        //Creamos los contenedores hijo de los pallets
                        cBoxNo := '';
                        rDetallPalBox.Reset();
                        rDetallPalBox.SetRange(PalletNo, rDetallPal.PalletNo);
                        rDetallPalBox.SetRange(OrderNo, WhseReceiptLine."Source No.");
                        if rDetallPalBox.FindSet() then
                            repeat
                                if cBoxNo <> rDetallPal.BoxNo then begin
                                    cBoxNo := rDetallPal.BoxNo;
                                    rContenedor2.Init();
                                    rContenedor2.Validate(tipo, rContSetup."Tipo caja");
                                    rContenedor2.Padre := rContenedor."Código";
                                    rContenedor2.Validate("Código", cBoxNo);
                                    if not rContenedor.Insert(true) then
                                        rContenedor.Modify(true);
                                    dCantCaja += 1;
                                end;
                            until (rDetallPalBox.Next() = 0) or (dCant = dCantCaja);
                    end;
                until (rDetallPal.Next() = 0) or (dCant = dCantPallet);
            end;
            dCantPallet := 0;
            rbox.reset;
            rbox.SetRange(OrderNo, WhseReceiptLine."Source No.");
            rbox.SetRange(PalletNo, rContenedor.Padre);
            rbox.SetRange(BoxNo, rContenedor."Código");
            if rbox.find('-') then begin
                //if not rContenedor.Get(rDetallPal.BoxNo) then begin
                repeat
                    rDetallBoxCant.Reset();
                    rDetallBoxCant.SetRange(PalletNo, rbox.PalletNo);
                    if rDetallBoxCant.FindSet() then begin
                        /*repeat
                            rProdUdMedPal.Get(rDetallBoxCant.ItemNo, rContSetup."Ud. medida Pallet");
                            dCantPallet += rDetallBoxCant.Quantity;
                            cPalletNo := rDetallBoxCant.PalletNo;
                        until rDetallBoxCant.Next() = 0;*/
                        rProdUdMedPal.Get(rDetallBoxCant.ItemNo, rContSetup."Ud. medida Pallet");
                        if rDetallBoxCant.Count = rProdUdMedPal."Qty. per Unit of Measure" then begin
                            rContenedor.Init();
                            rContenedor.Validate(Tipo, rContSetup."Tipo pallet");
                            rContenedor.Validate("Código", rDetallPal.PalletNo);
                            rContenedor.Validate("Descripción");
                            rContenedor.Validate("Descripción");
                            rContenedor.Validate("Almacén", rbox.LocationCode);
                            rContenedor.Validate(Ubicacion, rbox.BinCode);
                        end else
                            error(lErr002, rbox.BoxNo, dCantPallet, rProdUdMedCaja."Qty. per Unit of Measure");
                        if not rContenedor.Insert(true) then
                            rContenedor.Modify(true);
                    end;
                    //COMMIT;
                    //Creamos el contenido para dicho contenedor
                    rBoxContCont.Reset();
                    rBoxContCont.SetRange(PalletNo, rDetallPal.PalletNo);
                    rBoxContCont.SetRange(OrderNo, WhseReceiptLine."Source No.");
                    if rBoxContCont.FindSet() then
                        repeat
                            rContCont.reset;
                            rContCont.SetRange("Código", rContenedor."Código");
                            rContCont.SetRange("Nº producto", rbox.ItemNo);
                            rContCont.SetRange(IMEI, rbox.UnitNo);
                            if not rContCont.find('-') then begin
                                rContCont.init;
                                rContCont.Validate("Código", rContenedor."Código");
                                rContCont.Validate("Nº producto", rbox.ItemNo);
                                rContCont.Validate(Cantidad, 1);
                                rProd.get(rbox.ItemNo);
                                rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                                rContCont.Validate(IMEI, rbox.UnitNo);
                                rContCont.Validate(Caducidad, rbox."Expiration Date");
                                rcontcont.Insert();
                                rbox."Contenedor generado" := true;
                                rbox.Modify();
                                dCantCaja += 1;
                                //COMMIT;
                            end;
                        until (rBoxContCont.Next() = 0) or (dCant = dCantCaja);
                until (rBox.Next() = 0) or (dCant = dCantPallet);
                //end;
            end
        end;
    end;

    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnAfterConfirmPost', '', false, false)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    procedure ComprobCantDetallPaletReg(var PurchaseHeader: Record "Purchase Header")
    var
        rDetallPal, rDetallPalBox, rDetallPalCant, rBox, rDetallBoxCant, rBoxContCont : Record AzmHFBreakdownPallet;
        rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        dCantPallet, dCant, dCantCaja : Decimal;
        cPalletNo, cBoxNo, cDetPallet : Code[20];
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units maccording to the corresponding unit of measure number.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        rPurchaseLine: Record "Purchase Line";
        rContenedor, rContenedor2 : Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
    begin
        //Buscamos el registro (si es pallet verificamos su cantidad y agregamos sus contenedores hijos, CAJAS)
        //Si lo que introducimos es un código de caja, verificamos la cantidad y metemos el contenido dentro del contenedor
        if (PurchaseHeader.Receive) and (PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order) then begin
            rContSetup.Get();
            if rContSetup."Comprobación pallets/cajas" then begin
                VerificarCdadContenedor(PurchaseHeader."No.");
                dCant := 0;
                rPurchaseLine.Reset();
                rPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                rPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                rPurchaseLine.SetFilter("Qty. to Receive", '<>%1', 0);
                if rPurchaseLine.FindSet() then
                    repeat
                        dCant += rPurchaseLine."Qty. to Receive";
                    until rPurchaseLine.Next() = 0;
                dCantPallet := 0;
                rDetallPal.reset();
                rDetallPal.SetRange(OrderNo, PurchaseHeader."No.");
                rDetallPal.SetRange("Contenedor generado", false);
                if rDetallPal.find('-') then begin
                    repeat
                        if not rContenedor.Get(rDetallPal.PalletNo) then begin
                            rDetallPalCant.Reset();
                            rDetallPalCant.SetRange(PalletNo, rDetallPal.PalletNo);
                            if rDetallPalCant.FindSet() then begin
                                rProdUdMedPal.Get(rDetallPalCant.ItemNo, rContSetup."Ud. medida Pallet");
                                if rDetallPalCant.Count = rProdUdMedPal."Qty. per Unit of Measure" then begin
                                    rContenedor.Init();
                                    rContenedor.Validate(Tipo, rContSetup."Tipo pallet");
                                    rContenedor.Validate("Código", rDetallPal.PalletNo);
                                    rContenedor.Validate("Descripción");
                                    rContenedor.Validate("Almacén", rDetallPal.LocationCode);
                                    rContenedor.Validate(Ubicacion, rDetallPal.BinCode);
                                    dCantPallet += 1;
                                end else
                                    error(lErr001, rDetallPalCant.PalletNo, rDetallPalCant.Count, rProdUdMedPal."Qty. per Unit of Measure");
                                if not rContenedor.Insert(true) then
                                    rContenedor.Modify(true);
                            end;
                            //COMMIT;
                            //Creamos los contenedores hijo de los pallets
                            dCantCaja := 0;
                            cBoxNo := '';
                            rDetallPalBox.Reset();
                            rDetallPalBox.SetRange(PalletNo, rDetallPal.PalletNo);
                            rDetallPalBox.SetRange(OrderNo, PurchaseHeader."No.");
                            if rDetallPalBox.FindSet() then
                                repeat
                                    if cBoxNo <> rDetallPal.BoxNo then begin
                                        cBoxNo := rDetallPal.BoxNo;
                                        rContenedor2.Init();
                                        rContenedor2.Validate(tipo, rContSetup."Tipo caja");
                                        rContenedor2.Padre := rContenedor."Código";
                                        rContenedor2.Validate("Código", cBoxNo);
                                        if not rContenedor2.Insert(true) then
                                            rContenedor2.Modify(true);
                                        dCantCaja += 1;
                                    end;
                                until (rDetallPalBox.Next() = 0) or (dCant = dCantCaja);
                        end;
                    until (rDetallPal.Next() = 0) or (dCant = dCantPallet);
                end;
                dCantPallet := 0;
                rbox.reset;
                rbox.SetRange(OrderNo, PurchaseHeader."No.");
                rbox.SetRange(PalletNo, rContenedor.Padre);
                rbox.SetRange(BoxNo, rContenedor."Código");
                if rbox.find('-') then begin
                    repeat
                        rDetallBoxCant.Reset();
                        rDetallBoxCant.SetRange(PalletNo, rbox.PalletNo);
                        if rDetallBoxCant.FindSet() then begin
                            if not rContenedor.Get(rbox.PalletNo) then begin
                                rProdUdMedCaja.get(rBox.ItemNo, rContSetup."Ud. medida. Caja");
                                if rDetallBoxCant.Count = rProdUdMedCaja."Qty. per Unit of Measure" then begin
                                    rContenedor.Init();
                                    rContenedor.Validate(Tipo, rContSetup."Tipo caja");
                                    rContenedor.Validate("Código", rContenedor."Código");
                                    rContenedor.Validate("Descripción");
                                    rContenedor.Validate("Almacén", rbox.LocationCode);
                                    rContenedor.Validate(Ubicacion, rbox.BinCode);
                                    dCantPallet += 1;
                                end else
                                    error(lErr002, rbox.BoxNo, rDetallBoxCant.Count, rProdUdMedCaja."Qty. per Unit of Measure");
                                if not rContenedor.Insert(true) then
                                    rContenedor.Modify(true);
                            end;
                        end;
                        //COMMIT;
                        //Creamos el contenido para dicho contenedor
                        dCantCaja := 0;
                        rBoxContCont.Reset();
                        rBoxContCont.SetRange(PalletNo, rContenedor.Padre);
                        rBoxContCont.SetRange(OrderNo, PurchaseHeader."No.");
                        rBoxContCont.SetRange(BoxNo, rContenedor."Código");
                        if rBoxContCont.FindSet() then
                            repeat
                                rContCont.reset;
                                rContCont.SetRange("Código", rContenedor."Código");
                                rContCont.SetRange("Nº producto", rbox.ItemNo);
                                rContCont.SetRange(IMEI, rbox.UnitNo);
                                if not rContCont.find('-') then begin
                                    rContCont.init;
                                    rContCont.Validate("Código", rContenedor."Código");
                                    rContCont.Validate("Nº producto", rbox.ItemNo);
                                    rContCont.Validate(Cantidad, 1);
                                    rProd.get(rbox.ItemNo);
                                    rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                                    rContCont.Validate(IMEI, rbox.UnitNo);
                                    rContCont.Validate(Caducidad, rbox."Expiration Date");
                                    rcontcont.Insert();
                                    rbox."Contenedor generado" := true;
                                    rbox.Modify();
                                    dCantCaja += 1;
                                    //COMMIT;
                                end;
                            until (rBoxContCont.Next() = 0) or (dCant = dCantCaja);
                    until (rBox.Next() = 0) or (dCant = dCantPallet);
                end
            end;
        end;
    end;


    //Buscar el paquete de datos asociado al producto registrado y en el caso de que exista dar de baja
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostItemLine', '', false, false)]
    procedure ConsumirPaqDatos(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; CommitIsSupressed: Boolean; RemQtyToBeInvoiced: Decimal; RemQtyToBeInvoicedBase: Decimal; sender: Codeunit "Purch.-Post"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
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
    begin
        rItemJnlLine.DeleteAll();
        rItemJnlLine.LockTable();
        rConfCont.Get();
        ItemJnlTemplate.Get(rConfCont."Libro registro productos");
        ItemJnlBatch.Get(rConfCont."Libro registro productos", rConfCont."Sección registro productos");
        if rItemJnlLine.FindLast() then;
        LineNo := rItemJnlLine."Line No.";
        if rItem.Get(PurchaseLine."No.") then begin
            if (rItem."Gestion IMEI") and not (rItem."Gestión de IMSIs") then begin
                cDocNo := PurchaseLine."Document No.";
                rBOMComp.Reset();
                rBOMComp.SetRange("Parent Item No.", PurchaseLine."No.");
                rBOMComp.SetRange("Installed in Item No.", '');
                if rBOMComp.FindSet() then begin
                    rMovProd.Reset();
                    rMovProd.SetRange("Item No.", rBOMComp."No.");
                    rMovProd.Setfilter("Entry Type", '<>%1', rMovProd."Entry Type"::"Negative Adjmt.");
                    rMovProd.Setfilter("Remaining Quantity", '<>%1', 0);
                    if rMovProd.FindFirst() then begin
                        repeat
                            //if rMovProd."Remaining Quantity" < PurchaseLine."Qty. to Receive" then
                            rItemJnlLine.Init();
                            LineNo := LineNo + 10000;
                            rItemJnlLine."Line No." := LineNo;
                            rItemJnlLine."Journal Template Name" := rConfCont."Libro registro productos";
                            rItemJnlLine."Journal Batch Name" := rConfCont."Sección registro productos";
                            rItemJnlLine.Validate("Entry Type", rItemJnlLine."Entry Type"::"Negative Adjmt.");
                            rItemJnlLine.Validate("Document No.", rMovProd."Document No.");
                            //rItemJnlLine."Lot No." := rMovProd."Lot No.";
                            rItemJnlLine.Validate("Item No.", rMovProd."Item No.");
                            rItemJnlLine.validate("Posting Date", rMovProd."Posting Date");
                            rItemJnlLine.Validate(Quantity, rMovProd."Remaining Quantity");
                            rItemJnlLine.Validate("Quantity (Base)", rMovProd."Remaining Quantity");
                            rItemJnlLine."Posting No. Series" := rMovProd."No. Series";
                            rItemJnlLine.Validate(Description, rMovProd.Description);
                            rItemJnlLine.Insert(true);
                            rItemJnlLine.Validate("Shortcut Dimension 1 Code", rMovProd."Global Dimension 1 Code");
                            rItemJnlLine.Validate("Shortcut Dimension 2 Code", rMovProd."Global Dimension 2 Code");
                            rItemJnlLine.Validate("Dimension Set ID", rMovProd."Dimension Set ID");
                            rItemJnlLine.Validate("Location Code", rMovProd."Location Code");
                            //rItemJnlLine.Validate("Bin Code", PurchaseLine."Bin Code");
                            rItemJnlLine."Bin Code" := PurchaseLine."Bin Code";
                            rItemJnlLine.Validate("Variant Code", rMovProd."Variant Code");
                            rItemJnlLine.Validate("Item Category Code", rMovProd."Item Category Code");
                            rItemJnlLine.Validate("Inventory Posting Group", PurchaseLine."Posting Group");
                            rItemJnlLine.Validate("Gen. Bus. Posting Group", PurchaseLine."Gen. Bus. Posting Group");
                            //rItemJnlLine."Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
                            rItemJnlLine."Job No." := rMovProd."Job No.";
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
                            rItemJnlLine."Return Reason Code" := rMovProd."Return Reason Code";
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
                                recReservationEntry."Lot No." := rMovProd."Lot No.";
                                recReservationEntry.VALIDATE("Quantity (Base)", -ABS(rMovProd."Remaining Quantity"));
                                recReservationEntry."Qty. per Unit of Measure" := 1;
                                recReservationEntry."Item Tracking" := recReservationEntry."Item Tracking"::"Lot No.";
                                recReservationEntry."Created By" := USERID;
                                recReservationEntry.INSERT;
                            end;
                        until (rMovProd.Next() = 0) or (rMovProd."Remaining Quantity" = PurchaseLine."Qty. to Receive");
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", rItemJnlLine);
                        RegistroActivaciones(cDocNo);
                    end;
                end;
            end;
        end;
    end;

    procedure RegistroActivaciones(cDocNo: Code[20])
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
                rActIMEI.Insert(true);
            until rDetallPal.Next() = 0;
    end;

    //Campos que se cubren en este punto: N.º pedido IMSI y Precio IMSI, al registrar el pedido con el paquete de datos
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post (Yes/No)", 'OnAfterPost', '', false, false)]
    procedure RegistroPedIMSI(var PurchaseHeader: Record "Purchase Header")
    var
        rDetallPal: Record AzmHFBreakdownPallet;
        rPurchaseLine: Record "Purchase Line";
        dCant, dCantIMSI : Decimal;
    begin
        rPurchaseLine.Reset();
        rPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        rPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if rPurchaseLine.FindSet() then
            repeat
                dCantIMSI := 0;
                rDetallPal.Reset();
                rDetallPal.SetFilter(IMSI, '<>%1', '');
                rDetallPal.SetRange("Nº pedido IMSI", '');
                if not rDetallPal.Find('-') then
                    repeat
                        if rPurchaseLine."Qty. to Receive" > dCantIMSI then begin
                            rDetallPal.Validate("Nº pedido IMSI", rPurchaseLine."Document No.");
                            rDetallPal.Validate("Unit Cost", rPurchaseLine."Direct Unit Cost");
                            if rDetallPal.Modify(true) then
                                dCantIMSI += 1;
                        end;
                    until (rDetallPal.Next() = 0) or (rPurchaseLine."Qty. to Receive" = dCantIMSI);
            until rPurchaseLine.Next() = 0;
    end;

    //Buscar el paquete de datos asociado al producto registrado y en el caso de que exista dar de baja
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnAfterCode', '', false, false)]
    procedure ConsumirPaqDatosRecep(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; CounterSourceDocOK: Integer; CounterSourceDocTotal: Integer)
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
    begin
        rItemJnlLine.DeleteAll();
        rItemJnlLine.LockTable();
        rConfCont.Get();
        ItemJnlTemplate.Get(rConfCont."Libro registro productos");
        ItemJnlBatch.Get(rConfCont."Libro registro productos", rConfCont."Sección registro productos");
        if rItemJnlLine.FindLast() then;
        LineNo := rItemJnlLine."Line No.";
        if rItem.Get(WarehouseReceiptLine."No.") then begin
            if (rItem."Gestion IMEI") and not (rItem."Gestión de IMSIs") then begin
                cDocNo := WarehouseReceiptLine."Source No.";
                rBOMComp.Reset();
                rBOMComp.SetRange("Parent Item No.", WarehouseReceiptLine."No.");
                rBOMComp.SetRange("Installed in Item No.", '');
                if rBOMComp.FindSet() then begin
                    rMovProd.Reset();
                    rMovProd.SetRange("Item No.", rBOMComp."No.");
                    rMovProd.Setfilter("Entry Type", '<>%1', rMovProd."Entry Type"::"Negative Adjmt.");
                    rMovProd.Setfilter("Remaining Quantity", '<>%1', 0);
                    if rMovProd.FindFirst() then begin
                        repeat
                            rItemJnlLine.Init();
                            LineNo := LineNo + 10000;
                            rItemJnlLine."Line No." := LineNo;
                            rItemJnlLine."Journal Template Name" := rConfCont."Libro registro productos";
                            rItemJnlLine."Journal Batch Name" := rConfCont."Sección registro productos";
                            rItemJnlLine.Validate("Entry Type", rItemJnlLine."Entry Type"::"Negative Adjmt.");
                            rItemJnlLine.Validate("Document No.", rMovProd."Document No.");
                            //rItemJnlLine."Lot No." := rMovProd."Lot No.";
                            rItemJnlLine.Validate("Item No.", rMovProd."Item No.");
                            rItemJnlLine.validate("Posting Date", rMovProd."Posting Date");
                            rItemJnlLine.Validate(Quantity, rMovProd."Remaining Quantity");
                            rItemJnlLine.Validate("Quantity (Base)", rMovProd."Remaining Quantity");
                            rItemJnlLine."Posting No. Series" := rMovProd."No. Series";
                            rItemJnlLine.Validate(Description, rMovProd.Description);
                            rItemJnlLine.Insert(true);
                            rItemJnlLine.Validate("Shortcut Dimension 1 Code", rMovProd."Global Dimension 1 Code");
                            rItemJnlLine.Validate("Shortcut Dimension 2 Code", rMovProd."Global Dimension 2 Code");
                            rItemJnlLine.Validate("Dimension Set ID", rMovProd."Dimension Set ID");
                            rItemJnlLine.Validate("Location Code", rMovProd."Location Code");
                            rItemJnlLine.Validate("Bin Code", WarehouseReceiptLine."Bin Code");
                            rItemJnlLine.Validate("Variant Code", rMovProd."Variant Code");
                            rItemJnlLine.Validate("Item Category Code", rMovProd."Item Category Code");
                            rItemJnlLine."Job No." := rMovProd."Job No.";
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
                            rItemJnlLine."Source No." := rMovProd."Source No.";
                            rItemJnlLine."Purchasing Code" := rMovProd."Purchasing Code";
                            rItemJnlLine."Return Reason Code" := rMovProd."Return Reason Code";
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
                                recReservationEntry."Lot No." := rMovProd."Lot No.";
                                recReservationEntry.VALIDATE("Quantity (Base)", -ABS(rMovProd."Remaining Quantity"));
                                recReservationEntry."Qty. per Unit of Measure" := 1;
                                recReservationEntry."Item Tracking" := recReservationEntry."Item Tracking"::"Lot No.";
                                recReservationEntry."Created By" := USERID;
                                recReservationEntry.INSERT;
                            end;
                        until (rMovProd.Next() = 0) or (rMovProd."Remaining Quantity" = WarehouseReceiptLine."Qty. to Receive");
                        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Line", rItemJnlLine);
                        RegistroActivaciones(cDocNo);
                    end;
                end;
            end;
        end;
    end;

    procedure VerificarCdadContenedor(cPedNo: code[20])
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
        if (dCdadPed <> 0) and (cprod <> '') then
            VerificaContenedor(cpedno, dCdadPed, cProd);
    end;

    Procedure VerificaContenedor(cPed: code[20]; dCdadRec: Decimal; cProd: code[20])
    var
        rProd: record item;
        rDet: record AzmHFBreakdownPallet;
        lText001: Label 'The merchandise receipt cannot be generated. We only have %1 units in the pallet detail table pending to be generated.', comment = 'ESP="No se puede generar la recepción de mercancía. Solo tenemos %1 unidades en la tabla detalle palet pendientes de generar."';
        lText002: Label 'The merchandise receipt cannot be generated. There are no units in the pallet detail table to be generated.', comment = 'ESP="No se puede generar la recepción de mercancía. No disponemos de unidades en la tabla detalle palet pendientes de generar."';
    begin
        rprod.get(cprod);
        if rprod."Gestión de contenedores" then begin
            rdet.reset;
            rdet.SetRange(OrderNo, cped);
            rdet.SetRange(ItemNo, cProd);
            rdet.SetRange("Contenedor generado", false);
            if rdet.Find('-') then begin
                if rdet.Count < dCdadRec then
                    error(lText001, format(rdet.count));
            end else
                error(lText002, format(rdet.count));
        end;
    end;

    // Pedidos Ventas

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", 'OnBeforeConfirmWhseShipmentPost', '', false, false)]
    procedure CompCantContRegEnv(var WhseShptLine: Record "Warehouse Shipment Line"; var HideDialog: Boolean; var Invoice: Boolean; var IsPosted: Boolean; var Selection: Integer)
    var
        rPedidoLoteIMEI: record "Pedido - Lote - IMEI";
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the quantity indicated on the shipping document line.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del documento de envío."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the quantity indicated on the shipping document line.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del documento de envío."';
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
    begin
        rContSetup.Get();
        if rContSetup."Comprobación pallets/cajas" then begin
            rPedidoLoteIMEI.reset();
            rPedidoLoteIMEI.SetRange("Nº pedido", WhseShptLine."Source No.");
            rPedidoLoteIMEI.SetRange("Nº Linea pedido", WhseShptLine."Source Line No.");
            if rPedidoLoteIMEI.find('-') then
                repeat
                    if rContenedor.Get(rPedidoLoteIMEI.Lote) then begin
                        if rContSetup."Tipo pallet" = rContenedor.Tipo then begin
                            if rPedidoLoteIMEI.Count <> WhseShptLine."Qty. to Ship" then
                                error(lErr001, rPedidoLoteIMEI.Lote, rPedidoLoteIMEI.Count, WhseShptLine."Qty. to Ship");
                        end else begin
                            if rContSetup."Tipo caja" = rContenedor.Tipo then begin
                                if rPedidoLoteIMEI.Count <> WhseShptLine."Qty. to Ship" then
                                    error(lErr002, rPedidoLoteIMEI.Lote, rPedidoLoteIMEI.Count, WhseShptLine."Qty. to Ship");
                            end;
                        end;
                    end;
                until rPedidoLoteIMEI.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", 'OnAfterCode', '', false, false)]
    procedure ElimContRegEnv(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        rPedidoLoteIMEI: record "Pedido - Lote - IMEI";
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
        rTipoCont: Record "Tipo contenedor";
        rDetallPal: Record AzmHFBreakdownPallet;
    begin
        rContSetup.Get();
        rPedidoLoteIMEI.reset();
        rPedidoLoteIMEI.SetRange("Nº pedido", WarehouseShipmentLine."Source No.");
        rPedidoLoteIMEI.SetRange("Nº Linea pedido", WarehouseShipmentLine."Source Line No.");
        if rPedidoLoteIMEI.find('-') then
            repeat
                if rContenedor.Get(rPedidoLoteIMEI.Lote) then begin
                    if rContSetup."Tipo pallet" = rContenedor.Tipo then begin
                        rTipoCont.Get(rContenedor.Tipo);
                        if rTipoCont.Fungible then begin
                            //rContenedor.Delete();
                            rContCont.reset;
                            rContCont.SetRange("Código", rContenedor."Código");
                            rContCont.SetRange("Nº producto", WarehouseShipmentLine."Item No.");
                            rContCont.SetRange(IMEI, rPedidoLoteIMEI.IMEI);
                            if not rContCont.find('-') then
                                repeat
                                    //No se borra el contenedor solo el contenido contenedor
                                    rContCont.Delete();
                                until rContCont.Next() = 0;
                        end;
                    end else begin
                        if rContSetup."Tipo caja" = rContenedor.Tipo then begin
                            rTipoCont.Get(rContenedor.Tipo);
                            //rContenedor.Delete();
                            rContCont.reset;
                            rContCont.SetRange("Código", rContenedor."Código");
                            rContCont.SetRange("Nº producto", WarehouseShipmentLine."Item No.");
                            rContCont.SetRange(IMEI, rPedidoLoteIMEI.IMEI);
                            if not rContCont.find('-') then
                                repeat
                                    //No se borra el contenedor solo el contenido contenedor
                                    rContCont.Delete();
                                until rContCont.Next() = 0;
                        end;
                    end;
                end;
            until rPedidoLoteIMEI.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostItemLine', '', false, false)]
    procedure AsigContManualPedVenta(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; var TempSalesLineGlobal: Record "Sales Line" temporary; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the quantity indicated on the sales order line.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del pedido de venta."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the quantity indicated on the sales order line.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del pedido de venta."';
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
    begin
        //Buscar en la tabla comunicaciones me mandan imei y pallet o caja, la cantidad la sé al crearlo comprobar de todas formas
        rContSetup.Get();
        if rContSetup."Comprobación pallets/cajas" then begin
            rContCont.reset();
            rContCont.SetRange("Nº producto", SalesLine."No.");
            rContCont.SetRange(PedVenta, SalesLine."Document No.");
            if rContCont.find('-') then
                repeat
                    if rContenedor.Get(rContCont."Código") then begin
                        if rContSetup."Tipo pallet" = rContenedor.Tipo then begin
                            if rContCont.Count < SalesLine."Qty. to Ship" then
                                error(lErr001, rContCont."Código", rContCont.Count, SalesLine."Qty. to Ship");
                        end else begin
                            if rContSetup."Tipo caja" = rContenedor.Tipo then begin
                                if rContCont.Count < SalesLine."Qty. to Ship" then
                                    error(lErr002, rContCont."Código", rContCont.Count, SalesLine."Qty. to Ship");
                            end;
                        end;
                    end;
                until rContCont.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostItemLine', '', false, false)]
    procedure CompCantContRegPedVent(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; var TempSalesLineGlobal: Record "Sales Line" temporary; var RemQtyToBeInvoiced: Decimal; var RemQtyToBeInvoicedBase: Decimal; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the quantity indicated on the sales order line.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del pedido de venta."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the quantity indicated on the sales order line.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del pedido de venta."';
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
    begin
        //Buscar en la tabla comunicaciones me mandan imei y pallet o caja, la cantidad la sé al crearlo comprobar de todas formas
        rContSetup.Get();
        if rContSetup."Comprobación pallets/cajas" then begin
            rContCont.reset();
            rContCont.SetRange("Nº producto", SalesLine."No.");
            rContCont.SetRange(PedVenta, SalesLine."Document No.");
            if rContCont.find('-') then
                repeat
                    if rContenedor.Get(rContCont."Código") then begin
                        if rContSetup."Tipo pallet" = rContenedor.Tipo then begin
                            if rContCont.Count < SalesLine."Qty. to Ship" then
                                error(lErr001, rContCont."Código", rContCont.Count, SalesLine."Qty. to Ship");
                        end else begin
                            if rContSetup."Tipo caja" = rContenedor.Tipo then begin
                                if rContCont.Count < SalesLine."Qty. to Ship" then
                                    error(lErr002, rContCont."Código", rContCont.Count, SalesLine."Qty. to Ship");
                            end;
                        end;
                    end;
                until rContCont.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostItemLine', '', false, false)]
    procedure ElimContRegPedVent(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean; QtyToInvoice: Decimal; QtyToInvoiceBase: Decimal)
    var
        rPedidoLoteIMEI: record "Pedido - Lote - IMEI";
        lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        lErr002: Label 'Box %1 which has %2 units should have %3 units according to the corresponding unit of measure number.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según el número de unidad de medida correspondiente."';
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
        rTipoCont: Record "Tipo contenedor";
        rDetallPal: Record AzmHFBreakdownPallet;
    begin
        rContSetup.Get();
        rPedidoLoteIMEI.reset();
        rPedidoLoteIMEI.SetRange("Nº pedido", SalesLine."Document No.");
        rPedidoLoteIMEI.SetRange("Nº Linea pedido", SalesLine."Line No.");
        if rPedidoLoteIMEI.find('-') then
            repeat
                if rContenedor.Get(rPedidoLoteIMEI.Lote) then begin
                    if rContSetup."Tipo pallet" = rContenedor.Tipo then begin
                        rTipoCont.Get(rContenedor.Tipo);
                        if rTipoCont.Fungible then begin
                            //rContenedor.Delete();
                            rContCont.reset;
                            rContCont.SetRange("Código", rContenedor."Código");
                            rContCont.SetRange("Nº producto", SalesLine."No.");
                            rContCont.SetRange(IMEI, rPedidoLoteIMEI.IMEI);
                            if not rContCont.find('-') then
                                repeat
                                    //No se borra el contenedor solo el contenido contenedor
                                    rContCont.Delete();
                                until rContCont.Next() = 0;
                        end;
                    end else begin
                        if rContSetup."Tipo caja" = rContenedor.Tipo then begin
                            rTipoCont.Get(rContenedor.Tipo);
                            //rContenedor.Delete();
                            rContCont.reset;
                            rContCont.SetRange("Código", rContenedor."Código");
                            rContCont.SetRange("Nº producto", SalesLine."No.");
                            rContCont.SetRange(IMEI, rPedidoLoteIMEI.IMEI);
                            if not rContCont.find('-') then
                                repeat
                                    //No se borra el contenedor solo el contenido contenedor
                                    rContCont.Delete();
                                until rContCont.Next() = 0;
                        end;
                    end;
                end;
            until rPedidoLoteIMEI.Next() = 0;
    end;

    /* Marcar origen y destino y crear movimiento de inventario */
    /*procedure ReubicarContenedor(cCodCont: code[20]; cAlmFin: code[20]; cZonaFin: code[20]; cUbiFin: Code[20])
    var
        rconfalm: record "Warehouse Setup";
        rDiaAlm: Record "Warehouse Journal Line";
        rContenedor: Record Contenedores;
        rContCont: Record "Contenido contenedor";
        iLinea: Integer;
        cAlmIni, cZonIni, cUbiIni : code[20];
    begin
        if rContenedor.Get(cCodCont) then begin
            cAlmIni := rContenedor."Almacén";
            cZonIni := rContenedor.Zona;
            cUbiIni := rContenedor.Ubicacion;
            
            //Se mueven todos los artículos indicados de una zona y ubicacion indicada a la de destino        
            rContCont.reset;
            rContCont.SetRange("Código", cCodCont);
            if rContCont.find('-') then begin
                if rdiaalm.TemplateSelection(PAGE::"Whse. Reclassification Journal", "Warehouse Journal Template Type"::Reclassification, rdiaalm) then begin
                    if rDiaAlm.find('+') then
                        iLinea := rDiaAlm."Line No." + 10000
                    else
                        iLinea := 10000;
                    repeat
                        rconfalm.get();
                        rDiaAlm.Validate("Journal Template Name", rconfalm.ReclasJT);
                        rDiaAlm.Validate("Journal Batch Name", rconfalm.ReclasJB);

                        rDiaAlm.Validate("Item No.", rContCont."Nº producto");
                        rdiaalm.validate("Location Code", cAlmIni);
                        rDiaAlm.Validate("From Zone Code", cZonIni);
                        rDiaAlm.Validate("To Zone Code", cZonaFin);
                        rDiaAlm.Validate("From Bin Code", cUbiIni);
                        rDiaAlm.Validate("To Bin Code", cUbiFin);
                        rDiaAlm.Validate(Quantity, rContCont.Cantidad);
                        if not rdiaalm.Insert(true) then rdiaalm.Modify(true);
                    until rContCont.Next() = 0;
                end;
                //Registramos el diario
                CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register", rDiaAlm);
            end;
            rContenedor.Validate("Almacén", cAlmFin);
            rContenedor.Validate(Zona, cZonaFin);
            rContenedor.Validate(Ubicacion, cUbiFin);
            rContenedor.Modify(true);
        end;
    end;*/

    //dentro ficha producto crear campo fecha caducidad
}
