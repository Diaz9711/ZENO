# ZENO — Especificación del producto y plan de construcción

Documento para Claude Code. Léelo completo antes de escribir código.
El dueño del proyecto (Diaz) no tiene experiencia programando: explica cada paso en español sencillo, dile exactamente qué tocar en Xcode y construye una fase a la vez.

---

## 1. Qué es ZENO

Una app para personas con TDAH y neurodivergencia que **se adapta a la energía de la persona en vez de exigirle que se adapte a la app**.

No es una lista de tareas. Tres ideas la sostienen:

1. **Energía**: la app calcula sola un puntaje de energía (0–100) y propone la tarea correcta para ese momento.
2. **Presencia**: cada vez que se abre, trae a la persona al presente (fecha, edad, hoy). Combate la ceguera temporal del TDAH.
3. **Lumi**: una estrella viva, única para cada persona, que refleja su energía y la acompaña sin juzgar.

Regla de oro: **ZENO nunca pide atención, la merece.** Sin culpa, sin rachas rotas, sin números en rojo.

---

## 2. Decisiones técnicas

| Tema | Decisión |
|---|---|
| Plataforma | iPhone nativo, SwiftUI, iOS 17 o superior |
| Datos | SwiftData, todo guardado en el teléfono. Sin cuentas ni servidor en el MVP |
| Estrella y fondo | Dibujados por código (Canvas / TimelineView / shaders). Nada de imágenes fijas |
| Voz | Framework Speech de Apple para dictar tareas |
| Háptica | Core Haptics / sensoryFeedback |
| Notificaciones | UserNotifications, locales |
| Idiomas | Español e inglés desde el inicio (String Catalog) |

Si Diaz prefiere también Android, la alternativa es Flutter; confirmar con él antes de empezar.

---

## 3. Lumi, la estrella

### Cómo nace
- En el registro se piden **nombre** y **fecha de nacimiento**.
- Con esos dos datos se genera una **semilla** (hash estable). De la semilla salen:
  - la paleta de colores de la estrella y de su nebulosa,
  - la forma del halo,
  - el ritmo de respiración.
- La persona **no elige colores ni movimiento**: su estrella le toca, como una huella digital. Dos personas nunca tienen la misma.
- Lo único que elige es **la forma**: *estrella* (corazón de luz con rayos) o *esfera* (bola dorada de luz líquida). La elige al nacer su Lumi y puede cambiarla en Ajustes. *(Decisión de Diaz, 12 nov 2026.)*
- La misma semilla siempre produce la misma estrella.

### Cómo se ve
- No es una estrella de cinco puntas dibujada. Es una **estrella de luz**: un corazón dorado muy brillante que se funde en resplandor, con rayos finos y largos, un halo que respira y motas que la orbitan. *(Decisión de Diaz, 12 nov 2026. La segunda forma es la **esfera** dorada de luz líquida; cada persona elige una. Las dos nunca se mezclan, porque juntas se veían raras.)*
- **Animación única**: además de los colores, de la semilla salen el número de rayos (4 a 8), cómo laten (juntos o en ola), el sentido de giro, el ritmo de respiración, la órbita de las motas y la forma de flotar.
- Se relaciona con la marca: el sol dorado de ZENO.

### Cómo se comporta
| Situación | Lumi |
|---|---|
| Energía alta | Brillante, definida, halo amplio que pulsa |
| Energía media | Resplandor tibio, respiración tranquila |
| Energía baja | Luz tenue, flota más lento. Da permiso de descansar |
| Tarea terminada | Inhala, se encoge un instante y suelta una onda de luz cálida por toda la pantalla, con vibración suave. Dura 1.5 segundos |
| Tarea difícil terminada | Onda más amplia; queda un poco más brillante el resto del día |
| Tres tareas seguidas | Giro lento sobre sí misma |
| Terminada en día de energía baja | El fondo se calienta un poco |
| Días sin usar la app | Baja su ritmo y espera. **Nunca pierde luz como castigo** |
| La persona regresa | Se enciende un poco y ofrece una sola cosa pequeña. No muestra lo que faltó |

Lumi no habla con globos de texto ni regaña. Comunica con luz, postura y movimiento. Sin confeti, sin sonidos agudos.

---

## 4. Diseño visual

