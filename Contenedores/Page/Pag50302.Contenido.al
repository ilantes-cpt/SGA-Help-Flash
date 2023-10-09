page 50302 Contenido
{
    Caption = 'Content';
    PageType = List;
    SourceTable = "Contenido contenedor";
    //UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Código"; Rec."Código")
                {
                }
                field("Nº producto"; Rec."Nº producto")
                {
                }
                field(Cantidad; Rec.Cantidad)
                {
                }
                field("Unidad de medida"; Rec."Unidad de medida")
                {
                }
                field(IMEI; Rec.IMEI)
                {
                }
                field(Caducidad; Rec.Caducidad)
                {
                }
                field(Padre; Rec.Padre)
                {
                }
            }
        }
    }
}
