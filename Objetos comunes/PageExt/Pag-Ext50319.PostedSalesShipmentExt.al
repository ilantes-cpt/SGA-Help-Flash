pageextension 50319 "Posted Sales Shipment Ext." extends "Posted Sales Shipment"
{
    layout
    {
        addafter(SalesShipmLines)
        {
            part(ContenidoContenedor; "Contenido contenedor")
            {
                ApplicationArea = basic, suite;
                Visible = true;
                Editable = false;
                Provider = SalesShipmLines;
                SubPageLink = PedVenta = field("Order No."), LinPedVenta = field("Order Line No."), "Nº albarán venta" = field("Document No.");
                UpdatePropagation = Both;
            }
        }
    }
}
