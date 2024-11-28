pageextension 50312 "Transfer Order Ext." extends "Transfer Order"
{
    layout
    {
        addafter(TransferLines)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = TransferLines;
                SubPageLink = PedTrans = field("Document No."), LinPedTrans = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
