tableextension 50308 "Location Ext." extends Location
{
    fields
    {
        field(50300; "Contenedor devoluciones"; Code[20])
        {
            Caption = 'Returns Container';
            DataClassification = ToBeClassified;
            TableRelation = Contenedores;
        }
    }
}
