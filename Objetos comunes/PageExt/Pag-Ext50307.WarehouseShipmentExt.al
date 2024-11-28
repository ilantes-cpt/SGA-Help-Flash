pageextension 50307 "Warehouse Shipment Ext." extends "Warehouse Shipment"
{
    layout
    {
        addafter(WhseShptLines)
        {
            part(Contenedores; "Contenido contenedor")
            {
                ApplicationArea = Basic, Suite;
                Visible = true;
                Editable = false;
                Provider = WhseShptLines;
                //SubPageLink = EnvioAlm = field("No."), LinEnvio = field("Line No.");
                SubPageLink = EnvioAlm = field("Source No."), LinEnvio = field("Source Line No.");
                UpdatePropagation = Both;
            }
        }
    }
}
