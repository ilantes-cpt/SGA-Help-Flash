page 50305 "Contenido contenedor"
{
    ApplicationArea = Basic, Suite;
    //ApplicationArea = all;
    Caption = 'Container Content';
    PageType = ListPart;
    SourceTable = "Contenido contenedor";
    Editable = false;

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
                field("Nº Albarán Compra"; Rec."Nº Albarán Compra")
                {
                }
                field(PedVenta; Rec.PedVenta)
                {
                }
                field(LinPedVenta; Rec.LinPedVenta)
                {
                }
                field("Nº pedido ensamblado"; Rec."Nº pedido ensamblado")
                {
                    ApplicationArea = All;
                }
                field("Nº linea pedido ensamblado"; Rec."Nº linea pedido ensamblado")
                {
                    ApplicationArea = All;
                }
                field(Vendido; Rec.Vendido)
                {
                }
                field("Nº albarán venta"; Rec."Nº albarán venta")
                {
                }
                field("Cód Almacén"; Rec."Cód Almacén")
                {
                }
                field(PedTrans; Rec.PedTrans)
                {
                }
                field(LinPedTrans; Rec.LinPedTrans)
                {
                }
                field(EnvioAlm; Rec.EnvioAlm)
                {
                }
                field(LinEnvio; Rec.LinEnvio)
                {
                }
                field(RecepAlm; Rec.RecepAlm)
                {
                }
                field(LinRecep; Rec.LinRecep)
                {
                }
                field("Libro registro productos"; Rec."Libro registro productos")
                {
                    ApplicationArea = all;
                }
                field("Sección registro productos"; Rec."Sección registro productos")
                {
                    ApplicationArea = all;
                }
                field(LinDiario; Rec.LinDiario)
                {
                }
                field(PedCompra; Rec.PedCompra)
                {
                }
                field(LinPedCompra; Rec.LinPedCompra)
                {
                }
                field("Nº abono venta"; Rec."Nº abono venta")
                {
                    ApplicationArea = All;
                }
                field("Nº linea abono venta"; Rec."Nº linea abono venta")
                {
                    ApplicationArea = All;
                }


            }
        }
    }
}
