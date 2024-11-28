report 50300 "Recargar historico IMEI"
{
    ApplicationArea = All;
    Caption = 'Recargar histórico IMEI';
    UsageCategory = Tasks;
    ProcessingOnly = true;
    UseRequestPage = true;


    dataset
    {
        dataitem(Integer; "Integer")
        {

            trigger OnPreDataItem()
            var
            begin
                SetRange(Number, 1);
            end;

            trigger OnAfterGetRecord()
            var
                rHistoricosIMEI: Record "Historicos IMEI";
                rSalesInvLn: record "Sales Invoice Line";
                SalesInvoiceHeader: record "Sales Invoice Header";
                rContenidocontenedor: record "Contenido contenedor";
                Window: Dialog;
                texto: Text[1024];
            begin

                // texto := 'Cargando datos \'
                //             + ' \'
                //             + ' Referencia factura         #1################### \'
                //             + ' IMEI               #2################################### \';




                SalesInvoiceHeader.Reset();

                if (fechaDesde <> 0D) and (fechaHasta <> 0D) then
                    SalesInvoiceHeader.SetFilter("Posting Date", '%1..%2', fechaDesde, fechaHasta)
                else if fechaDesde <> 0D then
                    SalesInvoiceHeader.SetFilter("Posting Date", '%1..', fechaDesde)
                else if fechaHasta <> 0D then
                    SalesInvoiceHeader.SetFilter("Posting Date", '..%1', fechaHasta);

                if SalesInvoiceHeader.FindSet() then //begin
                    // Window.OPEN(texto);
                    repeat
                        Window.Update(1, SalesInvoiceHeader."No.");
                        rSalesInvLn.Reset();
                        rSalesInvLn.SetRange("Document No.", SalesInvoiceHeader."No.");
                        rSalesInvLn.SetRange(Type, Enum::"Sales Line Type"::Item);
                        if rSalesInvLn.FindSet() then
                            repeat
                                rContenidocontenedor.Reset();

                                if rSalesInvLn."Shipment No." <> '' then
                                    rContenidocontenedor.SetRange("Nº albarán venta", rSalesInvLn."Shipment No.")
                                else if rSalesInvLn."Order No." <> '' then
                                    rContenidocontenedor.SetRange(pedventa, rSalesInvLn."Order No.")
                                else
                                    if rSalesInvLn.Next() = 0 then;

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

                                    // Window.UPDATE(2, rHistoricosIMEI.IMEI);

                                    until rContenidocontenedor.Next() = 0;
                            until rSalesInvLn.Next() = 0;

                    until SalesInvoiceHeader.Next() = 0;
            end;

            //end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(fechaDesde; fechaDesde)
                    {
                        ApplicationArea = All;
                    }
                    field(fechaHasta; fechaHasta)
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }
        actions
        {
            area(Processing)
            {
            }
        }
    }

    var
        fechaDesde: Date;
        fechaHasta: Date;

    trigger OnInitReport()
    var
    begin
        fechaDesde := 0D;
        fechaHasta := 0D;
    end;
}
