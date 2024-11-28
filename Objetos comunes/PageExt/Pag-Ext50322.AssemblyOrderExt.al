pageextension 50322 "Assembly Order Ext" extends "Assembly Order"
{
    layout
    {

        moveafter("Quantity to Assemble"; "Location Code")


        addafter(Lines)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = Lines;
                SubPageLink = "Nº pedido ensamblado" = field("Document No."), "Nº linea pedido ensamblado" = field("Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
