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
| Nivel de sesión — corrección manual | Manda siempre sobre el cálculo. Se guarda por clave `fecha\|etiqueta` en `bmnava_sesniv` y se sincroniza |
| Modelo de sesión del equipo | `hreqModelo`: de **RPE objetivo + contacto** (lo que se planifica en el calendario) a **objetivos de pulso** (minutos y % en Z4+Z5, FC media, TRIMP). Es el inverso del modelo individual, que va de pulso a RPE. Una sesión = un punto: se exigen 5 pulsómetros por sesión y `HREQ_MIN`=12 sesiones con pulso, RPE del equipo y contacto. El término de contacto solo entra con contacto variado **y** ≥20 sesiones: con 12 puntos, cuatro coeficientes se ajustan al ruido. **La salida son rangos, nunca cifras exactas** (centro ± error de validación cruzada), y con ajuste <20% no se dibujan objetivos, igual que en el individual. El TRIMP se modela **por minuto** y el volumen lo pone la duración planificada, no el modelo; se calcula pero **no se muestra**: las cuatro salidas visibles son minutos y % en Z4+Z5, % en Z5 y FC media (*Daniel cambió TRIMP por %Z5 el 22/09/2026*). Cada tarjeta lleva el ajuste de **su propia** salida en un punto de color, porque el %Z4+Z5 se predice bastante mejor (51%) que el %Z5 (26%). Junto al rango se muestra siempre la mediana observada de las sesiones parecidas, que es el contraste sin modelo. *Pedido por Daniel el 22/09/2026.* Vive en Pulsómetros › Equipo, **debajo de la clasificación de sesión y la semana**, y deja un resumen corto en el calendario y en las próximas sesiones del Resumen |
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
- **Arco de los anillos animado (v384, `animarAnillos`)**: los de `conic-gradient` se repintan por fotograma —no hay transición CSS para el ángulo de un cónico— y los de SVG se interpolan solos con `stroke-dashoffset`. **El arco arranca vacío, así que hace falta red de seguridad**: si la animación no corre (pestaña de fondo, que congela `requestAnimationFrame`; impresión; animaciones desactivadas en el sistema) el anillo se quedaría a cero para siempre. Por eso el SVG usa `setTimeout` y no rAF, el cónico lleva un temporizador que fuerza el valor final, y con `prefers-reduced-motion` se pinta directo. **El anillo de la ficha exportable (`wRing`) queda fuera a propósito**: html2canvas dispara la captura de inmediato y saldría un arco a medio dibujar. Ojo: el mismo anillo SVG está copiado en tres sitios del archivo: la tira del Resumen la pinta `renderTeam()` cuando llegan los datos, casi siempre después de `go()`, así que se animaba un marcado que todavía no existía. Y se anima el número aunque lleve sufijo (`16 / 19`, `100%`): va envuelto en su propio `<span data-count>`. **Un micrográfico solo se dibuja si hay serie real y con variación**: nada de series planas ni inventadas para rellenar el hueco.
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

## 5. Plantilla canónica (temporada 26/27, 19 jugadores)

```
Alex Ugalde
Alfredo Otero
Baptiste Audiffred
Brais González Blanco
Clemet Esparon
David Fernández
David Roca
Dzmitry Patotski
Hugo Lima
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
| Doble declaración de `medPersist()` | La segunda sobrescribía a la primera; el módulo médico no guardaba nada |
| Carga de sesión multiplicada por nº de cuestionarios | Brais con 2.730 UA en vez de ~900 |
| Clasificación de sesión ignorando los criterios de apoyo | Clasificaba alto/medio/bajo con una lógica distinta de la que declaraba |
| Nombres con puntuación sin limpiar antes de comparar | Registros atribuidos al jugador equivocado |
| Tumba sin comparar fechas con el registro | La tumba de una sesión borrada se llevó por delante la que se cargó después con la misma fecha y etiqueta |
| Ejes de cuadrantes sin `type: 'linear'` | Escala categórica, posiciones falsas |
| Fusionar un vector posicional como si fuera una lista | Los tiempos por zona de Polar perdían los valores repetidos y el resto se descolocaba; salía `NaN%` en Z5 y en Z4+Z5 |

---

## 10. Disciplina con los datos

Marca las anomalías **antes** de incorporarlas a las líneas base. Contrasta las sesiones de HR sospechosas con los datos de RPE del mismo día. Ante un valor raro, la hipótesis por defecto es error de medición o configuración, no rendimiento real — pero la decisión de borrar es de Daniel, no tuya.
