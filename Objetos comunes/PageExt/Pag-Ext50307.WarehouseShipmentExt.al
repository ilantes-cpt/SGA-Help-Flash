pageextension 50307 "Warehouse Shipment Ext." extends "Warehouse Shipment"
{
    layout
    {
        addafter(WhseShptLines)
        {
            part(LoteIMEI; "IMEI x Lotes")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = WhseShptLines;
                SubPageLink = "Nº pedido" = field("Source No."), "Nº Linea pedido" = field("Source Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
