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
| Readiness — curva del componente carga | 100 hasta ACWR 1,0 · baja a 75 en 1,3 · cae 250/punto por encima de 1,3 · por debajo de 0,8 pendiente 160. *No es plana dentro de la banda: eso hacía el readiness insensible a la carga* |
| Readiness — umbrales | Verde ≥75 · Ámbar 55–74 · Rojo <55 |
| Readiness — techo de señal única | Una sola variable mala no puede bajar el readiness por debajo de ~54 |
| ACWR | EWMA 7:21, `ewmaChronic = 0.0909` |
| Cuadrantes — umbral | 58 |
| z-scores valoraciones | Escalado robusto por MAD, suelo del 2 % para evitar z absurdos |
| TSA | Bloqueado |
| contactFactor | Bloqueado |

**CMJ y demás tests están excluidos del readiness a propósito.** No los incorpores.

### 2.2 Escala de wellness

**1 = óptimo · 5 = peor.** Nunca invertir. Si un cálculo parece dar la vuelta a la lógica, revisa el signo antes de tocar la escala.

### 2.3 Semántica de color

| Color | Uso exclusivo |
|---|---|
| Rojo `#e23b32` | **Solo alertas.** Nunca decorativo, nunca en gráficos neutros |
| Oro `#e8b04b` | **Solo sidebar** |
| Índigo `#3056c4` | Color de acción (botones, enlaces activos) |

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
- Tipografía: Inter (Google Fonts).
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
| Ejes de cuadrantes sin `type: 'linear'` | Escala categórica, posiciones falsas |

---

## 10. Disciplina con los datos

Marca las anomalías **antes** de incorporarlas a las líneas base. Contrasta las sesiones de HR sospechosas con los datos de RPE del mismo día. Ante un valor raro, la hipótesis por defecto es error de medición o configuración, no rendimiento real — pero la decisión de borrar es de Daniel, no tuya.
