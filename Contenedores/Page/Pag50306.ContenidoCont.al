page 50306 "Contenido Cont."
{
    //ApplicationArea = All;
    ApplicationArea = Basic, Suite;
    Caption = 'Container Content';
    PageType = List;
    SourceTable = "Contenido contenedor";
    SourceTableView = where(Incidencia = filter(false));
    UsageCategory = Lists;
    //Editable = true;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Código"; Rec."Código") { }
                field("Nº producto"; Rec."Nº producto")
                {
                    TableRelation = Item;
                }
                field(Cantidad; Rec.Cantidad) { }
                field("Unidad de medida"; Rec."Unidad de medida") { }
                field(IMEI; Rec.IMEI) { }
                field(Caducidad; Rec.Caducidad) { }
                field(Padre; Rec.Padre) { }
                field("Nº Albarán Compra"; Rec."Nº Albarán Compra") { }
                field(PedVenta; Rec.PedVenta) { }
                field(LinPedVenta; Rec.LinPedVenta) { }
                field(Vendido; Rec.Vendido) { }
                field("Nº pedido ensamblado"; Rec."Nº pedido ensamblado") { }
                field("Nº linea pedido ensamblado"; Rec."Nº linea pedido ensamblado") { }
                field("Nº albarán venta"; Rec."Nº albarán venta") { }
                field("Cód Almacén"; Rec."Cód Almacén")
                {
                    TableRelation = location.Code;
                }
                field(PedTrans; Rec.PedTrans) { }
                field(LinPedTrans; Rec.LinPedTrans) { }
                field(EnvioAlm; Rec.EnvioAlm) { }
                field(LinEnvio; Rec.LinEnvio) { }
                field(RecepAlm; Rec.RecepAlm) { }
                field(LinRecep; Rec.LinRecep) { }
                field("Libro registro productos"; Rec."Libro registro productos") { }
                field("Sección registro productos"; Rec."Sección registro productos") { }
                field(LinDiario; Rec.LinDiario) { }
                field(PedCompra; Rec.PedCompra) { }
                field(LinPedCompra; Rec.LinPedCompra) { }
                field("Nº abono venta"; Rec."Nº abono venta") { ApplicationArea = All; }
                field("Nº linea abono venta"; Rec."Nº linea abono venta") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(MarcarIncidencia)
            {
                Caption = 'Mark/unmark incidence';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Return;

                trigger OnAction()
                var
                    rContenido, rRen : Record "Contenido contenedor";
                    pAlmacen: page "Location List";
                    rAlmacen: Record Location;
                begin
                    //Seleccionar el almacén al que se llevará la mercancía
                    // rAlmacen.reset;
                    // rAlmacen.SetRange("Use As In-Transit", false);
                    // Clear(pAlmacen);
                    // pAlmacen.SetTableView(rAlmacen);
                    // pAlmacen.LookupMode := true;
                    // if pAlmacen.RunModal = action::LookupOK then begin
                    //     pAlmacen.GetRecord(rAlmacen);
                    //     rAlmacen.TestField("Contenedor devoluciones");
                    //     //Marcamos os registos como incidencia

                    rContenido.Reset();
                    rContenido.Copy(Rec);
                    CurrPage.SetSelectionFilter(rcontenido);
                    if rContenido.find('-') then
                        repeat
                            if rContenido.Vendido then begin
                                rContenido.Validate(Incidencia, not (rContenido.Incidencia));
                                if rContenido.Incidencia then
                                    rContenido.Validate(Vendido, true);
                                rContenido.Modify();

                                //Se cambia el contenedor de ubicación al predeterminado de almacén
                                // if rContenido."Código" <> rAlmacen."Contenedor devoluciones" then begin
                                //     rren.get(rContenido."Código", rContenido."Nº producto", rContenido.IMEI);
                                //     rren.Rename(rAlmacen."Contenedor devoluciones", rren."Nº producto", rren.IMEI);
                                // end;
                            end;
                        until rcontenido.Next() = 0;

                    // end else
                    //     Message('No realizamos el marcado al no seleccionar almacén');
                end;
            }

            action(Incidencias)
            {
                ApplicationArea = All;
                Caption = 'Incidencias', comment = 'NLB="YourLanguageCaption"';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = OpenJournal;
                RunObject = page Incidencias;

            }

            /*
            action(ActValor)
            {
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ClearLog;

                trigger OnAction()
                var
                    rContCont, rcontenido : record "Contenido contenedor";
                    cProdAnt, cProdNuev, cProdPru : Code[20];
                begin
                    cProdAnt := 'PD-000099';
                    cProdNuev := 'PD-000037';
                    rContCont.reset();
                    rContCont.SetRange("Nº producto", cProdAnt);
                    if rContCont.Find('-') then
                        repeat
                            rcontenido.Copy(rContCont);
                            rcontenido.Rename(rContCont."Código", cProdNuev, rContCont.IMEI);
                        until rContCont.Next() = 0;
                    Message('Proceso finalizado');
                end;
            }
            */
        }
    }
}
