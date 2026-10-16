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
| Coste cardíaco | `hrEficiencia()`: **FC media ÷ RPE del propio jugador**, comparado contra su propia mediana y MAD. *Dicho sin adornos y escrito en la pantalla: no es la eficiencia cardíaca de laboratorio, que necesita carga externa medida —vatios, metros— y aquí no la hay. Es la relación entre lo que dice su pulso y lo que dice él, que es la discrepancia que sí se puede leer con estos datos.* **Cada jugador solo contra sí mismo**: Josu y Óscar tienen el pulso sistemáticamente bajo (anomalía conocida) y contra la media del equipo saldrían marcados todos los días. La lectura va sobre las **tres últimas sesiones**, no sobre una, y hace falta `HRE_MIN`=6 sesiones con pulso y RPE para tener línea base. *Pedido por Daniel el 16/10/2026 (propuesta 2.3)* |
| ¿Cumplimos el objetivo? | `hreqCumpl(key)`: cierra el bucle del modelo de sesión del equipo. El modelo decía antes de entrenar hasta dónde había que llegar; esto comprueba después si se llegó, sobre la sesión elegida en el selector de Polar. **Se compara contra lo que se planificó ESE día en el calendario** (RPE objetivo y contacto del evento), no contra lo que parezca ahora. **El objetivo es un rango, no una cifra**: «dentro» es dentro del rango, y cuando se sale se dice por cuánto. Sin plan en el calendario no hay objetivo y **se dice en vez de inventar uno**; con menos de 3 pulsómetros tampoco, porque el porcentaje describiría a un jugador. Incluye el desglose por jugador sobre el %Z4+Z5. *Pedido por Daniel el 16/10/2026 (propuesta 2.2)* |
| RPE objetivo en el calendario | Campo `e.rpe` del evento, entrada del modelo anterior. Si no se ha tocado, se hereda de la intensidad (`HREQ_RPE_INT`: baja 4,5 · media 6,5 · alta 8,2) y cambiar la intensidad la reajusta; moverla a mano manda sobre eso |
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

**Tres frenos, y son lo que evita el destrozo:**

- **No se aplica sola.** Calcula, enseña el antes y el después y **cuántas sesiones del histórico cambiarían de nivel**, y espera. Mover estos umbrales reclasifica todo el histórico de golpe.
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
| Rojo `#e23b32` | **Solo alertas.** Nunca decorativo, nunca en gráficos neutros |
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
- **El efecto cristal y los blobs del fondo no se tocan** (decisión de Daniel, 23/09/2026), ni los semáforos se cambian por anillos.
- **Móvil es de primera clase**, no una adaptación. Carlos consulta el dashboard desde el teléfono.

**No hagas rediseños especulativos.** No cambies nada que no se haya pedido. Si detectas algo mejorable, dilo; no lo implementes por tu cuenta.

---

## 4. Arquitectura

### 4.1 Stack

Chart.js 4.4.1 · PapaParse 5.4.1 · html2canvas 1.4.1 · Inter · `localStorage`.

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

> **Nota crítica**: el protocolo `file://` bloquea todos los `fetch`. Las conexiones a Sheets solo funcionan en el despliegue hosted, no abriendo el archivo en local. Para probar en local, levanta un servidor: `python3 -m http.server`.

### 4.3 Persistencia compartida (pendiente)

Hoy todo lo local vive en el `localStorage` de cada usuario y es **invisible para los demás**. Virginia no ve lo que registra Daniel y viceversa. La solución acordada es **Supabase con políticas RLS**; el SQL de configuración y la guía ya están entregados, pero Daniel aún no ha confirmado el alta.

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
| Fusionar un vector posicional como si fuera una lista | Los tiempos por zona de Polar perdían los valores repetidos y el resto se descolocaba; salía `NaN%` en Z5 y en Z4+Z5 |

---

## 10. Disciplina con los datos

Marca las anomalías **antes** de incorporarlas a las líneas base. Contrasta las sesiones de HR sospechosas con los datos de RPE del mismo día. Ante un valor raro, la hipótesis por defecto es error de medición o configuración, no rendimiento real — pero la decisión de borrar es de Daniel, no tuya.
