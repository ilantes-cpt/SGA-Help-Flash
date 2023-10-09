pageextension 50301 "Item Ledger Entries Ext" extends "Item Ledger Entries"
{
    layout
    {
        addafter(Description)
        {
            field(Contenedor; Rec.Contenedor)
            {
                ApplicationArea = all;
            }
        }
    }
}