- **Fondo**: una nebulosa. Azul profundo, casi índigo, que se aclara hacia el centro en azul cielo y, pegado a la estrella, en dorado. **Nunca negro puro.** La sensación es el resplandor de una estrella naciendo. *(Decisión de Diaz, 12 nov 2026: se cambió el violeta-vino original por azulado tras compararlos en el simulador.)*
- El fondo está vivo: más luminoso y cálido por la mañana, más azul profundo por la noche, y un poco más oscuro y calmado cuando la energía baja. **La energía cambia la luz, nunca la nitidez**: la calidad visual es la misma en todo el recorrido.
- Cada persona tiene su propia nebulosa, derivada de su semilla.
- **Una sola acción por pantalla.** Mucho espacio vacío. Que abrir la app se sienta como respirar.
- **Tipografía**: fina, clara y redondeada para el texto (SF Pro Rounded). Bebas Neue solo para el logotipo ZENO.
- **Transiciones**: nunca cortes. La estrella jamás desaparece y reaparece; se mueve, se encoge y se desplaza entre pantallas como un objeto físico (matchedGeometryEffect, animaciones tipo resorte, pequeño rebote al llegar). Es un solo universo continuo.
- **Respuesta al toque** inmediata, con háptica sutil.
- **Íconos propios**, dibujados para ZENO. Nada genérico.
- Referencia de calidad: la fluidez del fondo de Apple Weather con la calma de Headspace.
- Accesibilidad: respetar Reducir Movimiento, Dynamic Type y contraste suficiente sobre el fondo.

---

## 5. Pantallas del MVP

### 5.1 Registro
1. Nombre.
2. Fecha de nacimiento.
3. Tres preguntas de cronotipo: a qué hora te despiertas, cuándo te sientes más despierto, cuándo te apagas.
4. Nace la estrella: animación de la nebulosa condensándose en Lumi. Es el momento más importante de la primera impresión.
5. La persona elige la forma de su Lumi, estrella o esfera, viéndolas en vivo. Una sola decisión, sin respuesta incorrecta.

### 5.2 Momento de presencia (al abrir la app)
- Fondo de nebulosa, Lumi respirando en el centro.
- Aparecen tres líneas, una por una:
  - la fecha de hoy,
  - la edad de la persona,
  - una frase corta que cambia cada día.
- Dura unos dos segundos. Sin botones.
- Luego Lumi se desliza hacia arriba y aparece la tarea de hoy.
- Tono: acompaña al presente, nunca avergüenza. Incluir en Ajustes un interruptor para ocultar la línea de la edad.

### 5.3 Tarea del momento
- Una sola tarea en pantalla, elegida según el puntaje de energía:
  - energía alta: la más difícil,
  - energía media: una rutinaria,
  - energía baja: una microtarea de dos minutos, o "hoy descansa, mañana atacamos".
- Dos acciones: **Empezar** y **Ahora no**.
- Al empezar, un **anillo de luz** alrededor de Lumi se va consumiendo: el tiempo hecho visible.
- Si la persona termina dos tareas rápido, se le ofrece una tercera (está en racha).

### 5.4 Agregar tarea
- Sin formularios. Una sola frase, hablada o escrita.
- Voz: mantener presionada la estrella y hablar.
- La app asigna sola un tamaño: chica, mediana o grande.
- Si es grande, Lumi pregunta: "¿Cuál es el primer paso de dos minutos?" y eso es lo que se muestra después.

### 5.5 Mis tareas
- Vista simple de lo pendiente, sin fechas vencidas en rojo ni contadores de deuda.

### 5.6 Ajustes
- Notificaciones (apagadas por defecto), línea de edad, forma de Lumi (estrella o esfera), idioma, borrar mis datos.

---

## 6. Puntaje de energía (MVP)

Dos señales, sin permisos de salud:

**A. Curva base por cronotipo.** Con las tres respuestas del registro se arma una curva de energía por hora del día (0–100).

**B. Comportamiento dentro de la app.**
- qué tan rápido completa tareas frente a su promedio,
- si abre la app y la cierra sin hacer nada,
- cuánto tarda en empezar la primera tarea del día.

**Aprendizaje.** Cada franja horaria tiene un nivel de confianza:
- la app propone una tarea difícil y la persona la termina: sube la confianza de esa hora;
- la persona toca "Ahora no" o la ignora: baja, y se intenta más tarde.

A las dos semanas la curva debe ser de la persona, ya no la genérica. Guardar el historial de eventos para poder recalcular.

