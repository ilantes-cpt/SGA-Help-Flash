pageextension 50320 "Posted Purchase Receipt Ext" extends "Posted Purchase Receipt"
{
    layout
    {
        addafter(PurchReceiptLines)
        {
            part(ContenidoContenedor; "Contenido contenedor")
            {
                ApplicationArea = basic, suite;
                Visible = true;
                Editable = false;
                Provider = PurchReceiptLines;
                SubPageLink = "Nº Albarán Compra" = field("Document No."), PedCompra = field("Order No."), LinPedCompra = field("Order Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
