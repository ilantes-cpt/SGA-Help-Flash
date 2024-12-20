pageextension 50305 "Purchase Order Subform Ext" extends "Purchase Order Subform"
{
    layout
    {
        addafter("Over-Receipt Code")
        {
            field("Nº Lote"; Rec."Nº Lote")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }
    actions
    {
        addlast("F&unctions")
        {
            action("Importar IMSIs")
            {
                ApplicationArea = all;
                Image = Import;
                Caption = 'Import IMSIs';

                trigger OnAction()
                var
                    //rListaIMSI: Record "AzmHF IMSI Lots Number";
                    rDetallPal, rDetallPall, rDetallPalle : Record AzmHFBreakdownPallet;
                    InS: InStream;
                    tFileName, tFromFile : Text[100];
                    UploadMsg: Label 'Please choose the CSV file', comment = 'ESP="Seleccione el archivo CSV"';
                    lNoFileFoundMsg: Label 'No CSV file found!';
                    lErr001: Label 'The file to be imported contains less IMSI codes than units of the product in the selected purchase line.', comment = 'ESP="El archivo a importar contiene menos códigos IMSI que uds del producto en la línea de compra seleccionada."';
                    cFileMgt: Codeunit "File Management";
                    LineNo, iEntryNo, iRepetidos : Integer;
                    dCant, dCantIMSI : Decimal;
                    rBOMComp: Record "BOM Component";
                    dDialog: Dialog;
                    rItem: Record Item;
                    lText001: Label 'The selected product is not a data package.', comment = 'ESP="El producto seleccionado no es un paquete de datos."';
                    cCodIMSI: Code[20];
                    lText002: Label 'The IMSI code %1 that you want to import already exists in pallet detail.', comment = 'ESP="El código de IMSI %1 que quiere importar ya existe en detalle palet."';
                    lText003: Label 'Some IMSI codes (%1) already exists in pallet detail.', comment = 'ESP="Algunos códigos IMSI (%1) ya existe en detalle palet."';
                begin
                    if rItem.Get(Rec."No.") then begin
                        if rItem."Gestión de IMSIs" then begin
                            //dCantIMSI := 0;
                            dCant := 0;
                            /*if Rec."Nº Lote" = 0 then
                                dCant := 0
                            else
                                dCant := Rec."Nº Lote";*/
                            rBOMComp.Reset();
                            rBOMComp.SetRange("No.", Rec."No.");
                            rBOMComp.Setfilter("Installed in Item No.", '<>%1', Rec."No.");
                            ddialog.open('Procesando registros #1#####');
                            if rBOMComp.FindSet() then begin
                                UploadIntoStream(UploadMsg, '', '', tFromFile, InS);
                                if tFromFile <> '' then begin
                                    tFileName := cFileMgt.GetFileName(tFromFile);
                                end else
                                    Error(lNoFileFoundMsg);
                                iRepetidos := 0;
                                rDetallPalle.Reset();
                                rDetallPalle.SetFilter(EntryNo, '<>%1', 0);
                                if rDetallPalle.FindLast() then
                                    iEntryNo := 1 + rDetallPalle.EntryNo
                                ELSE
                                    iEntryNo := 1;
                                //dCantIMSI := Rec."Qty. to Receive";
                                CSVBuffer.Reset();
                                CSVBuffer.DeleteAll();
                                CSVBuffer.LoadDataFromStream(InS, ';');
                                //if dCantIMSI > CSVBuffer.GetNumberOfLines() - 1 then
                                //Error(lErr001);
                                for LineNo := 2 to CSVBuffer.GetNumberOfLines() do begin
                                    ddialog.update(1, lineno - 1);
                                    //cCodIMSI := GetValueAtCell(LineNo, 1);
                                    rDetallPal.Reset();
                                    rDetallPal.SetCurrentKey(IMSI);
                                    rDetallPal.SetRange(IMSI, GetValueAtCell(LineNo, 1));
                                    //rDetallPal.SetRange(IMSI, cCodIMSI);
                                    if not rDetallPal.Find('-') then begin
                                        //if not rListaIMSI.Get(GetValueAtCell(LineNo, 1)) then begin
                                        if GetValueAtCell(LineNo, 1) <> '' then begin
                                            //if dCant = dCantIMSI then
                                            //break;
                                            /*rListaIMSI.Init();
                                            Evaluate(rListaIMSI."IMSI Code", GetValueAtCell(LineNo, 1));
                                            rListaIMSI.Validate("IMSI Code", GetValueAtCell(LineNo, 1));
                                            rListaIMSI.Validate("BC Lot No", Rec."Document No.");
                                            if rListaIMSI.Insert(true) then
                                                dCant += 1;*/
                                            rDetallPall.Init();
                                            rDetallPall.EntryNo := iEntryNo;
                                            //Evaluate(rDetallPall.IMSI, cCodIMSI);
                                            //rDetallPall.Validate(IMSI, cCodIMSI);
                                            rDetallPall.Validate(IMSI, GetValueAtCell(LineNo, 1));
                                            rDetallPall.Validate("Nº pedido IMSI", Rec."Document No.");
                                            rDetallPall.Validate("Unit Cost", Rec."Direct Unit Cost");
                                            rDetallPall.Validate(OnlyIMSI, true);
                                            if rDetallPall.Insert(true) then begin
                                                dCant += 1;
                                                iEntryNo += 1;
                                            end;
                                        end;
                                    end else
                                        iRepetidos += 1;
                                    ;/* else
                                        Message(lText002, GetValueAtCell(LineNo, 1));*/
                                end;
                                //Rec.Validate("Qty. to Receive", dCant);
                                Rec.Validate("Nº Lote", dCant);
                                Rec.Modify(true);
                                //if dCant <> 0 then
                                //CrearReservaComprasCantidad(Rec, dCant);
                            end;
                            ddialog.close;
                            if iRepetidos <> 0 then
                                message(lText003, iRepetidos)
                        end else
                            Message(lText001);
                    end;
                end;
            }
        }
    }
    var
        CSVBuffer: Record "CSV Buffer" temporary;

    local procedure GetValueAtCell(RowNo: Integer; ColNo: Integer): Text
    begin
        if CSVBuffer.Get(RowNo, ColNo) then
            exit(CSVBuffer.Value)
        else
            exit('');
    end;

    procedure CrearReservaComprasCantidad(var rPurchLine: record "Purchase Line"; var Cantidad: Decimal);
    var
        recReservationEntry: record "Reservation Entry";
        wUltNumMov: Integer;
        rPurchSetup: Record "Purchases & Payables Setup";
        rItem: Record Item;
    begin
        if rItem.Get(rPurchLine."No.") then begin
            if rItem."Item Tracking Code" <> '' then begin
                rPurchSetup.Get();
                recReservationEntry.Reset();
                recReservationEntry.SetRange("Item No.", rPurchLine."No.");
                recReservationEntry.SetRange("Source ID", rPurchLine."Document No.");
                recReservationEntry.SetRange("Source Ref. No.", rPurchLine."Line No.");
                if recReservationEntry.FindSet() then begin
                    recReservationEntry."Quantity (Base)" := Cantidad;
                    recReservationEntry."Qty. to Handle (Base)" := Cantidad;
                    recReservationEntry.VALIDATE(Quantity, Cantidad);
                    recReservationEntry."Qty. to Invoice (Base)" := Cantidad;
                    recReservationEntry."Qty. to Handle (Base)" := Cantidad;
                    recReservationEntry.Modify();
                end else begin
                    CLEAR(recReservationEntry);
                    recReservationEntry.INIT;
                    recReservationEntry."Entry No." := wUltNumMov;
                    recReservationEntry."Item No." := rPurchLine."No.";
                    //recReservationEntry."Item No." := rPurchSetup."Paquetes de datos";
                    recReservationEntry."Lot No." := rPurchLine."Document No.";
                    recReservationEntry."Item Tracking" := recReservationEntry."Item Tracking"::"Lot No.";
                    recReservationEntry."Source Type" := 39;
                    recReservationEntry."Source Subtype" := 1;
                    recReservationEntry."Source ID" := rPurchLine."Document No.";
                    recReservationEntry."Source Batch Name" := '';
                    recReservationEntry."Source Prod. Order Line" := 0;
                    recReservationEntry."Source Ref. No." := rPurchLine."Line No.";
                    recReservationEntry."Location Code" := rPurchLine."Location Code";
                    recReservationEntry."Variant Code" := rPurchLine."Variant Code";
                    recReservationEntry.Positive := FALSE;
                    recReservationEntry."Quantity (Base)" := Cantidad;
                    recReservationEntry."Qty. to Handle (Base)" := Cantidad;
                    recReservationEntry."Expiration Date" := 0D;
                    recReservationEntry."Reservation Status" := recReservationEntry."Reservation Status"::Surplus;
                    recReservationEntry."Creation Date" := rPurchLine."Order Date";
                    recReservationEntry."Expected Receipt Date" := rPurchLine."Expected Receipt Date";
                    recReservationEntry."Created By" := USERID;
                    recReservationEntry.VALIDATE(Quantity, Cantidad);
                    recReservationEntry."Qty. to Invoice (Base)" := Cantidad;
                    recReservationEntry."Qty. to Handle (Base)" := Cantidad;
                    recReservationEntry.INSERT;
                end;
            end;
        end;
    end;
}
