pageextension 50300 "Item Card Ext." extends "Item Card"
{
    layout
    {
        addafter("Item Category Code")
        {
            field("Gestión de contenedores"; Rec."Gestión de contenedores")
            {
                ApplicationArea = all;
            }
            /*field("Baja producto asociado"; Rec."Baja producto asociado")
            {
                ApplicationArea = all;
            }
            field("Código producto asociado"; Rec."Código producto asociado")
            {
                ApplicationArea = all;
            }*/
            field("Gestión de IMSIs"; Rec."Gestión de IMSIs")
            {
                ApplicationArea = all;
            }
            field("Fecha caducidad"; Rec."Fecha caducidad")
            {
                ApplicationArea = all;
            }
        }
    }
}
