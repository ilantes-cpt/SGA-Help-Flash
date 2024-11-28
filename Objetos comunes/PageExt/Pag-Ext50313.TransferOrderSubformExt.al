pageextension 50313 "Transfer Order Subform Ext" extends "Transfer Order Subform"
{
    actions
    {
        addlast("&Line")
        {
            action(AsignaContLantes)
            {
                ApplicationArea = All;
                Enabled = bEnabled;
                Caption = 'Asign Container', comment = '="Asignar contenedor"';
                Image = SelectLineToApply;

                trigger OnAction()
                var
                    pSel: page "Sel. Contenido Contenedor";
                    dCant: Decimal;
                begin
                    clear(psel);
                    //if Rec."Qty. Shipped (Base)" <> 0 then begin
                    //dCant := Rec."Qty. Shipped (Base)" + Rec."Qty. to Ship (Base)";
                    psel.EstablecerDocnew('PTRANS', Rec."Document No.", rec."Line No.", Rec."Qty. Shipped (Base)" + Rec."Qty. to Ship (Base)", rec."Transfer-from Code", Rec."Item No.", '', '', FALSE);
                    //end else
                    //psel.EstablecerDoc(Rec."Document No.", rec."Line No.", rec."Qty. to Ship (Base)", rec."Location Code", Rec."No.");
                    psel.RunModal();
                    CurrPage.Update(true);
                end;
            }
            /*action(AsignarCont)
            {
                ApplicationArea = All;
                Caption = 'Asign Container', comment = '="Asignar contenedor"';
                Image = SelectLineToApply;

                trigger OnAction()
                var
                    lErr001: Label 'Pallet %1 which has %2 units should have %3 units according to the quantity indicated on the transfer order line.', comment = 'ESP="El palet %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del pedido de transferencia."';
                    lErr002: Label 'Box %1 which has %2 units should have %3 units according to the quantity indicated on the transfer order line.', comment = 'ESP="La caja %1 que cuenta con %2 uds. debería tener %3 uds. según la cantidad indicada en la línea del pedido de transferencia."';
                    rContenedor: Record Contenedores;
                    rContSetup: Record "Containers Setup";
                    rContCont: Record "Contenido contenedor";
                    pContCont: Page "Contenido Cont.";
                    dCant, dCant2 : Integer;
                    rTransferHead: Record "Transfer Header";
                begin
                    dCant := 0;
                    if Rec."Qty. to Ship" = Rec.Quantity then
                        dCant := 0
                    else
                        dCant := Rec."Qty. to Ship";
                    rContSetup.Get();
                    pContCont.LookupMode(true);
                    rContCont.Reset();
                    rContCont.FilterGroup(2);
                    rContCont.SetRange(PedVenta, '');
                    rContCont.SetRange(LinPedVenta, 0);
                    rContCont.SetRange(PedTrans, '');
                    rContCont.SetRange(LinPedTrans, 0);
                    rContCont.SetRange("Nº producto", Rec."Item No.");
                    //rTransferHead.Get(Rec."Document No.");
                    rContCont.SetRange("Cód. Almacén", Rec."Transfer-from Code");
                    rContCont.FilterGroup(0);
                    pContCont.SetTableView(rContCont);
                    if pContCont.RunModal() = ACTION::LookupOK then begin
                        pContCont.SetSelectionFilter(rContCont);
                        pContCont.GetRecord(rContCont);
                        if rContCont.FindSet() then
                            repeat
                                if rContSetup."Comprobación pallets/cajas" then begin
                                    if rContenedor.Get(rContCont."Código") then begin
                                        if rContSetup."Tipo pallet" = rContenedor.Tipo then begin
                                            if rContCont.Count > Rec."Qty. to Ship" then begin
                                                error(lErr002, rContCont."Código", rContCont.Count, Rec."Qty. to Ship");
                                            end else begin
                                                dCant += rContCont.Cantidad;
                                                rContCont.Validate(PedTrans, Rec."Document No.");
                                                rContCont.Validate(LinPedTrans, Rec."Line No.");
                                                rContCont.Modify(true);
                                            end;
                                        end else begin
                                            if rContSetup."Tipo caja" = rContenedor.Tipo then begin
                                                if rContCont.Count > Rec."Qty. to Ship" then begin
                                                    error(lErr002, rContCont."Código", rContCont.Count, Rec."Qty. to Ship");
                                                end else begin
                                                    dCant += rContCont.Cantidad;
                                                    rContCont.Validate(PedTrans, Rec."Document No.");
                                                    rContCont.Validate(LinPedTrans, Rec."Line No.");
                                                    rContCont.Modify(true);
                                                end;
                                            end;
                                        end;
                                    end;
                                end;
                            until rContCont.Next() = 0;
                        Rec.Validate("Qty. to Ship", dCant);
                        Rec.Modify(true);
                    end;
                end;
            }*/
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Completely Shipped" then
            bEnabled := false
        else
            bEnabled := true;
    end;

    var
        bEnabled: Boolean;
}
