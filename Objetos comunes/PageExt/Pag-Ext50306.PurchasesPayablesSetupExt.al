pageextension 50306 "Purchases & Payables Setup Ext" extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Default Accounts")
        {
            group("Tipo de producto paquetes de datos")
            {
                Caption = 'Item Type Data Packages';

                field(ConsumirPaquetes; Rec.ConsumirPaquetes)
                {
                    ApplicationArea = all;
                }
            }

        }
    }
}