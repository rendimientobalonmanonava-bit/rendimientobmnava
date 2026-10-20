# BM Nava · Control de cargas / Telemetría

Contexto permanente del proyecto. Léelo entero antes de tocar nada.

---

## 1. Qué es esto

Dashboard de monitorización de carga y disponibilidad del **Club Balonmano Nava** (liga ASOBAL, España).

- **Archivo único**: `index.html`. Autocontenido, sin build, sin dependencias de servidor.
- **Despliegue**: GitHub Pages.
- **Responsable**: Daniel Gutiérrez, preparador físico y analista.
- **Usuarios**: Daniel y Virginia (fisioterapeuta, perfil técnico) · Carlos (primer entrenador, usa móvil, necesita información visual a simple vista).

**Misión por orden de prioridad:**

1. Prevención de lesiones
2. Disponibilidad y ayuda a la selección
3. Análisis de rendimiento
4. Return-to-play

Todo lo que se construya debe servir a ese orden. Si una función es bonita pero no ayuda a ninguna de las cuatro, no entra.

---

## 2. Reglas inviolables

Estas no se cambian nunca sin confirmación explícita de Daniel en la conversación. No basta con que "parezca mejor" o que un cálculo "esté mal según la literatura".

### 2.1 Cálculos bloqueados

| Elemento | Valor fijado |
|---|---|
| Readiness — pesos | Wellness 45 · ACWR 35 · RPE última sesión 8 · Dolor 12 (W45/A35/R8/D12) · *cambiado el 27/08/2026 por decisión de Daniel; antes W50/A28/R10/D12* |
| Readiness — componente wellness | Media entre el z-score relativo y el valor absoluto (escala 1–5), sin poder superar nunca al relativo. *Cambiado el 28/08/2026 por decisión de Daniel; antes solo relativo, que saturaba en 100 en bloques largos de carga alta porque la línea base del jugador se desplazaba* |
| Readiness — curva del componente carga | 100 hasta ACWR 1,0 · baja a 75 en 1,3 · cae 250/punto por encima de 1,3 · por debajo de 0,8 pendiente 160. *No es plana dentro de la banda: eso hacía el readiness insensible a la carga* |
| Readiness — umbrales | Verde ≥75 · Ámbar 55–74 · Rojo <55 |
| Readiness — techo de señal única | Una sola variable mala no puede bajar el readiness por debajo de ~54 |
| ACWR | EWMA 7:21, `ewmaChronic = 0.0909` |
| ACWR — días mínimos de bloque | 21 (`minBlockDays`). *Bajado de 28 el 28/08/2026 por decisión de Daniel: con 28 la carga no entraba en el readiness hasta el cuarto fin de semana de pretemporada* |
| Ratio agudo:crónico mostrado | 7:28 desacoplado, con aguda, crónica, ratio y % de diferencia. Se muestra; NO alimenta readiness ni alertas, que siguen con el acoplado 7:21 |
| Nivel de sesión — del score al nivel | Tercios iguales de la escala 0–2 (BAJA <0,67 · MEDIA <1,33 · ALTA) y, por encima, regla de mayoría: si más de la mitad de los criterios coinciden en un nivel, ese manda. *Cambiado el 12/09/2026 por decisión de Daniel; antes `Math.round(score)`, que daba a MEDIA la mitad de la escala y mandaba 51 de 69 sesiones al cajón del medio* |
| Nivel de sesión — sin pulsómetros | Si la sesión no tiene ninguna captura de Polar, **el criterio de zonas no entra** y su 40% se reparte entre carga, RPE y contacto, que es lo que el modelo ya hacía con cualquier criterio ausente. *Antes `pctZones` devolvía ceros con una lista vacía, la banda salía BAJA y el criterio de más peso puntuaba a partir de un dato inexistente.* Sin ningún criterio, `level` es **null** y se dice «sin datos»: no se inventa nivel |
| Próximas sesiones | «Próximo» se mide **desde el día de hoy de verdad**, no desde el día elegido en el selector. *Al quedarse el panel en un día pasado, «próximas» arrancaba ahí y colaba sesiones ya jugadas: el partido del sábado 26 aparecía como próximo, encima de la sesión de hoy.* Desde v387 las etiquetas Hoy/Mañana ya iban por el reloj, así que el filtro y los rótulos se contradecían. Vale igual para el desplegable de sesiones del modelo de pulso (`hreqProximas`). **Lo que mira al futuro va por el reloj; lo que describe el día que se está viendo, por `REF()`** |
| Series que toman prestado `STATE.refDate` | El recorrido de días de `teamReadinessSeries`/`Async` **cede el hilo antes de mover la fecha**, nunca después, y mientras `window.__RD_CALC` está puesto **nadie pinta**: `renderAll` se anota en `__RD_PEND` y el recorrido le da su turno al terminar, ya con la fecha devuelta y la serie en la caché. *Verificar un cálculo no basta: hay que mirar el DOM. La comprobación del 28/09/2026 llamó a `ultimasSesiones()` a mano, le dio 28/26/25 y dio el bloque por bueno; en pantalla ponía otra cosa porque el pintado había ocurrido antes, con la fecha prestada* |
| Últimas sesiones del Resumen | Una sesión es **un día en el que el equipo hizo algo**, venga de donde venga: captura de Polar, cuestionarios de RPE o un partido en el calendario. *Hasta el 28/09/2026 la tira se alimentaba solo de Polar, así que un día entrenado sin pulsómetros —o un partido, que casi nunca los lleva— no existía para el Resumen y la última sesión se quedaba en la última captura.* Lo que hay se pinta; lo que falta se dice («Sin pulsómetros este día») |
| Tecnificación · tercer bloque de carga | Trabajo específico de mañana que hacen **solo algunos jugadores**, con gente distinta cada semana. `lbBucket` devuelve `tec` y es un bloque igual que pista y gimnasio: minutos propios (`__tec`), convocatoria propia (`asist`) y carga propia. **La regla entera cabe en una frase: entra en lo individual, no entra en ningún agregado de equipo.** Suma a `ua`/`cal`/`dur` del jugador —y por tanto a su ACWR, su monotonía y su readiness, que es para lo que se hizo— y queda fuera de `sessMeta`, o sea fuera del nivel de la sesión del día y fuera del modelo de pulso del equipo. `lbTeamDay` la devuelve como banda aparte con `n` = cuántos la hicieron de verdad, porque su `ua` se promedia sobre toda la plantilla para que la barra apilada siga sumando. En el gráfico semanal es una franja magenta que **no entra en `total`**: `total` es contra lo que se mide el plan, y la tecnificación no se planifica en el calendario. *Decisión de Daniel el 14/10/2026.* **Depende de una opción «Tecnificación» en el formulario de RPE**: sin ella la sesión de mañana es indistinguible de la de tarde |
| Tecnificación — convocatoria | **Nunca automática.** `asistSetAllPending` sigue recorriendo solo pista y gimnasio: el grupo cambia cada semana, así que se convoca a mano desde la columna del día. Las columnas de tecnificación solo salen los días que el bloque existe; si salieran siempre, cada día habría dieciocho botones de «Convocar» a un entrenamiento que no se hizo |
| Microciclo · MD como ancla | **Una sola regla de MD en toda la app: `calMd(dk)`.** Cada día se etiqueta contra el partido **más cercano**, y en caso de empate gana el que viene por delante: a mitad de camino entre dos partidos, lo que gobierna la sesión es el siguiente, no el ya jugado. `calMDmap` (vista de semana) delega en ella. *Antes `calMDmap` elegía UN partido de referencia para los siete días: en una semana con partido el sábado, el lunes salía MD-5 aunque el sábado anterior también se hubiera jugado, cuando ese lunes es MD+2.* El panel `cal-micro-panel` muestra el ciclo real **partido → partido**, no la semana natural; la vista de lunes a domingo se llama **Semana**, que es lo que es. Un ciclo de más de 14 días se recorta y se avisa: significa que falta meter el próximo partido. *Decisión de Daniel el 15/10/2026* |
| La rejilla del mes describe el MES | `calRealMap` usaba `teamDayAgg()`, que filtra `x.date <= REF()`. **Con el selector en un día pasado, los días posteriores perdían la carga real y con ella el % de desviación de su casilla**: Daniel lo vio como «no aparece en todos» con el selector en el 5 de octubre. El mes no describe el día elegido, así que no se acota por él; se lee día a día con `lbTeamDay`, que da el mismo número y no mira a `REF()`. *Es el mismo error de siempre con otra cara — ver «Próximas sesiones» y la serie de readiness.* |
| Zonas altas en la casilla del mes | **Dos cifras separadas, %Z5 y %Z4, no la suma** (*Daniel, 15/10/2026*): no es lo mismo un 20 % repartido que un 20 % que es casi todo Z5. Cada una se colorea **contra su propia banda de `SESSPEC`** —Z5 con 1/3/5 y Z4 con 8/15/20—, porque un 4 % es mucho en Z5 y poco en Z4. **No se inventan umbrales**: son los de la app y el mismo aplastado a tres niveles que hace `classifySession` (`Math.min(2,banda)`), así que el color de la casilla no puede contradecir al nivel con el que se clasifica la sesión. El nivel se calcula sobre la **cifra redondeada que se ve**, no sobre el valor interno: un 0,95 % pintado como «1 %» con el color del 0 hace que se deje de creer a la pantalla (misma regla que en el ACWR proyectado) |
| Color del % en Z4+Z5 | **No se inventan umbrales.** Son las bandas oficiales de `SESSPEC` (`z54`: 8 · 18 · 24) y el mismo aplastado a tres niveles que hace `classifySession` (`Math.min(2,banda)`), así que el color de la casilla y el nivel con el que se clasifica la sesión no pueden contradecirse: <8% verde · 8–18% ámbar · >18% rojo. *Que el rojo signifique «mucho Z4+Z5» es coherente con el semáforo de intensidad de al lado, que ya usa rojo para ALTA: no es decoración, es la misma escala.* Pedido por Daniel el 15/10/2026 |
| Casilla del mes · qué se ve sin pasar el ratón | Semáforo de intensidad, duración, contacto, **% de desviación plan vs real** y **% del tiempo en Z4+Z5 de los pulsómetros** (`calZ45`, mínimo `CAL_Z45_MIN`=3 capturas: con una o dos el porcentaje describe a un jugador, no a la sesión). El valor escrito a mano se marca con `*` para no mezclar medido con estimado. *Pedido por Daniel el 15/10/2026.* Si el día tiene plan y cuestionarios pero **no tiene minutos**, la carga no es calculable y la casilla lo dice con `min?` en vez de quedarse muda, que es lo que hacía parecer que el % fallaba |
| Microciclo · dónde vive y cómo se dibuja | **Vive dentro de `cal-body`, debajo del «Resumen por semana · monotonía y strain»** —decisión de Daniel el 15/10/2026— y por eso `renderCalMicro()` se llama **después** del `innerHTML` del mes y del de la semana: antes el contenedor todavía no existía. Es un **gráfico de verdad**, no barras flotando: eje con escala en UA redondeada al siguiente escalón (`paso` 50/100/250/500 según el techo), rejilla que cruza las siete columnas y un plano alto y **compartido** —las barras no viven cada una en su cajita, que es lo que impedía comparar un martes con un sábado—. Las etiquetas salen del plano a una rejilla de siete columnas debajo, alineada con la de arriba. *Dos versiones anteriores se rechazaron por barras finas y aire muerto.* |
| Microciclo · densidad | **La barra crece con la columna, no es de ancho fijo.** La primera versión fusionada puso barras de 17 px dentro de columnas de 250: todo el peso visual se iba en aire y Daniel lo rechazó —«las barras son muy finas, hay mucho espacio vacío, poco dato»—. Las barras van con `flex:1` y un tope, la zona de temporada ocupa el ancho entero de la columna, y **el gráfico y la proyección del ACWR van uno al lado del otro**, no apilados: el hueco de la derecha se llena con dato en vez de con aire. Cada día cuenta además **lo real y su desviación del plan** (`563 · +15%`), que es lo que convierte la columna en una lectura. En móvil el pie se apila y los estados largos («pendiente», «sin plan») se reducen a una raya: a 46 px de columna el texto se comía la columna de al lado |
| Microciclo · una sola tarjeta | **El ciclo actual y la referencia de temporada viven en el mismo sitio**: eran dos tarjetas con las MISMAS siete columnas en el mismo orden, una debajo de otra, 942 px para decir dos cosas del mismo día. Desde v395 cada día es **una columna** donde la banda de temporada es el **fondo** y las barras del ciclo van delante — 355 px, y deja de haber que mirar arriba y abajo para comparar. *Decisión de Daniel el 15/10/2026: «está todo muy mal optimizado a nivel de espacio».* Tres pesos visuales distintos y a propósito: relleno muy tenue con una línea arriba que marca el máximo de la temporada, raya **discontinua** para la media, y la barra de plan en un gris claramente más oscuro. Cuando la zona y la barra de plan compartían gris parecía un recuadro alrededor de las barras en vez de un rango. El partido va en una línea en la cabecera, no en un bloque propio |
| Referencias por día del ciclo | `calRefMD`: media, mínimo y máximo de la carga del equipo **en cada posición del microciclo** (MD+1…MD-1, MD), acumulado de toda la temporada. Es la referencia que convierte el plan en decisión: «un MD-1 nuestro son 300 UA, no 600». *Pedido por Daniel el 15/10/2026 a partir de un informe suyo en hoja de cálculo.* **Solo desde el 1 de septiembre** (`MD_REF_DESDE`): agosto es pretemporada y su carga no describe la temporada. **No basta con filtrar los días: hay que filtrar los PARTIDOS**, porque si no, un día de septiembre cuyo partido más cercano fuese el último amistoso de agosto entraría etiquetado contra la pretemporada — por eso `calMd(dk,ps)` admite la lista. Se promedia **solo sobre días con carga registrada**: un día sin cuestionarios no es un día de 0 UA, es un día del que no sabemos nada, y como cero hundiría la media de esa posición. Las posiciones con menos de 3 días se atenúan y se dicen. **El informe original usaba rojo para el máximo y amarillo para el mínimo; aquí el rojo es solo de alertas y un máximo histórico no es una alerta**: la banda va en neutro y la media en el color de acción |
| Dónde aterriza el ACWR | El ACWR es una EWMA, o sea **aritmética proyectable**: con la carga puesta en el calendario para los días que faltan se calcula dónde acaba cada jugador al cerrar el ciclo. `calProyeccionACWR` extiende la serie diaria del jugador con el plan y la pasa por **`acwrDeSerie`, el mismo cálculo que el ACWR real** —extraído de `acwrToDate` justo para esto; una copia se desincronizaría al primer ajuste de pesos—. Dos honestidades van escritas en la pantalla: la carga planificada es **del equipo** y se le atribuye entera a cada jugador (es «si hace lo que hay puesto», no una predicción individual), y la comparación con la banda se hace sobre la **cifra redondeada que se ve**, no sobre el valor interno: un 0,7996 marcado en ámbar mostrando `0.80` hace que se deje de creer a la pantalla |
| Cerrar sesión del día | `calCerrarSesion(dk)`: pone la duración planificada en los bloques que no la tengan y convoca a quien no respondió. **Lo que no hace, a propósito**: no pisa minutos escritos a mano —lo escrito es dato, el plan es suposición—, no toca la tecnificación, y **no cierra días sin sesión planificada** (sin esa guarda, pulsarlo en un descanso convocaba a toda la plantilla a bloques que «existían» por un cuestionario suelto, y convocar imputa carga). Convoca en **dos pasadas**: al escribir los minutos de un bloque ese bloque pasa a existir, y solo entonces se vuelven convocables los que no lo habían declarado. Siempre dice en voz alta lo que ha hecho |
| Nivel de sesión — corrección manual | Manda siempre sobre el cálculo. Se guarda por clave `fecha\|etiqueta` en `bmnava_sesniv` y se sincroniza |
| Modelo de sesión del equipo | `hreqModelo`: de **RPE objetivo + contacto** (lo que se planifica en el calendario) a **objetivos de pulso** (minutos y % en Z4+Z5, FC media, TRIMP). Es el inverso del modelo individual, que va de pulso a RPE. Una sesión = un punto: se exigen 5 pulsómetros por sesión y `HREQ_MIN`=12 sesiones con pulso, RPE del equipo y contacto. El término de contacto solo entra con contacto variado **y** ≥20 sesiones: con 12 puntos, cuatro coeficientes se ajustan al ruido. **La salida son rangos, nunca cifras exactas** (centro ± error de validación cruzada), y con ajuste <20% no se dibujan objetivos, igual que en el individual. El TRIMP se modela **por minuto** y el volumen lo pone la duración planificada, no el modelo; se calcula pero **no se muestra**: las cuatro salidas visibles son minutos y % en Z4+Z5, % en Z5 y FC media (*Daniel cambió TRIMP por %Z5 el 22/09/2026*). Cada tarjeta lleva el ajuste de **su propia** salida en un punto de color, porque el %Z4+Z5 se predice bastante mejor (51%) que el %Z5 (26%). Junto al rango se muestra siempre la mediana observada de las sesiones parecidas, que es el contraste sin modelo. *Pedido por Daniel el 22/09/2026.* Vive en Pulsómetros › Equipo, **debajo de la clasificación de sesión y la semana**, y deja un resumen corto en el calendario y en las próximas sesiones del Resumen |
| Comparar puestos, no filtrar por puesto | Daniel, 16/10/2026: «Cargas › RPE me parece casi absurdo y no lo uso». **El motivo era concreto: «Por posición» e «Individual» eran el MISMO panel con otro filtro** —siete gráficos repetidos que, filtrados, no responden ninguna pregunta de puesto—. La pregunta de puesto es comparativa, y eso no se ve filtrando sino poniendo los cuatro al lado (`cgPorPuesto`). Dos reglas: **todo por jugador y por día, nunca totales** —un grupo de siete suma más que uno de dos por ser siete, no por entrenar más— y **cada cifra contra la mediana del equipo**, para que diga algo sin recordar de memoria qué es mucho. El detalle de un puesto suelto se conserva debajo. *Con los datos del club: pivotes con menos carga total (573 UA/día) y mucho más contacto (3,7 frente a 2,3 del equipo); porteros aparte, como debe ser* |
| Quién necesita algo hoy | `cgAtencion()`: lista corta ordenada por gravedad con **el motivo y qué hacer**, en vez de un quinto gráfico. **No inventa ningún umbral**: reúne los que la app ya tiene —banda del ACWR, monotonía, readiness, episodios médicos abiertos y el coste cardíaco— y los ordena. Si alguien no sale, es que ninguna de sus señales está fuera de rango. *Propuesta 3.2* |
| Plan contra real, por jugador | `cgPlanReal()`: la comparación del equipo ya estaba; por jugador es otra pregunta y es mejor —quien se queda corto siempre es el que juega menos, quien se pasa siempre es el riesgo—. La carga planificada del calendario **es del equipo**, así que es la misma para todos: lo que cambia es lo que cada uno hizo. **Los días sin dato no cuentan como cero**: no se comparan. *Propuesta 3.3* |
| Cada jugador, esta semana | `renderCargaResumen`, panel nuevo de v426. **La monotonía y el strain por JUGADOR**, que no estaban en ninguna pantalla: solo existía la media del equipo, y una media no dice quién lleva tres semanas entrenando siempre igual. Una fila por jugador con UA de la semana, **ACWR sobre una banda dibujada** (0,8–1,3 sombreado, punto en su valor), monotonía y strain, ordenada por lo que hay que mirar antes: fuera de banda, luego monotonía alta, luego el resto. Todo sale de `weekly()`, que ya devolvía `ua`, `mono`, `strain` y `acwr`: **no se añadió ningún cálculo nuevo**. Umbrales: la banda del ACWR es la del reparto de arriba y la monotonía va por `calMonoTier`, el mismo criterio del calendario. **Sustituye al gráfico de 14 días del equipo**: el gráfico era del equipo y el problema es individual. *Pedido por Daniel el 20/10/2026* |
| Cargas › Resumen — qué se quitó | Daniel, 20/10/2026, sobre qué más cambiar en Cargas. Medido antes de proponer: **era una segunda portada**. De sus seis indicadores de cabecera, **cinco ya estaban en el Resumen** (readiness medio, ACWR medio, disponibles, con molestia, fuera), «A vigilar por carga» solapaba con «A vigilar y destacados» y «Últimas sesiones» estaba literalmente en los dos sitios. Se quitan los tres indicadores repetidos y los dos paneles; se quedan los que **solo** están aquí. **Si una cifra se ve dos veces, la segunda no aporta y hace que la vista parezca una copia** |
| ¿Llegan a ritmo de partido? | `hrListos` + `renderHRListos`, en Pulsómetros. Sustituye a «Carga contra minutos jugados», que decía cuánta carga y cuántos minutos pero no qué hacer con eso: **un entrenador no decide con «570 UA y 12 minutos», decide con «este no está llegando a ritmo de partido»**. Compara el %Z4+Z5 que cada uno alcanza **entrenando** con el que exige un partido, y lo cruza con los minutos jugados. Cuatro reglas: **(1) la exigencia no se inventa**, es la mediana de vuestros propios partidos medidos; **(2) el listón de «juega» tampoco**, es la mediana de minutos de los que juegan; **(3) cada uno contra SU propio partido** cuando tiene dos o más lecturas suyas —la misma regla del coste cardíaco—, porque medir a todos contra la media del equipo señalaría siempre a quien lleva el pulso bajo; **(4) una referencia por debajo del corte «baja» de `SESEF()` no es una referencia**: Josu y Óscar daban 0,5 % y 2 % en partido y al dividir salía «611 % de la exigencia». Con suelo, caen en **«pulsómetro poco fiable»** y no se les juzga, que es lo honesto: su FC máx está mal configurada, no les falta forma. *Pedido por Daniel el 20/10/2026* |
| Tiempo en zonas de la semana | `wzSemanas` + `buildWeekZones`, en Pulsómetros. Daniel, 20/10/2026: «creo que esto está mal calculado, no me sirve de nada así». **Lo que estaba mal era la UNIDAD, no la aritmética**: el bloque sumaba los segundos de los dieciséis jugadores y enseñaba ese total —18:33— como «Total de la semana». Ese número no lo ha vivido nadie: es el tiempo de dieciséis personas puesto uno detrás de otro, y era lo escrito más grande del panel. La unidad es ahora el **jugador-sesión**, la única comparable: no depende de cuántos llevaron pulsómetro ni de cuántas sesiones se han subido. Cuatro reglas: **(1) nada de Δ%** —medido sobre las 726 lecturas del club, el Z5 de un jugador en una sesión va de 0,4 a 1,3 min, así que un porcentaje sobre esa base se dispara solo: +155 % la semana del 16/03, +77 % la del 18/05, y el +440 % que vio Daniel era una base de dos minutos; es la misma trampa ya escrita para el progreso del TSA—, la comparación va **en minutos** y contra la **mediana de nuestras propias semanas**; **(2) ningún umbral nuevo**: el nivel del %Z4+Z5, del %Z4 y del %Z5 sale de `calZonaNivel`, o sea de las bandas calibradas de `SESEF()`, y **Z1, Z2 y Z3 no llevan nivel porque la app no tiene banda para ellas**; **(3) la barra apilada ES el reparto** —las cinco zonas suman el 100 % del tiempo de sesión—, mientras que las barras por fila del bloque viejo iban contra el máximo y pintaban Z5, que es el 1 % del tiempo, del tamaño de Z1; **(4) una semana a medias se dice, no se penaliza**: el número es por sesión y se puede comparar desde la primera, y lo que se dice es cuántas sesiones y cuántas lecturas lo sostienen, con aviso explícito por debajo de `CAL_Z45_MIN` lecturas. El rango de nuestras semanas (franja p33–p66, filo en la mediana, punto de esta semana en el color de acción) ocupa el hueco que antes era aire muerto entre el nombre de la zona y las cifras. Referencia: nuestras semanas con 2 o más sesiones medidas, mínimo `WZ_MIN_SEM`=4 |
| Carga contra minutos jugados | `cgMinutosCarga()`: quién acumula carga sin competir, que es la pregunta de disponibilidad y selección (misión 2). Los minutos salen de lo que se apunta en cada día de partido (`lbDur(dk,name,'pista')`). **Se presenta como pregunta, no como alerta** |
| Carga antes de las lesiones | `lesCarga()`: contrasta los umbrales con lo que de verdad le ha pasado a esta plantilla. **Se mira la víspera**, no el día del episodio: ese día la carga ya está contaminada por la propia lesión. **Y siempre contra una población de control** —días-jugador sin episodio abierto ni episodio en los 7 días siguientes, y sin episodio en los 21 anteriores—: que el 60 % de las lesiones llegue con ACWR alto no dice nada si el 60 % de los días normales también. *Un jugador sin carga calculable da EWMA ≈ 0 y eso **no** es «ACWR bajo», es «no sabemos»: sin carga aguda el caso se descarta, porque contándolo cada día sin minutos entraba como día tranquilo y hundía las tasas de los dos lados.* Por debajo de `LES_MIN`=6 episodios se enseña el recuento y **se calla la conclusión**. El texto dice explícitamente que describe lo que ha pasado y no demuestra causa. *Pedido por Daniel el 16/10/2026 (propuesta 3.1)* |
| Familias de sesión | `famAgrupar()`: las sesiones de Polar se agrupan por **cómo son** —intensidad (%Z4+Z5), contacto y volumen—, no por la etiqueta que lleven. Normalización robusta por eje (mediana y MAD) para que ninguno mande por tener números más grandes, y k-medias con **siembra determinista**: con semilla aleatoria las mismas sesiones caerían en familias distintas en cada recarga y nadie se fiaría de una etiqueta que cambia sola. **El nombre sale de sus propios números** contra la mediana del conjunto («alta con contacto y larga»), no de una lista fija: si los números cambian, el nombre cambia. `FAM_MIN`=12 sesiones con ≥4 pulsómetros; K=4, o 3 por debajo de 24 sesiones. Cada familia trae **el wellness del equipo del día siguiente**, que es lo que dice qué sesión sale cara: dos sesiones pueden dar el mismo pulso y dejar al equipo muy distinto en MD+1. *Pedido por Daniel el 16/10/2026 (propuesta 2.5, ideas a+b+c)* |
| Coste cardíaco | `hrEficiencia()`: **FC media ÷ RPE del propio jugador**, comparado contra su propia mediana y MAD. *Dicho sin adornos y escrito en la pantalla: no es la eficiencia cardíaca de laboratorio, que necesita carga externa medida —vatios, metros— y aquí no la hay. Es la relación entre lo que dice su pulso y lo que dice él, que es la discrepancia que sí se puede leer con estos datos.* **Cada jugador solo contra sí mismo**: Josu y Óscar tienen el pulso sistemáticamente bajo (anomalía conocida) y contra la media del equipo saldrían marcados todos los días. La lectura va sobre las **tres últimas sesiones**, no sobre una, y hace falta `HRE_MIN`=6 sesiones con pulso y RPE para tener línea base. *Pedido por Daniel el 16/10/2026 (propuesta 2.3)* |
| ¿Cumplimos el objetivo? | `hreqCumpl(key)`: cierra el bucle del modelo de sesión del equipo. El modelo decía antes de entrenar hasta dónde había que llegar; esto comprueba después si se llegó, sobre la sesión elegida en el selector de Polar. **Se compara contra lo que se planificó ESE día en el calendario** (RPE objetivo y contacto del evento), no contra lo que parezca ahora. **El objetivo es un rango, no una cifra**: «dentro» es dentro del rango, y cuando se sale se dice por cuánto. Sin plan en el calendario no hay objetivo y **se dice en vez de inventar uno**; con menos de 3 pulsómetros tampoco, porque el porcentaje describiría a un jugador. Incluye el desglose por jugador sobre el %Z4+Z5. *Pedido por Daniel el 16/10/2026 (propuesta 2.2)* |
| ¿Pasó lo que programamos? | `calCumplDia(dk)`: el veredicto de un vistazo para el entrenador —«si programamos FC alta, que sea alta»—, en la **lámina A4** y en la **semana del calendario**. Se compara el %Z4+Z5 medido contra **lo que se pidió ese día**: la banda del objetivo cardíaco si lo hay, y si no el rango que salía del RPE y el contacto planificados. **Un día sin pulsómetros no es un día incumplido, es un día del que no se sabe**: devuelve null y la fila no existe, así que la hoja se va completando sola según entran las capturas. El veredicto lleva **símbolo y palabra** además de color (`✓ Dentro` · `↓ Corto` · `↑ Pasado`), porque la lámina se fotocopia en blanco y negro. **El rojo no entra**: pasarse de pulso es una desviación, no una alerta, así que se usa el color de acción, igual que `hreqCumpl`. **En día de partido se enseña lo medido pero SIN veredicto**: el modelo está ajustado con entrenamientos y juzgar un partido con él sería extrapolar — desde v431 esa guarda vive **dentro de `calCumplDia`**, que es quien decide el cumplimiento, y no en cada consumidor. *Pedido por Daniel el 19/10/2026* |
| Lámina A4 — el microciclo se ancla a la semana impresa | `calMicrociclo` se llamaba siempre con hoy, así que al navegar a otra semana la hoja salía con la semana de mayo arriba y el ciclo de octubre abajo. Si hoy cae dentro de la semana mostrada se usa hoy —el caso normal—; si no, el jueves de esa semana. **La marca de «hoy» dentro del gráfico sigue yendo por el reloj**: es la misma regla de siempre, lo que mira al futuro va por el reloj y lo que describe lo que se está viendo, por lo que se está viendo |
| Cerrar el bucle · lo esperado contra lo reportado | `hreqCumpl` compara ahora también el **RPE**. Con objetivo cardíaco el RPE era una **predicción** y se comprueba contra su rango («Esperabas 6,6–7,6 → Reportaron 6,2»); sin él era la **entrada** del plan y lo que se mide es la desviación respecto a lo que se pidió («Pediste 6,9 → Reportaron 6,2»). Son dos preguntas distintas y van rotuladas distinto. El valor real sale de `sessMeta(key,dk).rpe`; sin cuestionarios se dice en vez de dejar el hueco. **Con objetivo cardíaco se comprueba contra lo que se PIDIÓ**, no contra lo que la regresión habría predicho desde el RPE: eso sería comprobar el plan contra otro plan. *Pedido por Daniel el 19/10/2026* |
| Objetivo cardíaco · el RPE como SALIDA | `e.card` (1 bajo · 2 medio · 3 alto) y `calCardObj(e)`. Invierte el planificador: se pide **pulso + contacto** y el **RPE se calcula** con `hrpModelo`, que es el modelo individual del revés y ya existía (r² 0,66 · rmse 0,48 con 68 sesiones). Responde a lo que Daniel planteó el 19/10/2026: sesiones de mucha carrera y poco contacto —mucho pulso, RPE moderado— frente a mucho juego real con poco pulso. Con los datos del club, el mismo objetivo cardíaco a contacto 1 espera **RPE 5,6–6,6** y a contacto 4, **7,1–8,1**. Cuatro reglas: **(1) NO toca `intens`** —ese campo alimenta la carga planificada, el semáforo, la casilla del mes y `calRefMD` en todo el histórico, y redefinirlo reinterpretaría en silencio lo ya planificado—, así que es un campo aparte y **opcional**: sin él todo se comporta como antes. **(2) No inventa umbrales**: bajo/medio/alto son las bandas de `z54` de `SESEF()`, las mismas calibradas que usan la casilla del mes y `classifySession`. **(3) No modela el %Z5 ni la FC**: se leen de las sesiones reales que cayeron en esa banda (mediana y rango intercuartílico), y con menos de 3 no se enseñan. **(4) No extrapola en silencio**: el modelo se evalúa recortado a `[zMin,zMax]` y se avisa solo cuando el recorte pasa de un punto de %Z4+Z5 — si no, el aviso saltaría en dos de los tres niveles y dejaría de leerse |
| Objetivo cardíaco — lo que falta | El contacto registrado **no tiene recorrido**: 43 de 68 sesiones están en contacto 3 y el rango real es 2–3,75, sin nada por debajo de 2 ni por encima de 4. Y el RPE correlaciona 0,57 con el contacto, o sea que históricamente se han movido juntos. Mientras eso no cambie, los extremos del nuevo selector se apoyan en muy pocas sesiones y la app lo dice. **Empezar a registrar contacto 0, 1, 4 y 5 es lo que da valor a todo esto.** Pendiente: `hreqCumpl` todavía comprueba el cumplimiento por el camino antiguo, no por el objetivo cardíaco |
| RPE objetivo en el calendario | Campo `e.rpe` del evento, entrada del modelo anterior. Si no se ha tocado, se hereda de la intensidad (`HREQ_RPE_INT`: baja 4,5 · media 6,5 · alta 8,2) y cambiar la intensidad la reajusta; moverla a mano manda sobre eso |
| Lámina A4 de la semana | `calSemanaA4`, botón en la vista de Semana del calendario. Una hoja apaisada para colgar en la oficina: los siete días, el microciclo y **el objetivo de pulso de cada día**, que es lo que no estaba en ningún papel. **La semana y el microciclo NO son el mismo tramo y la lámina lo rotula**: la semana es lunes-domingo, el microciclo va partido → partido. El objetivo del día se agrega de verdad: los minutos en Z4+Z5 se **suman** entre las sesiones (son minutos, son aditivos) y los porcentajes y la FC se promedian **ponderando por duración** (son tasas; a secas darían el mismo peso a 30′ que a 90′). Sin modelo útil **se dice una vez en el pie**, no cinco cajas iguales; sin partidos no hay microciclo, la misma guarda que `renderCalMicro`. Un día de descanso **no tiene intensidad**: `evIntens` devuelve 2 por defecto y el semáforo lo pintaba MEDIA — en pantalla se perdona, en un papel colgado no. *Pedida por Daniel el 19/10/2026* |
| Grado del desvío · `calDesvio` | Daniel, 20/10/2026: «mete color verde cuando estemos en el rango pactado, amarillo si nos desviamos por arriba o abajo un poco y rojo si nos pasamos bastante de lo establecido». **Es un cambio de criterio y hay que decirlo**: hasta aquí el color decía la DIRECCIÓN —ámbar corto, color de acción pasado— y ahora dice la GRAVEDAD. La dirección no se pierde, se lee en el dibujo: el punto cae a la izquierda o a la derecha de la franja, que es más claro que acordarse de qué significaba cada color. **«Un poco» y «bastante» no son dos números nuevos**: el listón lo pone el propio rango pactado —fuera de la franja pero a menos de MEDIA ANCHURA DE FRANJA del borde, desvío leve; más allá, fuerte—. Así una métrica que el modelo predice con poca certeza (rango ancho) aguanta más desvío antes de ponerse en rojo, y una que predice fino se pone antes. Y en la carga, cuya franja es el ±15 % de `calDev`, la regla reproduce **exactamente** los tramos que `calDev` ya tenía (verde ≤15 %, ámbar ≤30 %, rojo por encima): que coincida es la comprobación de que el criterio no está sacado de la manga. Con una franja de anchura cero no hay escala para graduar, así que se dice «leve» y no se afirma «bastante». Lo usan las barras de la lámina, la tira de la semana y el chip de la vista de semana del calendario — **un solo criterio, un solo sitio** |
| Lámina A4 · el resultado de CADA día | Daniel, 20/10/2026: «lo quiero para cada día, de manera muuuuuy gráfica, que mi entrenador lo entienda sin tener conocimiento en el área de preparación física… combinar una parte técnica con información sencilla». **Dos lecturas en el mismo sitio y a propósito.** *(1) La del entrenador*: **dos semáforos**, el que se programó y el que salió, con una flecha en medio y una palabra debajo —«Como se pidió», «Más duro», «Más suave»—. No hace falta saber qué es una zona 4 para leer eso. El nivel real lo da **`classifySession`**, el mismo con el que la app clasifica cualquier sesión y que respeta la corrección manual: **no se inventa aquí una segunda forma de decidir si una sesión fue dura**, y la palabra sale de restar dos niveles que ya existían. *(2) La del preparador*: **una barra por métrica** —carga, %Z4+Z5, %Z5, FC y RPE— con la **franja de lo que se pidió** y un **punto en lo que salió**, verde dentro, ámbar corto y color de acción pasado, que son los estados de `CUMPL_EST`. La franja va en neutro porque **no es una alerta**: lo que se mira es dónde cae el punto, misma regla que `calRefMD`. El encuadre de la barra se centra en la franja y se abre lo justo para que un valor muy fuera siga cayendo dentro del papel; sin eso, un día que se va al doble sacaría el punto del recuadro. **La cabecera es siempre una línea y la tabla siempre cinco filas**, pongan lo que pongan: así los siete recuadros miden igual y las barras de un día se comparan con las del de al lado sin que la vista se recoloque — la misma razón por la que la semana es una rejilla compartida. Un día de partido enseña las cinco cifras **sin franja ni veredicto**, que es la regla ya escrita de no juzgar un partido con un modelo ajustado con entrenamientos. La leyenda de la barra se dice **una vez en el pie**, no siete veces. El contacto real va en la línea de la duración (`Contacto 4 → 3,1`) y la carga deja la fila 6 porque ya tiene su barra: la fila 6 se queda con la media del MD y las bajas |
| Lámina A4 · «La semana» (cierre) | `calSemA4Efectos(dks)` + la tira `.sa-ef`, entre la semana y el microciclo. **Desde v430 es UNA línea de 26 px, no cinco tarjetas de 82**: el resultado de cada día vive ya en su columna, así que esto se queda como el cierre de la semana y le cede el alto a los días. Daniel, 20/10/2026: «quiero que me vayas poniendo de una manera súper sencilla de interpretar cuáles han sido los efectos del entrenamiento reales; si ha sido más carga total, más %Z4, %Z5, RPE, contacto… de la que habíamos planificado». Cinco ejes —los cinco que nombró— y una sola lectura por eje: lo que se pidió → lo que salió, y si fue más, menos o lo previsto. Seis reglas, **ninguna nueva**: **(1) un día sin dato no cuenta como cero**, solo entran los días con las DOS cifras y cada celda dice sobre cuántos días va —sumar el plan de la semana entera contra un real a medias diría siempre «por debajo»—; **(2) la carga se suma** (es aditiva) y **todo lo demás se promedia ponderando por duración**, la misma regla de `calSemA4Obj`; **(3) el objetivo es un rango** donde el modelo lo da (%Z4+Z5 y %Z5), y donde no, la tolerancia es una que ya existía: ±15 % de `calDev` en la carga y medio punto de `calCumplDia` en el RPE; **(4) la palabra dice la DIRECCIÓN y el color dice si cayó dentro de lo pedido**, que son dos cosas distintas —misma separación que las flechas del Camino a Champions—; **(5) el contacto va en neutro, sin veredicto de color**: no tiene banda en la app y no se inventa, igual que la FC media del recuadro del día; **(6) el %Z4 se deriva, no se modela** —el modelo predice %Z4+Z5 y %Z5, así que el %Z4 pedido es la resta, con el rango ensanchado a propósito (lo45−hi5 … hi45−lo5) porque una resta de dos intervalos ajustados por separado no puede salir más estrecha que ellos—. **Por eso cada celda enseña SIEMPRE la diferencia además del veredicto**: con un rango ancho, «Dentro» no respondería a la pregunta, que es cuánto más o cuánto menos. Los días de partido se caen solos de los ejes de zona, porque `calSemA4Obj` no da objetivo para ellos. La fila de carga de cada día pasa a enseñar **Plan y Real con su desviación** (la media del MD cede el sitio; la referencia de temporada sigue dibujada en el microciclo), y un día sin cuestionarios dice «sin RPE» en vez de pintar un 0 UA |
| Lámina A4 — la semana es UNA rejilla | Los siete días **no son siete columnas independientes**, sino seis filas compartidas (cabecera · semáforo · duración · sesiones · objetivo · carga). Con columnas sueltas, un día con una sesión más empujaba todo lo de debajo y los objetivos de pulso arrancaban a dos alturas distintas — lo que Daniel vio como «a veces queda con poco margen». En una rejilla común la altura de cada banda la fija el día más alto y las siete se alinean solas. La tarjeta se dibuja aparte, con un fondo que cruza las seis filas. *Decisión de Daniel el 19/10/2026* |
| Lámina A4 — el recuadro del objetivo | **Altura fija e idéntica en los siete días.** Antes dependía del contenido: «· 2 sesiones» partía la cabecera en dos líneas y un rango ancho («14–25») empujaba «min en Z4+Z5» a otras dos, así que los días de dos sesiones salían apretados aunque su fila estuviese alineada. Ahora la cabecera es **siempre una línea**, la cifra va sola y la unidad debajo a todo lo ancho, con el recuento de sesiones en esa misma línea. **La fila elástica de la rejilla es la de las SESIONES, no la del objetivo**: al revés, un recuadro más alto que su fila se desbordaba hacia arriba y tapaba la segunda sesión del día |
| Lámina A4 — color de las zonas | El %Z4+Z5 y el %Z5 van **con el color de su propia banda**, por `calZonaNivel(pct,key)`, que lee los umbrales calibrados de `SESEF()`. **No se inventan umbrales**: son los mismos que la casilla del mes y que `classifySession`, así que la lámina no puede decir que un 12 % es media si el calendario lo pinta alta. Se evalúa el **centro del rango**, porque el objetivo es un rango y no una cifra. El rojo aquí significa «mucho Z4+Z5» y es coherente con el semáforo de intensidad que está justo encima — la misma excepción ya documentada para la casilla del mes. La FC media va en neutro: no tiene banda. Los tres tonos sobre su fondo claro quedan por encima de 4,5:1 (4,99 · 5,63 · 4,75). *Pedido por Daniel el 19/10/2026* |
| Lámina A4 — el gráfico del microciclo | La banda de temporada y las barras viven en **la misma zona centrada**: la banda ocupaba el ancho entero de la columna (131 px) con una barra de 54 centrada, y se leían como dos cosas distintas una al lado de otra en vez de como «el rango en el que suele caer ESTA barra». El eje admite **cinco divisiones, no cuatro**: con un techo de 1060, cuatro forzaban un paso de 500, el eje cerraba en 1500 y sobraba un tercio del gráfico. La **media va en el color de acción** y la banda en neutro, que es la regla ya escrita para `calRefMD`: en gris, la media se perdía dentro de su propia banda |
| Lámina A4 — color y contraste | El semáforo se dibuja con **`calTraffic`**, el mismo del calendario y de la lámina de umbrales: el papel y la pantalla no pueden decir cosas distintas, y va **con la palabra** BAJA/MEDIA/ALTA al lado, porque una fotocopia en blanco y negro se queda sin color. **Los colores del semáforo valen para el punto, que es un gráfico, pero no para la letra**: sobre blanco el ámbar `#e6a700` da 2,0:1 y el verde 3,0:1, por debajo del 4,5:1 que necesita el texto de menos de 17 pt. `tinta()` los oscurece —mismo tono— solo cuando el color va sobre una palabra. Hoy y el día de partido se marcan con el **borde**, no con un fondo de color: un fondo saturado detrás de texto pequeño se come el contraste |
| Pruebas isocinéticas — modelo y cálculos | `bmnava_iso`, una fila por prueba. **Los cálculos se hacen en el código, nunca a mano**: LSI = pierna operada / pierna sana × 100, Nm/kg sobre el peso **del día de la prueba** (no el del roster: entre una prueba y otra pasan meses y el peso del roster es el de hoy), H/Q = flexores / extensores y las semanas desde la cirugía. El jugador se resuelve con `canonicalName` contra la plantilla, así que la prueba cuelga del jugador que ya existe y no se crea un fantasma. **La fecha de nacimiento sale de `STATE.info`, no del JSON del laboratorio** —el dato del club manda— y se muestra la fecha, nunca la edad. `isoCalc` es el único sitio donde se calcula; `isoInformeHTML` solo pinta. *Integración pedida por Daniel el 19/10/2026 a partir de su kit* |
| Pruebas isocinéticas — qué se oculta | **El bloque sin dato no se pinta y no se inventa ningún valor** (regla del propio kit). Sin curva de par, el gráfico desaparece **y su hueco se reparte**: dejarlo eran 390 px de hoja vacía. Sin pruebas, la sección entera no sale de la ficha. Con una sola prueba no hay gráfica de evolución, porque sería un punto suelto —misma regla que los micrográficos del Resumen—. Si el JSON trae `nota` en la curva, se rotula «Esquema del informe»: un gráfico aproximado sin decir que lo es no entra en algo que se le enseña al jugador |
| Pruebas isocinéticas — referencias | `bmnava_isoref`, **configurables, no fijadas en el código**: media ASOBAL (2,8 Nm/kg de partida), meta alta (2,5), meta de LSI para competir (90 %) y meta intermedia de vuelta a pista (80 %), más la fuente de la referencia. Viven aparte de las pruebas porque son del club y no de una prueba concreta: cambiarlas reescribe **todos** los informes, también los ya guardados. Al vaciar un campo se vuelve al valor de partida, no se deja un hueco que luego pinte `undefined` |
| Pruebas isocinéticas — dónde vive cada cosa | El informe es **una hoja A4 apaisada propia (1123×794)**, así que **no va dentro de la ficha exportable**: esa es otra hoja y meter una dentro de otra rompe las dos. Va en su propio visor (`#iso-overlay`), por **encima** de la ficha —con el mismo z-index ganaba la ficha por orden en el DOM y el informe no se veía— y con fondo más oscuro para que las dos barras no compitan. En la ficha lo que hay es el **historial** con el botón. La entrada de datos vive en **Perfil físico › Jugador**, junto a los demás cargadores, porque es un dato de valoración física. Los colores (#D70C22, #1D2836) son los de la plantilla, **fijados a claro** como la ficha exportable y la lámina de umbrales: es un documento que se imprime. Ese rojo **no es el rojo de alertas de la app** y no sale de la hoja |
| Camino a Champions — estructura | Dos partes: lo **ya conseguido** en una tira de etiquetas doradas (una línea, no una fila de bloques) y lo que **falta** en la rejilla, ordenado de más cerca a más lejos. Cada prueba lleva el **cambio desde la valoración anterior de esta temporada**, etiquetado como evolución en la banda de sección y en el encabezado del grupo. **La flecha dice la dirección del dato (sube o baja) y el color, si ese cambio es a mejor o a peor**: son dos cosas distintas y se codifican por separado. Cuando la flecha marcaba "mejora" en vez de dirección, un ▲ verde junto a un 9,3 % de grasa se leía como que había subido cuando lo que había hecho era bajar. Ambas mediciones tienen que ser posteriores a `TEMP_INICIO`. *Decisión de Daniel el 21/09/2026* |
| Radar del perfil de capacidades | **Ocho capacidades** (`CAP_GRUPOS`: velocidad, salto, lanzamiento, fuerza máx., agarre, resistencia, composición, movilidad), no un eje por prueba, y en la **escala del baremo del puesto**: 0 = rojo … 3 = listón Champions, con los anillos coloreados y Champions como circunferencia exterior. Cada eje es la media del nivel continuo (`refNivelCont`: franja + avance dentro de ella) de sus pruebas vigentes. *Cambiado el 19/09/2026 por decisión de Daniel: con 22 ejes "hay tantos puntos que es poco visual y satura".* El radar por z-score sobrevive como plan B cuando el jugador no tiene baremo de puesto. Las etiquetas Fuerte / A mejorar de debajo **siguen siendo frente al equipo** y lo dicen: son la pregunta complementaria al baremo |
| Semáforo de capacidades | Nivel **absoluto contra el baremo del puesto** (`refNivel`), no contra la media del equipo: por capacidad, media de los niveles (0 rojo … 3 Champions) de sus pruebas vigentes, redondeada. *Cambiado el 19/09/2026 por decisión de Daniel: comparando con el equipo, un jugador con buenos valores absolutos salía ámbar en todo solo por estar rodeado de compañeros parecidos (el caso de Alfredo).* La versión por z-score sobrevive como `fichaSemaforoZ` y solo se usa si el jugador no tiene ninguna prueba con baremo de su puesto. Afecta a la ficha y a Perfil físico › Gráficos |
| Ficha exportable — cabecera y lenguaje | Cabecera única (club + jugador + nota global en un solo bloque oscuro), títulos de sección en frase y no en versalitas, y las barras de Champions con la escala real del puesto siempre en el mismo sentido: rojo a la izquierda, Champions a la derecha, espejando las pruebas de menos-es-mejor. *Rediseño del 19/09/2026 por decisión de Daniel: "mucho dato y poco atractivo de ver para el jugador".* Los anillos WHOOP salieron de la ficha porque la nota global subió a la cabecera; el helper `wRing` sigue en el código |
| Valoraciones vigentes | Solo cuentan las pruebas con alguna medición desde el **1 de julio** (arranque de la 26/27, `TEMP_INICIO`). Las que no se han medido esta temporada quedan fuera del baremo, del resumen del jugador y de las tarjetas. *Decisión de Daniel el 15/09/2026: las marcas de hace dos y tres años ensuciaban el baremo* |
| Cuadrantes — umbral | 58 |
| z-scores valoraciones | Escalado robusto por MAD, suelo del 2 % para evitar z absurdos |
| TSA — composición | Media **ponderada de las tres capacidades**, **un tercio cada una** (`TSA_W`). *Repartido a partes iguales el 17/09/2026 por decisión de Daniel; el 15/09 se había probado con Fuerza 40 · Explosividad 35 · Condición 25*, más los kg de masa muscular, que antes quedaban fuera. *Cambiado el 15/09/2026 por decisión de Daniel; antes era la media simple de los z de los 22 tests, así que el peso lo decidía cuántas pruebas había de cada capacidad: 11 de explosividad mandaban el 50% de la nota y los extremos ocupaban las 4 primeras plazas* |
| TSA — progreso | Componente extra con peso 15% (`TSA_W_PROG`): avance medio **en desviaciones típicas** desde la primera valoración de la temporada, normalizado contra el del grupo. **No se usa el % de cambio para puntuar**: se dispara con bases pequeñas (la asimetría de tobillo de Josu pasó de 0,3 a 6 = −1900%). El % sí se muestra al jugador, acotado a ±40% por prueba y descartando bases menores de 1 |
| TSA — nota sobre 100 | Curva logística `tsaEscala`: **40 + 55/(1+e^(−2,6·TSA))**. Suelo 40, techo asintótico 95, máxima pendiente en el centro. *Cambiado el 21/09/2026 por decisión de Daniel: antes era `TSA·10+50` y, como la dispersión del TSA es de 0,4, los 19 jugadores cabían entre 39 y 56 y una mejora real movía dos puntos. Ahora van de 43 a 86.* No cambia el orden del ranking ni ninguna comparación, solo la escala con la que se enseña |
| TSA — ranking por puesto | Vista añadida el 17/09/2026: mismo TSA, comparado solo dentro del puesto. **No cambia ninguna nota.** Existe porque a los porteros se les puntúa con pruebas de jugador de campo y cierran la tabla global (45 y 39); con el baremo por puesto salen aún peor (49 y 25), así que el problema no es el cálculo sino con qué se les mide. **Pendiente de decisión de Daniel: qué pruebas valorar a un portero** |
| TSA — resto | Bloqueado |
| contactFactor | Bloqueado |

### 2.1.1 Umbrales de sesión · modelo interno del club

> *«Recuerda actualizar los umbrales de sesiones siempre con nuestros propios datos a medida que vamos teniendo más datos.»* — Daniel, 15/10/2026
> *«Un modelo de preparación física interna, en el que calculemos nuestros umbrales y esos umbrales no sean fijos, sino que vayan moviéndose con el tiempo a medida que lo hace el equipo.»* — Daniel, 16/10/2026

**`SESSPEC` no se toca nunca.** Es la línea de partida y el sitio al que se vuelve. La calibración vive aparte en `bmnava_sespec` y se lee **siempre por `SESEF()`** — único punto de lectura en toda la app, igual que `lbEsDe` con los bloques. Quitar la calibración devuelve el estado anterior sin tocar una línea de los consumidores: `classifySession`, `bandMeter`, `hrpBandas`, `calZonaNivel` y la banda del Resumen.

**Cortes: p33 · p66 · p90 de las propias sesiones.** Los dos primeros porque el nivel de sesión ya se reparte en tercios por decisión de Daniel (12/09/2026) y sería incoherente que las bandas dijeran otra cosa; el tercero marca la sesión excepcional, que es lo que la cuarta banda significaba.

**Desde el 19/10/2026 se aplica SOLA** (`sesCalAuto`, llamada desde `hrEnsure` en cuanto hay datos de pulso cargados). Daniel lo pidió dos veces —el 15/10 y el 19/10: *«usa nuestros propios umbrales y percentiles siempre»*— y hasta entonces la calibración calculaba, enseñaba el impacto y esperaba a que alguien pulsase: llevaba sin aplicarse y toda la app leía las bandas de partida. **Lo que cambió es quién decide, no las salvaguardas**, que siguen como puertas en vez de como permisos. Se puede automatizar sin red porque es **reversible**: `SESSPEC` no se toca nunca y «Volver a los de partida» (`sesCalQuitar`) deja la app exactamente como estaba.

**Tres frenos, y son lo que evita el destrozo:**

- **No se mueve sin muestra ni sin dejar rastro.** Cada aplicación queda fechada en `hist` con `auto:true` y **cuántas sesiones del histórico cambian de nivel**, y el panel sigue enseñando el antes y el después. Mover estos umbrales reclasifica todo el histórico de golpe, así que tiene que quedar auditado.
- **No calibra con pocas sesiones**: `SESCAL_MIN`=20 con al menos cinco pulsómetros —el listón de `hreqDatos`—. Un percentil sobre seis sesiones es ruido con aspecto de umbral.
- **No se recalcula a cada sesión**: vuelve a proponer con `SESCAL_PASO`=10 sesiones nuevas. Un umbral que se mueve cada día no es un umbral.

**Infografía A4 apaisada**, botón en el mismo panel: 1123×794 px = A4 a 96 ppp, tokens fijados a claro como la ficha del jugador porque es un documento impreso. Se genera **dentro de la app y no como archivo aparte a propósito**: así sale siempre con las sesiones y la fecha de quien la abre, no con una foto de los números de un día. Exporta a PNG (`exportNodePNG`) y tiene `@media print` con `@page{size:A4 landscape}`.

**Sigue el lenguaje gráfico del modelo v1.0 del club** (v403, Daniel aportó su lámina del año pasado): semáforo por nivel, azulejos de zona con el numeral fantasma y el corredor, cuatro tarjetas pastel por métrica y una columna con «qué hace que una sesión sea baja, media o alta». La lámina nueva es la **v2.0**. Tres reglas:

- **El semáforo se dibuja con `calTraffic`**, el mismo del calendario: la lámina y la app no pueden decir cosas distintas.
- **El corredor y la sirena van en SVG, no como imagen**: tienen que salir igual en el PNG, en la impresora de cualquiera y sin conexión.
- **El violeta del cuarto nivel es exclusivo de esta lámina** y significa «excepcional», no alerta: aquí el rojo ya está ocupado por el tercer nivel, que es el que el club lleva un año leyendo como «alta».
- **La tarjeta de nivel ES la fila** (v404): `.a4-row` va con `align-items:stretch`, no `center`. Con `center` las tarjetas flotaban en medio de una fila de 212 px y sobraban 110 por fila, 330 en toda la lámina — que es lo que Daniel vio como «muy mal optimizado, se ve muy pequeño». Ahora sobran 22, que son el borde y el relleno.
- **El cuerpo de los rangos está al límite del ancho de tarjeta.** A 23 px, «11.8–16.4%» se salía de una tarjeta de 100. Si en el futuro se tocan anchos, tipografías o el número de decimales, hay que volver a medir `scrollWidth` de `.a4-lv b` contra el ancho de la tarjeta: es lo primero que se rompe.

Cada calibración aplicada queda fechada en `hist`: un modelo que no sabe cuándo cambió no se puede auditar. **La corrección manual de nivel sigue mandando por encima de todo esto.**

**Lo que midieron los datos del club (68 sesiones, feb–may 2026):** Z5 pasa de 1/3/5 a **0,4 / 1,1 / 2** — o sea que los umbrales de partida estaban muy por encima de lo que el equipo hace de verdad en Z5. Z4 de 8/15/20 a **8,5 / 11,8 / 16,4**. 26 de 68 sesiones cambiarían de nivel.

**Ojo al leer el reparto final**: el nivel de sesión es el **máximo** de los tres criterios de zona, así que calibrar cada métrica por separado a tercios **no** da un reparto de tercios (en esa muestra: 18/39/11 → 16/21/31). Por eso el panel enseña el reparto resultante y no solo los cortes.

**CMJ y demás tests están excluidos del readiness a propósito.** No los incorpores.

### 2.2 Escala de wellness

**1 = óptimo · 5 = peor.** Nunca invertir. Si un cálculo parece dar la vuelta a la lógica, revisa el signo antes de tocar la escala.

### 2.3 Semántica de color

| Color | Uso exclusivo |
|---|---|
| Rojo `#e23b32` | **Solo alertas**, nunca decorativo ni en gráficos neutros. **Dos excepciones, las dos autorizadas por Daniel y las dos significan «mucho», no «peligro»**: el %Z4+Z5 de la casilla del mes y de la lámina (15/10/2026), donde el rojo es coherente con el ALTA del semáforo de al lado; y el **grado del desvío** de `calDesvio` (20/10/2026), donde quiere decir «muy lejos de lo que se pidió». En la lámina conviven las dos escalas verde/ámbar/rojo —intensidad y desvío— y por eso **el pie rotula cada una** |
| Oro `#e8b04b` | **Solo sidebar** |
| Azul EHF `#15224a` + dorado `#c9a227`/`#f0d98a` | **Solo el nivel Champions** del Perfil físico. Tomados del logo de la EHF Champions League. *Autorizado por Daniel el 15/09/2026; no confundir con el oro del club, que sigue siendo exclusivo del sidebar* |
| Índigo `#3056c4` | Color de acción (botones, enlaces activos) |

### 2.3.1 Borrados y sincronización

La fusión de Supabase conserva **lo que está en un lado y no en el otro**, así que un borrado sin rastro reaparece desde la copia del servidor en la siguiente actualización. Para eso están las tumbas (`bmnava_tumbas`, `LS_TUMBAS_OK`): al borrar se anota el registro, y lo que tiene tumba se retira al leer, al fusionar, al bajar y al subir.

**Un array sin objetos es un vector, no una lista.** `syFusionarListas` unía por identidad, y la identidad de un número es su propio valor, así que los repetidos se descartaban: los cinco tiempos por zona de Polar `[1969,658,230,0,0]` se quedaban en cuatro y perdían la Z5, y `[900,600,900,300,0]` perdía el segundo 900 **y descolocaba el resto**, de forma que la Z3 pasaba a valer lo de la Z4. Ocurría en cuanto la misma sesión existía en dos sitios con cualquier diferencia. Desde el 22/09/2026 un array de primitivos se elige entero. Lo que se corrompió antes **no se reconstruye** —si las zonas perdidas eran interiores, los valores están desplazados y no hay forma de saber cuáles—, así que las sesiones afectadas se señalan en la lista de sesiones cargadas para volver a subirlas.

**Al añadir un bloque nuevo al sistema de tumbas hay que darle identidad.** Los registros se identifican por `id`/`_id`; los de Polar no tienen, y se identifican por `fecha|etiqueta|jugador` (`lsHrId`), igual que ya hacía `syClaveRegistro` en la fusión. *No se les puede añadir un campo `id`*: cambiaría la clave de fusión y cada registro que ya está en el servidor sin `id` se duplicaría.

Dos reglas que acompañan a cada bloque con tumbas:

- **`LS_TUMBAS_NO_DIFF`**: los bloques que se reescriben enteros desde memoria (Polar) no anotan tumbas por diferencia, solo desde el borrado explícito. Si la memoria viniera incompleta, el diff anotaría como borrado lo que simplemente no se había cargado, y una tumba errónea borra para todos.
- **Una tumba mata el registro que había, no el que llegue después.** Los registros de Polar llevan sello `upd` con la hora en que se cargaron, y la tumba solo se aplica si el registro es anterior a ella. **El perdón local (`lsPerdonarTumbas`) NO basta por sí solo**: las tumbas se fusionan por unión, así que el servidor devuelve la suya en la siguiente bajada y vuelve a borrar. El sello viaja con el registro y sobrevive a eso. El sello se pone al cargar y `hrPersist` lo conserva tal cual — **si cada guardado lo refrescara, ninguna tumba volvería a valer**.

*Polar entró en el sistema el 22/09/2026: hasta entonces borrar una sesión solo valía hasta la siguiente sincronización.* **Ese mismo día la primera versión de las tumbas de Polar borró una sesión buena**: Daniel borró la sesión equivocada del 22, volvió a subir la correcta con la misma fecha y etiqueta, y la tumba se la llevó en el siguiente arranque. De ahí el sello `upd` y la purga única `bmnava_tumbahr_purga`, que retira las tumbas de Polar creadas por la versión sin sello.

### 2.4 Regla anti-solape (médico ↔ disponibilidad)

Los estados de lesión los gobierna **exclusivamente el módulo Médico**. Disponibilidad los refleja en **solo lectura**, con el indicador `🔒 desde Médico`. `availMark()` debe rechazar la marca si existe un episodio médico abierto.

### 2.5 Nombres reservados

- Persistencia médica: `medDbLoad` / `medPersist`, almacenando en `bmnava_meddb`.
- **`medLoad` está ocupado.** No lo reutilices.
- Nunca declares `medPersist()` dos veces: ya pasó una vez y la segunda declaración sobrescribió a la primera, dejando el módulo médico sin guardar nada durante días.

---

## 3. Filosofía de diseño

> "Superintuitivo, visual a simple vista."

- Anillos tipo WHOOP (`ring()` helper), semáforos, tarjetas blancas flotantes sobre lienzo gris, sombras suaves, KPIs grandes.
- Píldoras semánticas tranquilas (verde/ámbar/rojo).
- Se rechazaron explícitamente los layouts saturados de gráficos en favor de anillos e indicadores de un vistazo.
- Tipografía: Inter (Google Fonts), **en una sola petición** junto a Inter Tight y JetBrains Mono.
- **Escala tipográfica (v377)**: seis escalones y nada entre medias — `--fs-hero` 34 · `--fs-h1` 24 · `--fs-h2` 17 · `--fs-body` 14 · `--fs-sm` 12,5 · `--fs-xs` 11. Antes había 25 tamaños distintos solo en el Resumen, 15 de ellos entre 7,5 y 14 px: con todo en la misma banda no hay jerarquía. Lo nuevo usa los tokens.
- **Aire**: panel 22 px de padding, 18 de separación; en móvil 16 y 14. El bloque que antes se llamaba "modo compacto" los tenía en 14 y 12.
- **Elevación**: la sombra de los paneles es `--lg-shadow`, no `--e1` — las reglas del vidrio la imponen con `!important`. Contenida a propósito: si todo flota, nada destaca. La sombra grande se reserva para lo que se abre encima.
- **Cabecera de panel**: 17 px, peso 600, **sin raya debajo**. El aire separa mejor que una línea.
- **Modo oscuro (v378)**: el bloque `html[data-theme="dark"]` **tiene que redefinir los colores semánticos**, no solo las superficies. Verde, ámbar, rojo y el azul de acción están elegidos para fondo blanco y sobre un lienzo casi negro quedan por debajo de 0,4 de luminancia: se leen como manchas apagadas. En oscuro van subidos de luz (`--ok:#30d47f`, `--warn:#ffb224`, `--bad:#ff5f52`, `--accent:#6d8cff`). **La ficha exportable los fija a los valores claros**, porque es siempre un documento en claro.
- **Al cambiar de tema hay que tirar los gráficos** (`themeRepaint`): Chart.js no repinta porque cambien variables CSS, así que los ejes se quedaban con el gris del tema anterior. Y `rerenderCurrent` cubre todas las vistas — ojo, los ids son `v-tests`, `v-estado`, `v-cal`, `v-alertas`, `v-jugadores`; `go('tsa')` **no existe** y cae al Resumen sin avisar.
- **El cambio de tema no funde el color del texto**, solo los fondos: fundir el texto deja un tercio de segundo de gris lavado que parece que la aplicación se ha roto.
- **Nada de colores escritos a mano en el CSS o en línea desde JS.** Cada hexadecimal suelto es un punto que no vira con el tema: así había 132 elementos ilegibles en oscuro.
- **Probado y descartado (23/09/2026)**: subir el readiness del equipo a un bloque protagonista a ancho completo arriba del Resumen. A Daniel no le convenció y se volvió al anillo de 104 px dentro de la primera columna. No reproponerlo.
- **El fondo del modo oscuro es suyo (v380)**: `--sheet-grad` se declaraba **una sola vez**, para claro, y termina en `linear-gradient(180deg,#f2f4f9,#e9edf4)` — un gris claro que en oscuro se pintaba igual sobre el lienzo, con los blobs a las opacidades del claro encima. Eso era la película gris lavada que hacía que el modo oscuro se viese mal por mucho que se arreglaran los tokens de texto. **Cualquier token de fondo que se añada hay que declararlo en los dos temas.**
- **Acabado (v381)**: micrográfico de 14 días y conteo de la cifra en los seis recuadros del Resumen (`sparkline()` y `animateKPIs()` ya existían y no se usaban ahí); filete de 1 px entre elementos de lista en vez de aire; línea que cruza hasta el borde en los rótulos de sección; estados vacíos con icono, frase y acción en vez de texto gris suelto; y relleno en degradado bajo las líneas de los gráficos de **una sola serie** — con dos o más superpuestas embarra y no se aplica. **La animación de las cifras la lanza cada bloque al terminar de pintarse**, no `go()`, y va por el helper común `cifraAnim(valor)`, que envuelve solo el número y deja quieto el sufijo. Está en Resumen, Cargas (grupal, por puesto e individual), Pulsómetros y Parte wellness.
- **Arco de los anillos animado (v384, `animarAnillos`)**: los de `conic-gradient` se repintan por fotograma —no hay transición CSS para el ángulo de un cónico— y los de SVG se interpolan solos con `stroke-dashoffset`. **El marcado lleva SIEMPRE el valor final y la animación solo lo rebobina** (v386). Al revés —marcado vacío y el valor final puesto por JavaScript— los anillos de «A vigilar» se quedaron sin relleno: su panel lo pinta una función que no llamaba al animador, y nada se lo ponía. Con esta regla, un anillo no puede quedarse vacío aunque nadie lo anime. Los SVG se animan **solo con CSS** (`@keyframes arcIn`, que parte de `var(--arc-c)`), así que no dependen de ningún JavaScript; los cónicos los rebobina `animarAnillos` donde se le llama, y donde no, salen estáticos y correctos. **El anillo de la ficha exportable (`wRing`) queda fuera a propósito**: html2canvas dispara la captura de inmediato y saldría un arco a medio dibujar. Ojo: el mismo anillo SVG está copiado en tres sitios del archivo: la tira del Resumen la pinta `renderTeam()` cuando llegan los datos, casi siempre después de `go()`, así que se animaba un marcado que todavía no existía. Y se anima el número aunque lleve sufijo (`16 / 19`, `100%`): va envuelto en su propio `<span data-count>`. **Un micrográfico solo se dibuja si hay serie real y con variación**: nada de series planas ni inventadas para rellenar el hueco.
- **El microciclo es un apoyo, no el protagonista (v394)**: Daniel dijo que «ocupaba mucho y decía poco». El perfil baja a 46 px de alto, el bloque de partido se afina, y **la proyección del ACWR se pliega y solo se abre sola cuando hay alguien fuera de la banda** — ocupar media pantalla para decir «no pasa nada» es justo lo que estorbaba. La lista de fuera de banda se corta en seis y dice cuántos quedan. Las explicaciones largas viven en el `title`, no debajo del bloque: en móvil ocupaban siete líneas bajo algo que se entiende solo
- **La casilla del mes enseña el semáforo Y el % de desviación (v397)**: el segundo nivel de v393 se llevó la desviación al hover y Daniel lo pidió de vuelta — «no me gusta que no se vea la info en los cuadrados». En reposo: día, semáforo, grado, duración, contacto, bajas **y el % plan vs real**. Al hover siguen los chips de evento, la barra de carga real y las citas
- **Calendario (v393)**: el microciclo se lee como un **perfil de etapa** —la altura de la barra ES la carga, así que una semana plana se ve plana sin mirar un número—; el **próximo partido** es el bloque más grande del panel, con rival, competición y cuenta atrás, porque es el ancla de todo lo demás. La celda del mes pasa a **dos niveles**: en reposo queda qué día es, qué intensidad, cuánto dura, si hay partido y si hay bajas, y el resto —chips de evento, carga real, desviación, citas— aparece al pasar por encima en una **capa absoluta**, nunca empujando: si la celda creciera, al pasar el ratón se movería la rejilla entera. Sin ratón (`@media (hover:none)`) el segundo nivel no existe: en móvil el día se abre de un toque y ahí está todo. *Antes la casilla tenía nueve datos compitiendo.* El cambio Mes↔Semana va con un fundido de 150 ms, solo opacidad y cuatro píxeles, y respeta `prefers-reduced-motion`
- **Capa Apple · superficies (v421)**: lo que de verdad se nota. Fondo plano, tarjetas opacas, **Large Title de 34 px** en la cabecera de cada vista (`.pagehead h1`; ojo: ya era 30/800, por eso la v420 apenas cambiaba nada), más aire (panel 26 px, separación 20) y separadores de lista que no llegan al borde de la tarjeta. **Lección**: la v420 fue pulido de tokens y el cambio de tipografía es **invisible por construcción**, porque Inter se diseñó para imitar a SF Pro. Si se pide «que parezca Apple», lo que hay que mover son las **superficies**, no la tipografía.
- **Medir el contraste con `getComputedStyle` en el panel del navegador MIENTE.** Al auditar la v421 salieron 103 regresiones a 1,07 —texto casi invisible— que no existían: `getComputedStyle` resolvía valores del esquema oscuro para algunos elementos aunque se pintasen en claro, porque el sistema está en oscuro y la app fuerza claro. **El píxel pintado detrás de «Actualizar» era blanco.** La comprobación buena es muestrear el píxel con `html2canvas`, no leer el estilo calculado.
- **Capa Apple (v420)**: bloque **aditivo** al final de la hoja principal, pedido por Daniel el 19/10/2026 («estilo Apple en toda la página, solo visual»). 180 líneas añadidas, **ninguna borrada ni modificada**, y todas dentro de `<style>`: quitando el bloque, la app vuelve exactamente a como estaba. Cinco cosas: **la tipografía del sistema** (`-apple-system` primero, Inter de respaldo fuera de Apple), **la curva de Apple** en vez de la de Material (`cubic-bezier(.32,.72,0,1)`, que es casi todo lo que hace que «se sienta» Apple), **elevación más suave y alta**, **controles con los tres niveles del sistema** (relleno / neutro / plano, con el encogimiento al pulsar) y **separadores de medio punto**. El cristal de los paneles NO se toca: solo se refuerza en cabecera y sidebar, que es donde la guía lo pide (*«do NOT use Liquid Glass for content layer elements»*). **Los tres documentos imprimibles quedan fuera y fijados a Inter** —las dos láminas ya la declaraban, la ficha se fijó a mano—: son papel, están medidos al píxel y tienen que salir iguales entre sí.
- **Dos trampas que dejó esa capa, y que se verificaron**: `.seg` está reutilizada para el control segmentado **y para las barras de la tira de readiness**, así que una regla a `.seg` a secas las toca a las dos; y el segmento activo iba relleno de acento con **texto blanco**, de modo que cambiarle solo el fondo a claro dejó blanco sobre blanco —contraste 1:1, invisible—. **El color del texto va siempre junto al del fondo.** La forma de comprobarlo fue medir el contraste de toda la app contra la versión anterior: 603 hallazgos antes, 603 después, **0 nuevos y 0 peores**.
- **El cristal de las TARJETAS y los blobs del fondo se retiraron el 20/10/2026**, por decisión de Daniel: *«no ha cambiado casi nada»* tras la primera pasada de estilo Apple. Se le explicó que el degradado azulado con manchas de color y las tarjetas translúcidas eran justo lo que impedía el estilo que pedía —eso es glassmorphism de 2021; Apple usa fondo plano, tarjetas opacas y cristal solo en barras y sidebar— y **levantó él mismo el bloqueo que había puesto el 23/09/2026**. Ahora: fondo `#f2f2f7` plano (negro en oscuro), tarjetas opacas separadas por sombra, y **el cristal se conserva y se refuerza en cabecera y sidebar**, que es donde la guía lo pide. Reversible: borrando el bloque v421 vuelve el cristal. **Los semáforos siguen sin cambiarse por anillos.**
- **Móvil es de primera clase**, no una adaptación. Carlos consulta el dashboard desde el teléfono.

**No hagas rediseños especulativos.** No cambies nada que no se haya pedido. Si detectas algo mejorable, dilo; no lo implementes por tu cuenta.

---

## 4. Arquitectura

### 4.1 Stack

Chart.js 4.4.1 · PapaParse 5.4.1 · html2canvas 1.4.1 · Inter · `localStorage`.

### 4.1.1 Rendimiento · lo que de verdad cuesta

Medido el 20/10/2026 con los datos del club (726 sesiones de Polar, 2.500 RPE, 2.876 de wellness):

- **El código no es el problema.** `renderAll()` tarda 218 ms y cambiar de vista entre 19 y 29 ms. El HTML (2,69 MB) se parsea en 64 ms.
- **El problema es la red.** Las cuatro hojas de Google suman **~4,3 s** y la última no acaba hasta el segundo 3,7. Antes eran cinco peticiones: **la hoja de valoraciones se pedía dos veces a la vez**, una desde `connect()` y otra desde `vhAutoload()`, en el mismo milisegundo. Desde v422 comparten la promesa **en vuelo** (`vhTexto`). **No se cachea el resultado a propósito**: cachearlo dejaría a «Actualizar» sin traer datos nuevos.
- **Las fotos se repiden mucho** y **16 de ellas son de jugadores que ya no están** (plantilla anterior). En local no se cachean porque `python -m http.server` no manda cabeceras; en GitHub Pages sí. La parte real del desperdicio son esas 16 de la primera carga.

**Antes de optimizar nada más, medir.** La primera sospecha —que lo nuevo de la sesión ralentizaba— era falsa: el archivo creció 119 KB (+4,6 %) y las operaciones siguen por debajo de 30 ms.

### 4.1.2 Cargas › RPE se congelaba al abrirlo

Daniel, 20/10/2026: *«no me deja entrar a cargas>RPE, le hago click y la aplicación peta»*. No petaba: **bloqueaba el hilo 2,1 s** y el navegador se quedaba sin responder. Dos funciones puras que se recalculaban en bucle:

- **`dailyAgg(name)`** recorría los 2.500 registros de RPE **en cada llamada**, y `contDailyTo` la llama una vez por jugador y día: 3.529 veces por render para 18 jugadores, casi **nueve millones de comparaciones**.
- **`hrpDatos`** reclasificaba la sesión y rastreaba `STATE.hr` y `STATE.rpe` enteros por cada fila: **11.616 clasificaciones** de unas 70 sesiones distintas. **El nivel de una sesión depende de la SESIÓN, no de quién la mire.**

Las dos están cacheadas desde v423, con la caché atada a la referencia y el tamaño del array de RPE y tirada además desde `hreqInvalidar`. **2.138 ms → 956 ms** (mediana de 7 pasadas).

**Cómo se comprobó que no cambia ningún número**: una huella de todo lo que devuelve `hrpDatos` para los 18 jugadores (día, nivel, RPE, contacto y UA de cada fila) antes y después. Mismo hash, `-73473890`, 716 filas. **Un cambio de rendimiento que no se verifica contra la salida anterior es un cambio funcional sin querer.**

**v424 · primero se pinta, luego se calcula lo caro.** `renderCargaDecide` y `renderLesCarga` se ejecutaban ANTES del render normal, así que la pantalla esperaba a los dos. Ahora se aplazan a un `setTimeout(0)`: el render acaba, el navegador pinta y los bloques se rellenan después, con su propio «Calculando…» solo si están vacíos —al repintar ya hay contenido y cambiarlo sería un parpadeo gratuito—. **`setTimeout` y no `requestAnimationFrame` a propósito**: en una pestaña de fondo rAF no se dispara y los paneles no llegarían a rellenarse nunca. **956 ms → 362 ms de bloqueo**, y el contenido de los cuatro paneles da el mismo hash (`290334952`).

Queda pendiente: lo que sobra está casi todo en `lesCarga` y `weekly`. `contDailyTo` **no se cacheó a propósito**: devuelve objetos que algún consumidor podría modificar, y 250 ms no compensan ese riesgo.

### 4.2 Fuentes de datos

**Lectura (Google Sheets publicados como CSV, `pub?output=csv`), vía `CONFIG.sources`:**
- Wellness diario
- RPE / sRPE
- Plantilla
- Valoraciones físicas

**Escritura local (`localStorage`):**
- Registros médicos (`bmnava_meddb`)
- Calendario de entrenamientos
- Datos Polar
- Duraciones de sesión
- Cuadrantes
- Fotos de jugadores
- Pruebas isocinéticas (`bmnava_iso`) y sus referencias (`bmnava_isoref`)

> **Nota crítica**: el protocolo `file://` bloquea todos los `fetch`. Las conexiones a Sheets solo funcionan en el despliegue hosted, no abriendo el archivo en local. Para probar en local, levanta un servidor: `python3 -m http.server`.

### 4.3 Persistencia compartida (pendiente)

Hoy todo lo local vive en el `localStorage` de cada usuario y es **invisible para los demás**. Virginia no ve lo que registra Daniel y viceversa. La solución acordada es **Supabase con políticas RLS**; el SQL de configuración y la guía ya están entregados, pero Daniel aún no ha confirmado el alta.

### 4.3.0 «Exportar PNG» de la semana (retirado de la barra)

Desde el 19/10/2026, por decisión de Daniel, el botón **«Exportar PNG»** del calendario semanal (`calExportWeek`, que sacaba la tarjeta de la semana tal y como se ve) **no aparece en la barra**: tener dos botones de exportar al lado solo obligaba a elegir, y la lámina A4 lleva lo mismo más el microciclo y los objetivos de pulso. **La función sigue entera en el código**; para recuperarla basta devolver su botón a `cal-wk-tools`. El botón que queda se llama **«Exportar semana · A4»** y conserva a propósito la palabra «Exportar», que es la que Daniel busca. **No se ha borrado nada.**

### 4.3.0b Cargas › RPE (retirado de la navegación)

Desde el 20/10/2026, por decisión de Daniel: *«apenas lo uso, es la realidad. Poca información útil para mí»*. Es el tercer intento sobre esa pestaña y seguía sin usarla. **El diagnóstico, para no repetirlo: Calendario y Pulsómetros le dicen qué hacer hoy; Cargas › RPE describía lo que ya pasó.** Un quinto gráfico no arregla eso.

Lo que sí usaba se mudó a **Cargas › Resumen**: **«Quién necesita algo hoy»** (`cgaten-card`) y **«Plan contra real por jugador»** (`cgplan-card`). *El 20/10/2026 se pusieron por error en la portada (`v-equipo`) y Daniel lo corrigió en el acto: «el resumen que hay dentro del apartado de cargas, no el resumen general». La portada se devolvió byte a byte a como estaba.* **«Resumen» es ambiguo en esta app: hay el de la portada y el de dentro de Cargas. Preguntar cuál.** **«Carga contra minutos jugados»** se rehízo entera y vive en **Pulsómetros** (ver abajo). **«Carga antes de las lesiones»** (`lesCarga`) se queda sin sitio en la navegación: el código está entero y basta con devolverle un contenedor.

Como con Cuadrantes: **no se ha borrado nada**. Para reactivarla, devolver `'rpe'` a `CARGAS_TABS` y a `CARGA_PANES`, y los contenedores a `carga-grupal`. **Los ids no se duplican a propósito**: si existieran en los dos sitios, `getElementById` cogería el primero y el panel se pintaría en la pestaña oculta.

### 4.3.1 Cuadrantes (retirado de la navegación)

Desde el 11/09/2026, por decisión de Daniel, **Cuadrantes no aparece** ni en las pestañas de Cargas ni en el Resumen: no le estaba dando uso. El módulo sigue entero en el código, con sus datos (`bmnava_quadrants`), sus importaciones y su enganche con el Calendario. Para reactivarlo, devolver su entrada a `CARGAS_TABS` y a `CARGA_PANES`. **No se ha borrado nada.**

### 4.4 Navegación (estructura v180+)

```
EQUIPO              Resumen · Calendario
CARGA               Cargas · Pulsómetros
ESTADO DEL EQUIPO   Disponibilidad · Médico · Parte wellness
RENDIMIENTO         Perfil físico · Jugadores
SISTEMA             Conexión
```

- Pulsómetros es entrada de primer nivel: `go('hr')`.
- Los tres ítems de Estado comparten `v='estado'` con enrutado por pestañas mediante `sbBtn(v,l,tab)`, que genera `data-v="estado:TAB"`.
- **Alertas está fusionada dentro de Disponibilidad**, no es entrada de menú.

Pestañas de Cargas: `Resumen | Cuadrantes | RPE | Pulso · Polar`. RPE despliega subnavegación (Grupal, Individual, Por posición).

---

## 5. Plantilla canónica (temporada 26/27, 18 jugadores)

```
Alex Ugalde
Alfredo Otero
Baptiste Audiffred
Brais González Blanco
Clemet Esparon
David Fernández
David Roca
Dzmitry Patotski
Javier Carrión Ortiz
Josu Arzoz Azofra
Maiko Vázquez
Marcos Da Silva
Mateus M. Buda
Óscar Marugán Villagrán
Pablo Herranz García
Pancho Ahumada
Paulo Moreno
Tahu Lufuanitu
```

En el roster se usan nombres cortos canónicos (p. ej. "Óscar Marugán", "Pancho Ahumada").

### 5.0 Bajas · jugadores fuera del club

| Jugador | Fecha | Motivo |
|---|---|---|
| Hugo Lima | 01/10/2026 | Expulsado del club. Daniel pidió sus datos fuera de toda la aplicación |

La lista vive en `BAJAS` y se comprueba con `esBaja(nombre)`, **la misma regla de nombres que `canonicalName`**: dos palabras coincidentes o una de cinco letras o más. Así «Hugo Lima», «Lima, Hugo» y «HUGO LIMA» caen igual, y un «Hugo» suelto no arrastra a nadie que comparta nombre de pila.

**El filtro va en la lectura de `localStorage` (`lsLeer` → `bajaLimpiar`), no repartido por los módulos.** Dos razones, y las dos importan:

- Hay quince bloques guardados con forma distinta —mapas por nombre, listas de episodios, partes de fisioterapia, sesiones de Polar—. Un filtro por módulo es garantizar que el próximo bloque que se añada se olvide.
- **La fusión de Supabase une por clave, así que borrar a mano no sirve**: un mapa por nombre vuelve del servidor en la siguiente bajada, y las tumbas solo saben de registros con `id`. Filtrando al leer, vuelva lo que vuelva, ni se ve ni se reescribe.

`bajaLimpiar` no conoce la forma de ningún bloque: quita las claves de mapa que son un nombre dado de baja y los elementos de lista cuyo campo de jugador (`name`, `nombre`, `jugador`, `player`, `atleta`, `nombreCompleto`) lo sea, hasta seis niveles de profundidad.

Además se filtra en los puntos por donde entran las hojas de Google, que no pasan por `localStorage`: `ingestWellness`, `ingestRPE`, `ingestRoster`, `ingestTests`, `applyRosterLive` y `vhResolveName`. Y en los dos sitios donde el nombre se **enseñaba** aunque el dato estuviera fuera: la sugerencia de alta como jugador histórico y el aviso de «nombres sin correspondencia» de la importación de valoraciones.

**Lo que esto NO hace, y hay que decirlo cada vez:**

- **No borra las filas de las hojas de Google.** Desde la aplicación son de solo lectura. El filtro las descarta al entrar; si se quieren fuera de verdad, se borran en la hoja.
- **No borra lo que ya esté en Supabase.** Deja de verse y deja de reescribirse, pero el registro sigue en el servidor hasta que se borre allí.
- **El nombre sigue en el código**, en `BAJAS`. Es lo que hace funcionar el filtro; no se puede quitar sin quitar el mecanismo.

La foto (`fotos/<nombre>.png`) **sí se borra del repositorio**: es un archivo servido por URL y el filtro no lo tapa.

### 5.1 Resolución de nombres — es frágil

- Coincidencia por tokens exactos con umbral: **≥2 tokens coincidentes O ≥1 token de ≥5 caracteres**. Esto evita falsos positivos (`"Davide Boro"` ≠ `"David"`).
- **Hay que quitar la puntuación antes de comparar.** Un bug real: celdas con nombres separados por comas atribuían todo el registro al último nombre.
- **`"Marquinhos"` se mapea manualmente a Marcos Da Silva.**

### 5.2 Posiciones

`posGroup` normaliza con coincidencia difusa: acepta códigos (EI, LD, CE…), etiquetas detalladas en español y plurales, y mapea a las 4 categorías del club: **Porteros · 1ª Línea · Extremos · Pivotes**. `buildPlayers` envuelve la asignación en `posGroup`. `posDetailOf` devuelve la subdivisión concreta (Lateral izq., Extremo der., Central…) para mostrar en tablas individuales, mientras los filtros operan sobre las 4 categorías agrupadas.

---

## 6. Módulos

### 6.1 Carga de sesión

Separada por bloques **pista** y **gym**. Imputación corregida por sesgo para jugadores que no envían RPE. Gráficos semanales con barras apiladas planificado vs. real por tipo de sesión.

> Bug histórico: la carga se multiplicaba por el número de cuestionarios enviados. Brais aparecía con 2.730 UA en lugar de ~900.

### 6.1.1 Bloques del día

Un día tiene **tres bloques**: `pista`, `gym` y `tec` (`LB_BLOQUES`). Los dos primeros son la sesión del equipo (`LB_BLOQUES_EQUIPO`); el tercero no.

**`lbEsDe(tipo, bloque)` es la única forma correcta de preguntar si un registro cuenta para un bloque.** No se escribe a mano `bucket===b||bucket==='both'`: `'both'` significa «pista Y gimnasio» —un cuestionario que declara los dos— y **nunca** tecnificación. Mientras esa comprobación estuvo repetida a mano en cinco sitios, cualquier día con un registro de «pista y gimnasio» daba por existente también el bloque de tecnificación, y aparecían dieciocho botones de «Convocar» a un entrenamiento de mañana que no se había hecho.

### 6.2 Valoraciones físicas (z-score longitudinal)

Fuente histórica: `BM_Nava_valoraciones_fisicas.xlsx` — 1.315 mediciones, 13 jugadores, 27 tests, julio 2023 – abril 2026. Migrado desde la hoja Testing DATA (629 filas, formato ancho con fila de cabecera de grupo que exige re-encabezado).

**Problemas de datos conocidos y abiertos:**
- Formatos de fecha mezclados: 278 filas M/D/YYYY, 19 filas D/M/YYYY.
- CMJ anómalos el **2026-03-09** (se sospecha cambio de plataforma) distorsionando las líneas base. **Pendiente de decisión de Daniel: borrar o mantener.**
- Tres tests sin dirección confirmada: Test Dedo, cadena posterior, movilidad de hombro.
- Dos valores sospechosos: T-TEST 6s y ACC 3s de Óscar.
- Seis jugadores sin mediciones: Alex Ugalde, Baptiste Audiffred y cuatro más.

### 6.3 Módulo médico (v176+)

`STATE.med` persistido en `bmnava_meddb`. Soporta:
- Tipos lesión / molestia
- Selector de zona sobre silueta anatómica
- Readaptación por fases (plantilla Nolasco LCA de 4 fases)
- Seguimiento de dolor, registro de tratamientos
- Estados de disponibilidad personalizados

Pendiente: resumen en la ficha del jugador, edición de objetivos por bloque de fase, exportar episodio a PDF/PNG.

### 6.4 Polar / pulsómetros

**Polar no exporta directamente.** El flujo es: Daniel comparte capturas del iPad → transcripción manual (dorsal, nombre, FC media %, FC máx %, kcal, Z1–Z5 en hh:mm:ss) → canonicalización de nombres → verificación de que las zonas suman la duración de sesión → salida como bloque de texto delimitado por punto y coma para subir.

**Anomalías conocidas, no son bugs del código:**
- Josu Arzoz y Óscar Marugán muestran carga cardíaca sistemáticamente baja (posible rol de portero o FC máx configurada por encima de la real).
- Mateus Buda registra FC máx >100 % (máximo configurado por debajo del real).
- Sesiones con FC media <40 % y FC máx <55 % se marcan como probable fallo de sensor.
- **28/4/26: todos los jugadores muestran un desfase de un minuto en la suma de zonas. Es un bug de Polar confirmado, no un error de transcripción.**

Pendiente sin respuesta: orden de filas en la tabla de entrada manual de HR (¿por dorsal o alfabético?).

---

## 7. Flujo de trabajo

1. **Un cambio por mensaje.** No agrupes varias modificaciones sin pedirlo.
2. **Valida todo bloque `<script>` con `node --check` antes de guardar.** Sin excepción.
3. **Commit por cambio**, con mensaje descriptivo en español. El historial de Git sustituye al versionado `_NN` manual.
4. Validación visual cuando el cambio sea de layout: Playwright headless Chromium a **1440px y 390px**.
5. No especules. No añadas funciones no pedidas. No refactorices "de paso".

### 7.1 Comunicación

Español neutro, técnico, directo. **Sin adulación.** Daniel especifica requisitos exactos; impleméntalos con precisión. Si algo es ambiguo, pregunta antes de asumir.

---

## 8. Pendientes abiertos

**Esperando decisión de Daniel:**
- CMJ anómalos del 2026-03-09 — borrar o mantener
- Dirección de los tres tests sin confirmar
- Los dos valores sospechosos de Óscar
- Orden de filas en la tabla manual de HR
- Qué pruebas físicas tiene sentido valorar a un portero (hoy se les mide con las de jugador de campo y quedan últimos del TSA)

**Trabajo pendiente:**
- Configuración de Supabase (SQL y guía entregados, sin confirmar el alta)
- Fotos de jugadores: sin fondo, recorte circular grande con anillo de readiness y dorsal debajo, usando el helper `ring()` y `window.__AVATAR__` como provisional. **El nombre de archivo debe coincidir exactamente con el nombre del jugador, acentos incluidos.**
- Resumen médico en la ficha del jugador
- Isocinéticos: hoy solo cuádriceps e isquiotibiales de rodilla. Si entran otras articulaciones, `ISO_CAMPOS` y el informe hay que revisarlos; el modelo de datos aguanta
- Edición de objetivos por bloque de fase
- Exportar episodio médico a PDF/PNG
- Datos históricos: líneas base de wellness/RPE/HR de la temporada anterior para los jugadores que continúan
- Revisión del modo oscuro

---

## 9. Errores que ya se cometieron una vez

No los repitas.

| Error | Consecuencia |
|---|---|
| Datos Polar sin persistir en `localStorage` | Vivían solo en memoria; se perdían al recargar |
| El día de referencia no tenía a «hoy» como concepto | El tope del selector era el último día CON cuestionarios, así que si hoy nadie había rellenado todavía, hoy quedaba **fuera de rango**: ni las flechas ni el calendario llegaban, «Hoy» iba a la última jornada con datos, y la dirección guardaba el día visto y lo restauraba al volver a entrar. Había que ir a hoy a mano cada vez. Desde v388 se abre en hoy, el tope llega a hoy, y con la pestaña abierta de un día para otro el panel pasa al nuevo día solo (`REF_SIGUE_HOY`; elegir un día a mano lo corta, volver a hoy lo reanuda) |
| La serie de readiness empezaba a viajar DENTRO de la llamada que la pedía | `teamReadinessSerieAsync` es asíncrona, pero su cuerpo corría hasta el primer `await`: para cuando cedía el hilo, `STATE.refDate` ya estaba en el primer día del recorrido y `__RD_CALC` en true. Quien había pedido la serie —`renderTeam`— **seguía pintando debajo con esa fecha prestada**, catorce días atrás. El Resumen abría en un día viejo en **todos** los arranques, y «Últimas sesiones» se quedaba ahí. No era una carrera intermitente: era el orden fijo del arranque. Desde v389 se cede el hilo **antes** de tocar la fecha, `renderAll` se aplaza si `__RD_CALC` está puesto (`__RD_PEND`) y el recorrido repinta al acabar. **Cualquier cosa que tome prestado `STATE.refDate` tiene que ceder el hilo antes de tocarlo** |
| Pintar mientras la serie de readiness viaja por los días | `teamReadinessSeries`/`Async` recorren los últimos 14 días **moviendo `STATE.refDate`** y devolviéndolo al final. Todo lo que pinte o guarde la fecha en ese rato se queda con un día de paso: la barra decía «Viernes 18/9 · No es hoy» estando en hoy, y la URL se quedaba con esa fecha, así que al recargar abría ahí. `renderDayCtx` y `writeHash` salen si `window.__RD_CALC` |
| `renderAll()` reescribía el día de referencia en cada llamada | Lo ponía en la última fecha con wellness o RPE **cada vez**, y la sincronización en segundo plano llama a `renderAll()`: el día elegido se reescribía solo cada pocos minutos. El Resumen volvía a un día viejo con «Últimas sesiones» cortadas ahí y «Próximas» empezando ahí. Ahora el automático solo actúa en el primer pintado |
| `tnDiaLab` recibía el día ELEGIDO como «hoy» | Etiquetaba «Hoy» y «Mañana» sobre el día del selector, no sobre el real: mirando el 21 marcaba «Hoy» una sesión de hace cinco días mientras el calendario, que usa el reloj, marcaba el 26. Hoy es hoy |
| `seedHR()` sale antes de restaurar lo guardado | `applyHist()` llena `STATE.hr` con el bloque histórico, así que `seedHR()` se encuentra la lista con contenido y sale por su `if(STATE.hr.length)` **sin llegar a `hrLoadSaved()`**. Las sesiones de Polar subidas a mano no estaban en memoria al pintar el Resumen: «Últimas sesiones» enseñaba las viejas, y al abrir Pulsómetros —que sí llama a `hrEnsure()`— aparecían las nuevas. Dos pantallas con datos distintos |
| Doble declaración de `medPersist()` | La segunda sobrescribía a la primera; el módulo médico no guardaba nada |
| Carga de sesión multiplicada por nº de cuestionarios | Brais con 2.730 UA en vez de ~900 |
| Clasificación de sesión ignorando los criterios de apoyo | Clasificaba alto/medio/bajo con una lógica distinta de la que declaraba |
| Nombres con puntuación sin limpiar antes de comparar | Registros atribuidos al jugador equivocado |
| Tumba sin comparar fechas con el registro | La tumba de una sesión borrada se llevó por delante la que se cargó después con la misma fecha y etiqueta |
| Ejes de cuadrantes sin `type: 'linear'` | Escala categórica, posiciones falsas |
| Marcado que nace vacío y espera a que JavaScript lo rellene | Los anillos de «A vigilar» se quedaron sin arco: su panel lo pinta una función que no llamaba al animador. El estado final va en el marcado; la animación solo lo rebobina |
| Repetir a mano la regla de «¿este registro es de este bloque?» | Estaba escrita cinco veces como `bucket===b||bucket==='both'`. Al entrar el tercer bloque, `'both'` —que solo quiere decir pista+gimnasio— hizo que cualquier día con un registro de los dos diera por existente el bloque de tecnificación. Ahora la regla vive en `lbEsDe` y solo ahí |
| Construir algo que ya existía sin mirar antes | El panel de microciclo se escribió entero —con su propia lista de partidos y su propia regla de MD— habiendo ya `calMatchDksAll` y `calMDmap`, y con la vista de semana **ya etiquetada «Microciclo»**. Dos reglas de MD distintas habrían dicho cosas diferentes del mismo día. Antes de añadir un concepto, buscarlo en el archivo |
| Emparejar original y copia por índice al exportar a PNG | `exportNodePNG` copiaba los estilos recorriendo dos listas planas y emparejando por posición. **html2canvas inserta nodos propios en la copia** para representar los `::before`/`::after`, así que la copia tiene MÁS elementos que el original —354 contra 352 en la lámina A4— y a partir del primer nodo insertado **cada elemento hereda el color de otro**. Ya se parcheó una vez (v222, moviendo el borrado de imágenes al final): eso quitó una causa, no la de fondo. Desde v413 cada elemento lleva una marca `data-x2p` y la copia se busca por ella; las marcas se quitan al acabar, pase lo que pase |
| Contar con que html2canvas dibuje `box-shadow: inset` | **No lo dibuja: RELLENA el elemento entero con el color de la sombra.** El día de hoy del PNG de la semana salía como un bloque azul macizo que tapaba la columna. Lo sufrían `.cw-today`, `.cal-today`, `.fc-d--hoy` y la lámina A4. `exportNodePNG` tira ahora las capas `inset` —conserva las de fuera— y, cuando la capa era un simple filo (`0 0 0 Npx`), la redibuja con un borde, que sí sabe pintar; con `box-sizing:border-box` global el borde no agranda la caja |
| Dar por buena una exportación por el tamaño del lienzo | La lámina A4 se dio por verificada porque la captura medía 2246×1588 y salía en proporción A4. **El lienzo tenía la medida correcta y el contenido estaba roto.** Una exportación se comprueba mirando la imagen —o muestreando sus píxeles—, no sus dimensiones |
| Dibujar un gráfico con una constante de altura en el JS | El microciclo de la lámina A4 calculaba las barras contra un `H=118` fijo mientras el CSS dejaba que el plano creciera con la tarjeta: a 220 px de alto, todo quedó aplastado contra el eje. **Las alturas de un gráfico fluido van en porcentaje**, para que no haya dos sitios que tengan que estar de acuerdo |
| Usar lo que devuelve `calMd` como si fuera texto | `calMd(dk)` devuelve `{md,txt,partido,dir}`; el que devuelve la cadena es `calMDmap`. Usar el objeto como etiqueta pintaba «[object Object]» en el pie del microciclo y, peor, fallaba en silencio al buscar la referencia de esa posición de MD |
| Poner acentos graves dentro de una plantilla literal | Un comentario HTML dentro de un `` `...` `` llevaba `` `cargaDiferir()` `` entre acentos graves. Cierran la cadena: `SyntaxError: Unexpected identifier`. Dentro de una plantilla, los comentarios van sin acentos graves |
| Leer `STATE` como `window.STATE` | `const STATE` vive en el ámbito del bloque `<script>`, **no en `window`**: `window.STATE` es `undefined`. El chip con la fecha de nacimiento del informe isocinético no salía nunca y no daba ningún error, simplemente faltaba. Dentro del bloque se escribe `STATE` a secas |
| Dar por bueno un `<details>` que se pinta con `ontoggle` | Chrome **restaura el estado abierto de un `<details>` al recargar** y dispara su `toggle` mientras todavía está parseando, o sea antes de que exista la función que lo pinta: `ReferenceError` y panel en blanco justo para quien lo dejó abierto. El handler de la etiqueta va guardado (`window.fn && fn()`) y el bloque se pinta además desde el JavaScript si ya venía abierto |
| Guardar el nombre del jugador anidado y esperar que el filtro de bajas lo vea | `bajaLimpiar` mira los campos de nombre **del elemento de la lista** (`BAJA_CAMPOS`). `jugador` está en esa lista, pero si `jugador` es un **objeto**, `esBaja` no lo reconoce y el registro sobrevive. Las pruebas isocinéticas llevan por eso un `nombre` plano en la raíz. **Un bloque nuevo tiene que encajar en el filtro central, no traerse el suyo** |
| Escribir una regla en el consumidor y no en la función que decide | «En día de partido no se emite veredicto» estaba implementada **dentro de la lámina A4**, no en `calCumplDia`. La vista de semana del calendario, que llama a la misma función, sí juzgaba los partidos — y nadie lo vio hasta que el color pasó a graduar la gravedad y ese desvío empezó a salir en ROJO. **Una regla de negocio escrita en el sitio donde se pinta se cumple en un sitio y se incumple en los demás** |
| Dar el resultado solo en un resumen cuando lo que se mira es el día | La primera versión de «qué efecto tuvo» resumía la semana entera en una tira de cinco tarjetas. Daniel: «no lo quiero en un solo sitio, lo quiero para cada día». Un entrenador no planifica la semana, planifica el martes: **el resumen contesta a quien ya sabe la respuesta, y el que la necesita la busca en la columna del día** |
| Dos parejas Plan/Real con cifras distintas en la misma hoja | La cabecera de la lámina A4 enseñaba Plan 3.685 / Real 4.880 —la semana entera— y la tira de efectos, justo debajo, 3.055 → 4.428, que son los días con las dos cifras. Las dos son correctas y juntas son una contradicción impresa, porque nadie lee un papel buscando la letra pequeña que explica por qué el mismo par de etiquetas da números distintos. Se quitó el «Real» de la cabecera: el plan de la semana completa se sostiene solo. **Cuando dos bloques responden a la misma pregunta con criterios distintos, uno de los dos sobra** |
| Enseñar como «total» la suma de toda la plantilla | «Tiempo en zonas · acumulado de la semana» sumaba los segundos de los dieciséis jugadores y pintaba el resultado —18:33— como la cifra grande del panel. No es el tiempo de nadie: es el de dieciséis personas una detrás de otra, y además crece al poner más pulsómetros, que es justo lo contrario de lo que debe hacer una medida de carga. **Cuando se agrega a varias personas, la unidad tiene que ser una persona** |
| Un Δ% sobre una base de dos minutos | El mismo bloque comparaba cada zona contra la media de 4 semanas y enseñaba +440 % en Z5. Medido sobre el histórico del club, el Z5 de un jugador en una sesión va de 0,4 a 1,3 minutos: a esa escala el porcentaje es ruido con aspecto de medición, y el propio histórico lo demuestra (+155 %, +77 %, −100 % en semanas normales). Ya estaba escrito para el progreso del TSA y se volvió a cometer. **Donde el dato es pequeño, la diferencia va en la unidad del dato, no en porcentaje** |
| Pintar marcado con clases que no existen en la hoja | El bloque usaba `.wz-val` y `.wz-d`; la hoja declaraba `.wz-time` y `.wz-delta`. Ninguna de las dos reglas se aplicaba, así que los minutos y el Δ% iban sin ancho, sin alineación a la derecha y sin cifras tabulares: la columna de la derecha salía descuadrada y nadie lo relacionó con un cambio de nombre. **Un nombre de clase que no está en el CSS no da error: da un bloque mal puesto** |
| Fusionar un vector posicional como si fuera una lista | Los tiempos por zona de Polar perdían los valores repetidos y el resto se descolocaba; salía `NaN%` en Z5 y en Z4+Z5 |

---

## 10. Disciplina con los datos

Marca las anomalías **antes** de incorporarlas a las líneas base. Contrasta las sesiones de HR sospechosas con los datos de RPE del mismo día. Ante un valor raro, la hipótesis por defecto es error de medición o configuración, no rendimiento real — pero la decisión de borrar es de Daniel, no tuya.
