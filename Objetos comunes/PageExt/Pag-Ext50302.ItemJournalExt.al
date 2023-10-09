pageextension 50302 "Item Journal Ext" extends "Item Journal"
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