---

## 7. Notificaciones

- **Cero por defecto.** La persona las activa si quiere.
- Activadas: máximo **una al día**, en la hora de mayor energía según su curva.
- Si la ignora dos veces seguidas, la app deja de enviarla sola.
- Más de tres días sin abrir: un único mensaje suave, "Lumi sigue aquí". Nada más.
- Nunca mensajes de culpa ni de racha perdida.

---

## 8. Fuera del MVP (versión 2)

No construir todavía, pero dejar el código preparado para que quepan:

- **Salud**: sueño, pasos y ritmo cardíaco en reposo con HealthKit como tercera señal de energía.
- **Hiperfoco**: tras unos 90 minutos seguidos en una tarea, no interrumpir; solo recordar tomar agua.
- **Rachas bajas**: tres días con la curva por el suelo, preguntar con suavidad si todo está bien en vez de empujar tareas.
- **Anclas semanales**: una frase o foto de algo vivido de verdad; Lumi las muestra en días difíciles.
- **Memoria de victorias**: resumen semanal de los momentos en que la persona estuvo bien. Progreso, nunca deuda.
- **La estrella envejece**: se vuelve más definida con los meses y cambia de fase en cada cumpleaños.
- **Año visible**: cielo de 365 puntos de luz con los días ya vividos.
- **Reporte para el médico**: una página mensual con curva de energía, horas de mayor rendimiento, tareas iniciadas y terminadas, y sueño. Sin diagnósticos.
- **Cuestionario ASRS** al inicio. Revisar antes las condiciones de uso del cuestionario.
- **Suscripción** (StoreKit).

---

## 9. Modelo de negocio

- **Gratis**: Lumi, energía, tareas, presencia. Todo lo que resuelve el día a día.
- **De pago**: reporte médico, conexión con salud y funciones avanzadas de la estrella. Entre 4 y 5 dólares al mes (precio por definir).
- **Sin prueba gratis que atrape.** Se paga porque ya funcionó.

---

## 10. Reglas clínicas y de privacidad

- ZENO **no diagnostica ni reemplaza tratamiento**. Decirlo claramente en el registro y en Ajustes.
- Las técnicas que se usen (dividir tareas, hacer visible el tiempo) deben estar respaldadas por evidencia; citar la fuente dentro de la app cuando se incorporen.
- Fecha de nacimiento y datos de energía son sensibles: se quedan en el teléfono, sin analíticas de terceros en el MVP.
- Opción de borrar todos los datos.

---

## 11. Plan de construcción por fases

Construir en este orden. Al terminar cada fase: que compile, que corra en el simulador y explicarle a Diaz qué probar antes de seguir.

**Fase 0 — Proyecto.** Crear el proyecto SwiftUI "ZENO", estructura de carpetas, modelos de SwiftData (Persona, Tarea, EventoDeEnergía) y un archivo CLAUDE.md con las reglas de este documento.

**Fase 1 — Lumi y la nebulosa.** Generador a partir de la semilla, estrella que respira, fondo que cambia con la hora y con un valor de energía. Incluir una pantalla de prueba con un control deslizante de energía y un botón para probar semillas distintas. **Pulir esta fase hasta que se vea hermosa antes de avanzar: es el alma de la app.**

**Fase 2 — Registro.** Las pantallas de nombre, fecha, cronotipo y el nacimiento de la estrella.

**Fase 3 — Momento de presencia.** Las tres líneas y la transición hacia la tarea.

**Fase 4 — Tareas.** Agregar por texto y por voz, tamaño automático, primer paso de dos minutos, lista simple.

**Fase 5 — Energía.** Curva por cronotipo, señales de comportamiento, selección de la tarea y aprendizaje con "Ahora no".

**Fase 6 — Anillo de tiempo y celebración.** Con sus variantes y la háptica.

**Fase 7 — Notificaciones** con las reglas de la sección 7.

**Fase 8 — Pulido.** Transiciones continuas, íconos propios, accesibilidad, inglés y español, ícono de la app.

---

## 12. Primer mensaje para Claude Code

> Lee ZENO_SPEC.md completo. Soy principiante y no sé programar, así que explícame cada paso en español sencillo. Empieza por la Fase 0 y la Fase 1. No avances a la siguiente fase hasta que yo te confirme que lo que veo en el simulador me gusta.
