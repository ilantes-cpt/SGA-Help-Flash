permissionset 50300 SGAHELPFLASH
{
    Assignable = true;
    Permissions = tabledata "Containers Setup" = RIMD,
        tabledata Contenedores = RIMD,
        tabledata "Contenido contenedor" = RIMD,
        tabledata "Selector Contenedores" = RIMD,
        tabledata "Tipo contenedor" = RIMD,
        table "Containers Setup" = X,
        table Contenedores = X,
        table "Contenido contenedor" = X,
        table "Selector Contenedores" = X,
        table "Tipo contenedor" = X,
        codeunit Contenedores = X,
        page "Containers Setup" = X,
        page "Contenido Cont." = X,
        page "Contenido contenedor" = X,
        page "Lista contenedores" = X,
        page "Sel. Contenido Contenedor" = X,
        page "Tipo contenedor" = X;
}