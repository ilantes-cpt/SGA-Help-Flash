page 50300 "Lista contenedores"
{
    ApplicationArea = All;
    Caption = 'Container list';
    PageType = List;
    SourceTable = Contenedores;
    UsageCategory = Lists;
    DelayedInsert = true;
    PromotedActionCategories = 'New,Process,Report,Navigate';

    layout
    {
        area(content)
        {
            group(Total)
            {
                Visible = bcantidad;

                field(QtyOnCont; dCantCont)
                {
                    ApplicationArea = all;
                    Editable = falsE;
                }
            }
            repeater(General)
            {
                field(Tipo; Rec.Tipo)
                {
                    ApplicationArea = All;
                    LookupPageId = "Tipo contenedor";
                }
                field("Código"; Rec."Código")
                {
                    ApplicationArea = All;
                }
                /*
                field(dCantidad; dCantidad)
                {
                    ApplicationArea = all;
                    Editable = false;
                    visible = bDisponible;
                    Caption = 'Qty. in container', Comment = 'ESP="Cantidad disponible en contenedor"';
                }
                */
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field("Nº Albarán Compra"; Rec."Nº Albarán Compra")
                {
                    ApplicationArea = All;
                }
                field(Padre; Rec.Padre)
                {
                    ApplicationArea = All;
                    LookupPageId = 50300;
                    Editable = bEditable;
                }
                field("Almacén"; Rec."Almacén")
                {
                    ApplicationArea = All;
                }
                field(Zon; Rec.Zona)
                {
                    ApplicationArea = All;
                }
                field(Ubicacion; Rec.Ubicacion)
                {
                    ApplicationArea = All;
                }
                /*
                field(QtyOnContainer; Rec.QtyOnContainer)
                {
                    ApplicationArea = All;
                    Visible = bcantidad;
                }
                field(QtyOnFatherContainer; Rec.QtyOnFatherContainer)
                {
                    ApplicationArea = All;
                    Visible = bcantidad;
                }
                */
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(ImportaDetCont)
            {
                Caption = 'Import container detail';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportDatabase;

                trigger OnAction()
                var
                    rCRec: Record Contenedores;
                begin
                    CurrPage.SetSelectionFilter(rCRec);
                    if rcrec.Find('-') then
                        repeat
                            ImportarDetallePalet(rcrec);
                        until rcrec.next() = 0
                end;
            }

            action(ActualizarPadre)
            {
                Caption = 'Actualizar Padre';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ImportDatabase;

                trigger OnAction()
                var
                    rCont: Record Contenedores;
                    rContenido: Record "Contenido contenedor";
                    ddialog: Dialog;
                begin
                    ddialog.Open('Procesando contenedor #1#######');
                    rcont.reset;
                    CurrPage.SetSelectionFilter(rcont);
                    if rcont.Find('-') then
                        repeat
                            ddialog.Update(1, rCont."Código");
                            rContenido.reset;
                            rContenido.SetRange("Código", rCont."Código");
                            if rContenido.find('-') then
                                repeat
                                    rContenido.Padre := rCont.Padre;
                                    rContenido.Modify(false);
                                until rContenido.Next() = 0;
                        until rcont.next() = 0;
                    ddialog.Close();
                end;
            }
        }
        area(Navigation)
        {
            action(Contenido)
            {
                Caption = 'Content';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Entries;
                //RunObject = page Contenido;
                //RunPageLink = "Código" = field("Código");

                trigger OnAction()
                var
                    pCont: page "Contenido Cont.";
                    rCont: Record "Contenido contenedor";
                    rHijos: Record Contenedores;
                    tfiltro: text;
                    cHijo: code[20];
                begin
                    if Rec."Código" <> '' then begin
                        clear(pcont);
                        rcont.reset;
                        rcont.SetRange("Código", Rec."Código");
                        if rcont.FindSet() then begin
                            tfiltro := rec."Código";
                        end else begin
                            BuscarHijos(Rec."Código", tfiltro);
                        end;
                        rcont.reset;
                        if tfiltro = '' then
                            rcont.SetFilter("Código", rec."Código")
                        else
                            rcont.SetFilter("Código", tfiltro);
                        pcont.SetTableView(rcont);
                        //pcont.RunModal();
                        pcont.Run();
                    end;

                end;
            }
            action(Actualiza)
            {
                Caption = 'Actualizar documentos contenido';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Process;
                ApplicationArea = all;

                trigger OnAction()
                var
                    rContenido: Record "Contenido contenedor";
                    ddialog: Dialog;
                begin
                    ddialog.Open('Procesando IMEI: #1####');
                    rContenido.reset;
                    rContenido.SetRange(Vendido, false);
                    rContenido.SetRange(Endocumento, true);
                    if rContenido.find('-') then
                        repeat
                            ddialog.Update(1, rContenido.IMEI);
                            rContenido.VerificarDocumento();
                            rContenido.Modify(false);
                        until rContenido.Next() = 0;
                    ddialog.Close();
                    ;
                end;
            }
            /*action(MovContenido)
            {
                Caption = 'Content history';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Entries;
                RunObject = page "Mov. Cajas";
                RunPageLink = "Contenedor" = field("Código");
            }*/
        }
    }

    trigger OnOpenPage()
    begin
        if LookupMode then
            bCantidad := true
        else
            bcantidad := false;
    end;

    trigger OnAfterGetRecord()
    begin
        //CalcularCantidad();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        rTipo.Get(Rec.Tipo);
        beditable := rTipo."Admite nivel superior";
        dCantCont := 0;
        if bCantidad then
            if Rec.Tipo = 'PALE' then begin
                Rec.CalcFields(QtyOnFatherContainer);
                dCantCont := rec.QtyOnFatherContainer;
            end else begin
                Rec.CalcFields(QtyOnContainer);
                dCantCont := rec.QtyOnContainer;
            end;
    end;

    local procedure BuscarHijos(Cdigo: Code[20]; var tfiltro: Text)
    var
        rHijos: Record Contenedores;
        cHijo: code[20];
    begin
        rhijos.reset;
        rhijos.SetRange(padre, Cdigo);
        if rhijos.Find('-') then
            repeat
                if cHijo <> rHijos."Código" then begin
                    chijo := rhijos."Código";
                    if tfiltro = '' then
                        tfiltro := cHijo
                    else
                        tfiltro += '|' + chijo;
                end;
                BuscarHijos(rhijos."Código", tfiltro);
            until rhijos.Next() = 0;
    end;

    local procedure CalcularCantidad()
    var
        rContenido: record "Contenido contenedor";
        rConf: Record "Containers Setup";
    begin
        rcontenido.reset;
        rContenido.CalcFields("Cód Almacén");
        rContenido.SetRange("Cód Almacén", cAlmacen);
        rcontenido.SetRange("Nº producto", cProducto);
        rcontenido.SetFilter(PedVenta, '<>%1', cDocumento);
        rcontenido.SetFilter(LinPedVenta, '<>%1', iLinea);
        rContenido.SetRange(PedVenta, '');
        rContenido.SetRange(LinPedVenta, 0);
        rContenido.SetRange(RecepAlm, '');
        rContenido.SetRange(LinRecep, 0);
        //rContenido.SetRange(EnvioAlm, '');
        //rContenido.SetRange(LinEnvio, 0);
        rContenido.SetRange(PedTrans, '');
        rContenido.SetRange(LinPedTrans, 0);
        rContenido.SetRange("Libro registro productos", '');
        rContenido.SetRange("Sección registro productos", '');
        rContenido.SetRange(LinDiario, 0);
        rconf.get;
        case rec.tipo of
            rconf."Tipo caja":
                begin
                    rContenido.setrange("Código", Rec."Código");
                    if rContenido.findset then
                        if rContenido.CalcSums(Cantidad) then
                            dCantidad := rContenido.Cantidad;
                end;
            rconf."Tipo pallet":
                begin
                    rContenido.setrange(Padre, Rec."Código");
                    if rContenido.findset then
                        if rContenido.CalcSums(Cantidad) then
                            dCantidad := rContenido.Cantidad;
                end;
        end;
    end;

    trigger OnInit()
    begin
        bDisponible := falsE;
    end;

    procedure EstablecerFiltrosSeleccion(cAlm: code[20]; cProd: code[20]; cDoc: code[20]; iLin: Integer)
    begin
        bDisponible := true;
        cAlmacen := calm;
        cProducto := cprod;
        cDocumento := cdoc;
        ilinea := ilin;
    end;

    procedure EstablecerFiltrosSeleccionDiario(cAlm: code[20]; cProd: code[20]; cDoc: code[20]; cSecc: code[20]; iLin: integer)
    begin
        bDisponible := true;
        cAlmacen := calm;
        cProducto := cprod;
        cDocumento := cdoc;
        cSeccion := cSecc;
        ilinea := ilin;
    end;


    //Procedimiento para cargar hijos y detalle desde los datos de detalle palet.
    procedure ImportarDetallePalet(var rContOrg: Record Contenedores)
    var
        rDetallPal: Record AzmHFBreakdownPallet;
        //rProdUdMedPal, rProdUdMedCaja : Record "Item Unit of Measure";
        rProd: Record item;
        dCantPallet, dCantCaja : Decimal;
        rContenedor: Record Contenedores;
        rContSetup: Record "Containers Setup";
        rContCont: Record "Contenido contenedor";
    begin
        rContSetup.Get();
        if rContSetup."Tipo pallet" = rContOrg.Tipo then begin
            rDetallPal.reset();
            rDetallPal.SetRange(PalletNo, rContOrg."Código");
            rDetallPal.SetRange("Contenedor generado", false);
            if rDetallPal.Find('-') then begin
                if rContOrg."Almacén" = '' Then
                    rContOrg.validate("Almacén", rDetallPal.LocationCode);
                repeat
                    //Creamos los contenedores hijo de los pallets si fuese necesario
                    rContenedor.reset;
                    if not rContenedor.get(rDetallPal.BoxNo) then begin
                        rContenedor.Init();
                        rcontenedor.Validate(tipo, rContSetup."Tipo caja");
                        rContenedor.Padre := rContOrg."Código";
                        rContenedor.Validate("Código", rDetallPal.BoxNo);
                        rContenedor.validate("Almacén", rContOrg."Almacén");
                        rContenedor.Insert();
                        cCont.ValidaPadreContenido(rContenedor."Código", rContenedor.padre);
                        commit;
                    end;
                    //Insertamos el contenido del contenedor si fuese necesario
                    rContCont.reset;
                    rContCont.SetRange("Código", rDetallPal.BoxNo);
                    rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                    rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                    if not rContCont.find('-') then begin
                        rContCont.init;
                        rContCont.Validate("Código", rDetallPal.BoxNo);
                        rContCont.Validate("Nº producto", rdetallpal.ItemNo);
                        rContCont.Validate(Cantidad, 1);
                        rProd.get(rdetallpal.ItemNo);
                        rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                        rContCont.Validate(IMEI, rdetallpal.UnitNo);
                        rContCont.Validate(Caducidad, rdetallpal."Expiration Date");
                        //rContCont.Validate("Cód. Almacén", rContOrg."Almacén");
                        rcontcont.Insert();
                    end;
                    rDetallPal."Contenedor generado" := true;
                    rDetallPal.Modify(false);
                until rDetallPal.Next() = 0;
            end;
        end;
        if rContSetup."Tipo caja" = rContOrg.Tipo then begin
            rDetallPal.reset();
            rDetallPal.SetRange(BoxNo, rContOrg."Código");
            rDetallPal.SetRange("Contenedor generado", false);
            if rDetallPal.Find('-') then begin
                if rContOrg."Almacén" = '' Then
                    rContOrg.validate("Almacén", rDetallPal.LocationCode);
                repeat
                    //Insertamos el contenido del contenedor si fuese necesario
                    rContCont.reset;
                    rContCont.SetRange("Código", rDetallPal.BoxNo);
                    rContCont.SetRange("Nº producto", rDetallPal.ItemNo);
                    rContCont.SetRange(IMEI, rDetallPal.UnitNo);
                    if not rContCont.find('-') then begin
                        rContCont.init;
                        rContCont.Validate("Código", rDetallPal.BoxNo);
                        rContCont.Validate("Nº producto", rdetallpal.ItemNo);
                        rContCont.Validate(Cantidad, 1);
                        rProd.get(rdetallpal.ItemNo);
                        rContCont.Validate("Unidad de medida", rprod."Base Unit of Measure");
                        rContCont.Validate(IMEI, rdetallpal.UnitNo);
                        rContCont.Validate(Caducidad, rdetallpal."Expiration Date");
                        //rContCont.Validate("Cód. Almacén", rContOrg."Almacén");
                        rcontcont.Insert();
                    end;
                    rDetallPal."Contenedor generado" := true;
                    rDetallPal.Modify(false);
                until rDetallPal.Next() = 0;
            end;
        end;
    end;

    var
        rTipo: Record "Tipo contenedor";
        bEditable: Boolean;
        bCantidad: Boolean;
        dCantidad: Decimal;
        bDisponible: Boolean;
        cAlmacen, cProducto, cDocumento, cSeccion : code[20];
        iLinea: Integer;
        cCont: Codeunit Contenedores;
        dCantCont: Decimal;
}
