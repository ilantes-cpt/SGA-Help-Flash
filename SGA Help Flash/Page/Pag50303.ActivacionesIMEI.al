page 50303 "Activaciones IMEI"
{
    ApplicationArea = All;
    Caption = 'IMEI Activations';
    PageType = List;
    SourceTable = "Activaciones IMEI";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(IMEI; Rec.IMEI)
                {
                }
                field("Fecha activación"; Rec."Fecha activación")
                {
                }
                field(Coste; Rec.Coste)
                {
                }
                field("Fecha caducidad"; Rec."Fecha caducidad")
                {
                }
                field("Fecha venta"; Rec."Fecha venta")
                {
                }
                field(Venta; Rec.Venta)
                {
                }
            }
        }
    }
}
