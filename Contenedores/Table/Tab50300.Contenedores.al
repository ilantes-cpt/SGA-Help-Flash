table 50300 Contenedores
{
    Caption = 'Containers';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Código"; Code[20])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                //Comprobamos si, el tipo, tiene nº de serie y/o se puede introducir de forma manual
                rtipo.Get(tipo);
                if rTipo."Nº Serie" <> '' then begin
                    if "Código" <> '' then begin
                        cNoSeries.TestManual(rTipo."Nº Serie");
                    end else begin
                        validate("código", cNoSeries.TryGetNextNo(rTipo."Nº Serie", workdate));
                    end;
                end else
                    TestField("Código");

            end;
        }
        field(2; "Descripción"; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(3; "Almacén"; Code[20])
        {
            Caption = 'Warehouse';
            DataClassification = ToBeClassified;
            TableRelation = Location.Code;
            ValidateTableRelation = false;
        }
        field(4; Ubicacion; Code[20])
        {
            Caption = 'Bin';
            DataClassification = ToBeClassified;
            TableRelation = bin.Code where("Zone Code" = field(Zona), "Location Code" = field("Almacén"));
            //TableRelation = bin.Code where("Zone Code" = field(Zona));
            ValidateTableRelation = false;
        }
        field(5; Tipo; Code[20])
        {
            Caption = 'Type';
            DataClassification = ToBeClassified;
            TableRelation = "Tipo contenedor".Tipo;
        }
        field(6; Padre; Code[20])
        {
            //Nivel superior
            Caption = 'Father';
            DataClassification = ToBeClassified;
            TableRelation = Contenedores."Código";

            trigger OnValidate()
            var
                cContenedores: Codeunit Contenedores;
            begin
                IF NOT Rec.Insert() THEN Rec.Modify();
                if Rec."Código" = Rec.Padre then
                    error(lErrNoSeleccionable);
                if not cContenedores.VerificarAsignacionContenedor(Rec."Código", Rec.Padre) then
                    Error(lErr006);
            end;
        }
        field(7; Huecos; Integer)
        {
            Caption = 'Gaps';
            DataClassification = ToBeClassified;
        }
        field(8; Zona; Code[20])
        {
            Caption = 'Zone';
            DataClassification = ToBeClassified;
            TableRelation = Zone.Code where("Location Code" = field("Almacén"));
            ValidateTableRelation = false;
        }
    }
    keys
    {
        key(PK; "Código")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        cContenedores: Codeunit Contenedores;
    begin
        //VerificarUbicacion(true);
    end;

    trigger OnModify()
    begin
        //VerificarUbicacion(true);
    end;

    trigger OnDelete()
    begin
        //VerificarUbicacion(false);
    end;

    trigger OnRename()
    begin
        error(lErrRen);
    end;

    /*procedure VerificarUbicacion(bInsertar: Boolean)
    begin
        if bInsertar then begin
            if not rBin.get(Rec."Almacén", Rec."Código") then
                if rtipo.get(Rec.Tipo) then
                    CrearUbicacion(rTipo.DefaultLocation);
        end else begin
            if rbin.get(Rec."Almacén", Rec."Código") then
                rbin.Delete();
        end;
    end;

    procedure CrearUbicacion(cAlm: code[20])
    begin
        rtipo.get(Rec.Tipo);
        if not rtipo.CreateAsBin then
            exit;
        rloc.get(cAlm);
        rbin.Init();
        rbin.validate("Location Code", cAlm);
        rbin.Validate(Code, rec."Código");
        rbin.Validate("Zone Code", rloc.BufferZone);
        rbin.Validate(Description, 'Buffer ' + rec."Código");
        if not rbin.Insert() then rbin.Modify();
    end;*/

    var
        cNoSeries: Codeunit NoSeriesManagement;
        rTipo: Record "Tipo contenedor";
        rBin: Record bin;
        rLoc: Record Location;
        lErrRen: Label 'Cannot rename a container';
        lErrNoSeleccionable: label 'The same container cannot be selected as a parent';
        lErr006: label 'This type of combination it''s not allowed';
}
