pageextension 50309 "Sales Order Ext." extends "Sales Order"
{
    layout
    {
        addafter(SalesLines)
        {
            /*part(Contenedores; "Lista contenedores")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "Nº pedido" = field("Document No."), "Nº Linea pedido" = field("Line No.");
                UpdatePropagation = Both;
            }*/
        }
    }
}
