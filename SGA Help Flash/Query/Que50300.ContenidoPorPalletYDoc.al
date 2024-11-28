query 50300 ContenidoPorPalletYDoc
{
    Caption = 'Contenido Por Pallet Y Doc';
    QueryType = Normal;

    elements
    {
        dataitem(FiltroCC; "Contenido contenedor")
        {
            filter(CodAlmacen; "Cód Almacén")
            {
            }
            filter(PedVenta; PedVenta)
            {
            }
            filter(LinPedVenta; LinPedVenta)
            {
            }
            filter(PedTrans; PedTrans)
            {
            }
            filter(LinPedTrans; LinPedTrans)
            {
            }
            filter(PedCompra; PedCompra)
            {
            }
            filter(LinPedCompra; LinPedCompra)
            {
            }
            filter(RecepAlm; RecepAlm)
            {
            }
            filter(LinRecep; LinRecep)
            {
            }
            filter(EnvioAlm; EnvioAlm)
            {
            }
            filter(LinEnvio; LinEnvio)
            {
            }
            filter(LibroRegistroProductos; "Libro registro productos")
            {
            }
            filter(SeccionRegistroProductos; "Sección registro productos")
            {
            }
            filter(LinDiario; LinDiario)
            {
            }
            filter(Nproducto; "Nº producto")
            {
            }
            filter(NAlbaranCompra; "Nº Albarán Compra")
            {
            }
            filter(Nalbaranventa; "Nº albarán venta")
            {
            }
            filter(Vendido; Vendido)
            {
            }
            filter(Npedidoensamblado; "Nº pedido ensamblado")
            {
            }
            filter(Nlineapedidoensamblado;"Nº linea pedido ensamblado")
            {
            }
            column(Padre; Padre)
            {
            }
            column(CantidadPadre; Cantidad)
            {
                ColumnFilter = CantidadPadre = filter(<> 0);
                Method = Sum;
            }
        }
    }
}

