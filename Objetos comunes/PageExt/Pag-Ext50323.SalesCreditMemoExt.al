pageextension 50323 "Sales Credit Memo Ext" extends "Sales Credit Memo"
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
                SubPageLink = "Nº abono venta" = field("Document No."), "Nº linea abono venta" = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
