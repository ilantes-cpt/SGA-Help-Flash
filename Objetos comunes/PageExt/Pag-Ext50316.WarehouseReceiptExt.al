pageextension 50316 "Warehouse Receipt Ext." extends "Warehouse Receipt"
{
    layout
    {
        addafter(WhseReceiptLines)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = WhseReceiptLines;
                SubPageLink = RecepAlm = field("No."), LinRecep = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
