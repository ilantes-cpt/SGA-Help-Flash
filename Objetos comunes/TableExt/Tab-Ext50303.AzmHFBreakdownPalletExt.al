tableextension 50303 "AzmHFBreakdownPallet Ext" extends AzmHFBreakdownPallet
{
    fields
    {
        field(50300; "Unidad medida palet"; Code[20])
        {
            Caption = 'Palet Unit of Measure';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
            ObsoleteState = Removed;
            ObsoleteReason = 'No es necesario';
            ObsoleteTag = '20230925';
        }
        field(50301; "Unidad medida caja"; Code[20])
        {
            Caption = 'Box Unit of Measure';
            DataClassification = ToBeClassified;
            TableRelation = "Unit of Measure";
            ObsoleteState = Removed;
            ObsoleteReason = 'No es necesario';
            ObsoleteTag = '20230925';
        }
        field(50302; "Contenedor generado"; Boolean)
        {
            Caption = 'Box created';
            DataClassification = ToBeClassified;
            InitValue = false;
        }
        field(50303; "Nº pedido IMSI"; Code[20])
        {
            Caption = 'Order No. IMSI';
            DataClassification = ToBeClassified;
        }
    }

    trigger OnInsert()
    begin
        //Rec.Validate("Unidad medida palet", 'PALLET1200');
        //Rec.Validate("Unidad medida caja", 'CAJA30');
    end;

    /*trigger OnAfterInsert()
    var
        cContenedores: Codeunit Contenedores;
    begin
        cContenedores.ComprobCantDetallPalet(Rec.EntryNo);
    end;*/
}
