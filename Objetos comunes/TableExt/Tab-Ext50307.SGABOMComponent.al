tableextension 50307 "SGA BOM Component" extends "BOM Component"
{
    fields
    {
        field(50300; "Consumption Location"; Code[20])
        {
            Caption = 'Consumption Location';
            DataClassification = ToBeClassified;
            TableRelation = location.Code WHERE("Use As In-Transit" = const(false));
        }
    }
}
