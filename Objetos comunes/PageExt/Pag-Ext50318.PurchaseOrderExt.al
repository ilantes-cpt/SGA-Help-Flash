pageextension 50318 "Purchase Order Ext" extends "Purchase Order"
{
    layout
    {
        addafter(PurchLines)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = PurchLines;
                SubPageLink = PedCompra = field("Document No."), LinPedCompra = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
