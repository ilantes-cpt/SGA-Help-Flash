pageextension 50309 "Sales Order Ext." extends "Sales Order"
{
    layout
    {
        addafter(SalesLines)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = SalesLines;
                SubPageLink = PedVenta = field("Document No."), LinPedVenta = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
