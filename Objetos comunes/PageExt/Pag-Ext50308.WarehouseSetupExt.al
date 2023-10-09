pageextension 50308 "Warehouse Setup Ext" extends "Warehouse Setup"
{
    layout
    {
        addlast(content)
        {
            group(ReclasJournal)
            {
                Caption = 'Reclasification Journal';
                field(ReclasJT; Rec.ReclasJT)
                {
                    ApplicationArea = all;
                }
                field(ReclasJB; Rec.ReclasJB)
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}
