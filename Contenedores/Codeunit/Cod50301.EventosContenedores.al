codeunit 50301 "Eventos Contenedores"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterFinalizePosting', '', false, false)]
    local procedure c80OnAfterFinalizePosting(var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    var
        rHistoricosIMEI: Record "Historicos IMEI";
        rSalesInvLn: record "Sales Invoice Line";
        rContenidocontenedor: record "Contenido contenedor";
    begin
        if not SalesInvoiceHeader.IsEmpty then begin
            rSalesInvLn.Reset();
            rSalesInvLn.SetRange("Document No.", SalesInvoiceHeader."No.");
            rSalesInvLn.SetRange(Type, Enum::"Sales Line Type"::Item);            
            if rSalesInvLn.FindSet() then
                repeat
                    rContenidocontenedor.Reset();
                    rContenidocontenedor.SetRange("Nº producto", rSalesInvLn."No.");

                    if rSalesInvLn."Shipment No." <> '' then
                        rContenidocontenedor.SetRange("Nº albarán venta", rSalesInvLn."Shipment No.")
                    else if rSalesInvLn."Order No." <> '' then
                        rContenidocontenedor.SetRange(pedventa, rSalesInvLn."Order No.")
                    else 
                        rSalesInvLn.Next();

                    if rContenidocontenedor.FindSet() then
                        repeat //SI EXISTE LO MODIFICAMOS POR LA NUEVA FACTURA DONDE SE ENCUENTRA.
                            rHistoricosIMEI.Reset();
                            rHistoricosIMEI.SetRange(IMEI, rContenidocontenedor.IMEI);
                            if rHistoricosIMEI.FindSet() then begin
                                rHistoricosIMEI.IMEI := rContenidocontenedor.IMEI;
                                rHistoricosIMEI."Nº factura venta" := SalesInvoiceHeader."No.";
                                rHistoricosIMEI."Fecha registro factura" := SalesInvoiceHeader."Posting Date";
                                rHistoricosIMEI.Modify();
                            end else begin // SINO EXISTE EL REGISTRO EN EL HISTORICO LO CREAMOS
                                rHistoricosIMEI.Reset();
                                rHistoricosIMEI.Init();
                                rHistoricosIMEI.IMEI := rContenidocontenedor.IMEI;
                                rHistoricosIMEI."Nº factura venta" := SalesInvoiceHeader."No.";
                                rHistoricosIMEI."Fecha registro factura" := SalesInvoiceHeader."Posting Date";
                                rHistoricosIMEI.Insert();
                            end;
                        until rContenidocontenedor.Next() = 0;
                until rSalesInvLn.Next() = 0;
        end;
    end;
}
