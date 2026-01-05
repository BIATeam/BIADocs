---
sidebar_position: 22
---

# es - Funcionalidad de Importación
La funcionalidad de importación de datos permite añadir, actualizar y/o eliminar datos en masa en la pantalla correspondiente.
Los ejemplos siguientes utilizan **Aviones** como datos de referencia.

## Comencemos exportando
Antes de importar datos en masa, puede ser útil recuperar el archivo completo de la lista de datos actual.
Para realizar una exportación y mantener el vínculo entre los datos contenidos en la aplicación y los datos del archivo exportado, se debe añadir una columna *Id* (identificador) al archivo exportado.
Para ello, hay disponible un botón específico en el menú situado en la parte superior derecha de la lista de datos:
![ExporterPourImport](../../Images/Tuto/Import/ExportForImportButtonEs.png)

El archivo descargado puede abrirse posteriormente en Excel y sirve como base para añadir, modificar o eliminar información.
![ExportExcel](../../Images/Tuto/Import/ExportExcel.png)

## Importar datos
### Añadir nuevos datos
Para añadir una nueva fila de datos (en este ejemplo: una nueva aeronave), basta con añadir una nueva fila en la lista de datos de Excel sin introducir ningún valor en la primera columna (id).
![NewLine](../../Images/Tuto/Import/NewLine.png)

### Modificar datos
Para modificar una fila de datos existente, simplemente edite los datos de la fila en Excel manteniendo el id en la primera columna.

### Eliminar datos
Para eliminar una fila de datos existente, puede eliminar la fila del archivo Excel.
*Si desea eliminar una fila y crear una nueva similar, también puede eliminar el identificador de la primera columna y modificar las columnas que desee. La ausencia del id hará que la fila se considere eliminada y se realizará una nueva inserción al detectar la fila sin identificador.*

### Importar el archivo Excel
Una vez finalizadas las modificaciones, puede guardar el archivo Excel (como archivo .csv) y volver a importarlo en la aplicación.
Para ello, haga clic en el botón de importación en el menú situado en la parte superior derecha de la lista de datos:
![Importer](../../Images/Tuto/Import/ImportButtonEs.png)

La ventana de importación se abrirá y le pedirá que introduzca cierta información:
1) el archivo que contiene los datos a importar  
2) el formato de fecha utilizado en Excel (día/mes/año, mes/día/año o día.mes.año)  
3) el formato de hora utilizado en Excel  
4) una opción para aplicar la importación solo a los datos actualmente filtrados en la pantalla  

Una vez introducida esta información, haga clic en **Analizar** para leer el archivo y verificar la coherencia de los datos.

Dependiendo de la pantalla, algunas funcionalidades pueden no estar disponibles (añadir, modificar o eliminar).

#### Añadir
Si la funcionalidad de agregar está activada, las nuevas filas del archivo Excel aparecerán en la sección **Para Agregar**.
Esta lista contiene un resumen de todas las nuevas filas (identificador vacío) detectadas y válidas en el archivo Excel.

Si está satisfecho con los datos detectados, puede marcar la casilla situada junto a **Para Agregar** para tener en cuenta estas adiciones al guardar.
![AAjouter](../../Images/Tuto/Import/ToAddEs.png)

#### Modificar
Si la funcionalidad de modificación está activada, las filas modificadas del archivo Excel aparecerán en la sección **Para Modificar**.
Esta lista contiene un resumen de todas las filas modificadas detectadas y válidas en el archivo Excel.

Si está satisfecho con los datos detectados, puede marcar la casilla situada junto a **Para Modificar** para tener en cuenta estas modificaciones al guardar.

#### Eliminar
Si la funcionalidad de eliminación está activada, las filas eliminadas del archivo Excel aparecerán en la sección **Para Eliminar**.
Esta lista contiene un resumen de todas las filas eliminadas detectadas en el archivo Excel.

Si está satisfecho con los datos detectados, puede marcar la casilla situada junto a **Para Eliminar** para tener en cuenta estas eliminaciones al guardar.

#### Tratamiento de errores
Si se detectan errores en los datos del archivo Excel, la lista de estos errores se mostrará en la sección **Error(es)**.
La información sobre el/los error(es) detectados para cada fila está disponible en la última columna de la tabla (hay desplazamiento horizontal disponible si hay muchas columnas).
Ejemplo de errores detectados durante una importación:
![ImportErrors](../../Images/Tuto/Import/ImportErrorsEs.png)
- el campo obligatorio firstFlightDate (Fecha del primer vuelo) no ha sido informado.
- el formato del campo nextMaintenanceDate (Próxima fecha de mantenimiento) para esta fila es incorrecto.

#### Aplicar cambios
Una vez finalizado, puede aplicar los cambios haciendo clic en el botón **Aplicar** situado en la parte inferior derecha de la ventana.
