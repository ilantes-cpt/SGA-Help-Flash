tableextension 50306 "Warehouse Setup Ext" extends "Warehouse Setup"
{
    fields
    {
        field(53000; ReclasJT; code[10])
        {
            Caption = 'Reclasification Journal Template';
            DataClassification = ToBeClassified;
            TableRelation = "Warehouse Journal Template".Name;
        }
        field(53001; ReclasJB; code[20])
        {
            Caption = 'Reclasification Journal Template';
            DataClassification = ToBeClassified;
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = field(ReclasJT));
        }
    }
}
