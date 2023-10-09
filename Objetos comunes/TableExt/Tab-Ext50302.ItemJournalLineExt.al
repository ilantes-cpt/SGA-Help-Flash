tableextension 50302 "Item Journal Line Ext" extends "Item Journal Line"
{
    fields
    {
        field(50300; Contenedor; Code[20])
        {
            Caption = 'Container';
            DataClassification = ToBeClassified;
            TableRelation = Contenedores;
        }
    }
}
