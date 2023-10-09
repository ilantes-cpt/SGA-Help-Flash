page 50300 "Lista contenedores"
{
    ApplicationArea = All;
    Caption = 'Container list';
    PageType = List;
    SourceTable = Contenedores;
    UsageCategory = Lists;
    DelayedInsert = true;
    PromotedActionCategories = 'New,Process,Report,Navigate';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Tipo; Rec.Tipo)
                {
                    ApplicationArea = All;
                    LookupPageId = "Tipo contenedor";
                }
                field("Código"; Rec."Código")
                {
                    ApplicationArea = All;
                }
                field("Descripción"; Rec."Descripción")
                {
                    ApplicationArea = All;
                }
                field(Huecos; Rec.Huecos)
                {
                    ApplicationArea = All;
                }
                field(Padre; Rec.Padre)
                {
                    ApplicationArea = All;
                    LookupPageId = 50300;
                    Editable = bEditable;
                }
                field("Almacén"; Rec."Almacén")
                {
                    ApplicationArea = All;
                }
                field(Zon; Rec.Zona)
                {
                    ApplicationArea = All;
                }
                field(Ubicacion; Rec.Ubicacion)
                {
                    ApplicationArea = All;
                }
            }
        }

    }

    actions
    {
        area(Navigation)
        {
            action(Contenido)
            {
                Caption = 'Content';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Entries;
                //RunObject = page Contenido;
                //RunPageLink = "Código" = field("Código");

                trigger OnAction()
                var
                    pCont: page Contenido;
                    rCont: Record "Contenido contenedor";
                    rHijos: Record Contenedores;
                    tfiltro: text;
                    cHijo: code[20];
                begin
                    clear(pcont);
                    rcont.reset;
                    rcont.SetRange("Código", Rec."Código");
                    if rcont.FindSet() then begin
                        tfiltro := rec."Código";
                    end else begin
                        BuscarHijos(Rec."Código", tfiltro);
                    end;
                    rcont.reset;
                    rcont.SetFilter("Código", tfiltro);
                    pcont.SetTableView(rcont);
                    pcont.RunModal();
                end;
            }
            /*action(MovContenido)
            {
                Caption = 'Content history';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Entries;
                RunObject = page "Mov. Cajas";
                RunPageLink = "Contenedor" = field("Código");
            }*/
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        rTipo.Get(Rec.Tipo);
        beditable := rTipo."Admite nivel superior";
    end;

    local procedure BuscarHijos(Cdigo: Code[20]; var tfiltro: Text)
    var
        rHijos: Record Contenedores;
        cHijo: code[20];
    begin
        rhijos.reset;
        rhijos.SetRange(padre, Cdigo);
        if rhijos.Find('-') then
            repeat
                if cHijo <> rHijos."Código" then begin
                    chijo := rhijos."Código";
                    if tfiltro = '' then
                        tfiltro := cHijo
                    else
                        tfiltro += '|' + chijo;
                end;
                BuscarHijos(rhijos."Código", tfiltro);
            until rhijos.Next() = 0;
    end;

    var
        rTipo: Record "Tipo contenedor";
        bEditable: Boolean;
}
