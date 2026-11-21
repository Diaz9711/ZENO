# ZENO — dónde vamos (para empezar una conversación nueva)

Última actualización: 14 nov 2026 (noche). Repositorio privado: https://github.com/Diaz9711/ZENO (rama `main`).

## Cómo empezar la próxima conversación
Abre una sesión nueva en la carpeta `~/ZENO` y escribe:

> Lee CLAUDE.md, ZENO_SPEC.md y ESTADO.md. Vamos en la Fase 8. Sigue con "Probar en mi iPhone".

Las reglas que nunca se rompen están en `CLAUDE.md`. Este archivo solo cuenta el estado y lo pendiente.

## Con quién trabajas
- Diaz no programa: español sencillo, paso a paso, mensajes cortos.
- Quiere ahorrar créditos: pocas capturas y compilaciones, trabajo en lotes.
- Le funciona mejor **ver opciones en una sola foto y elegir un número** que adivinar.
- Diaz usa el simulador iPhone 17 Pro `BF996C6D…` a la vez. Para pruebas propias usar el segundo simulador iPhone 17 Pro `E586E750-C12E-4087-9FFA-5E53F184029E`.
- Fable está como asesor (advisor): consultarlo antes de cambios grandes y al terminar.

## Hecho en la Fase 8 (todo subido a GitHub)
- **Hoy con más vida:** titular grande con la última palabra en cursiva dorada (`Titular`), campo "Escribe una tarea…" (`CampoRapido`), datos con líneas de luz (`LineaDeLuz`, `PuntoDelDia`).
- **Cielo:** más detalle, lucecitas que flotan, profundidad al inclinar (`Nebulosa/Inclinacion.swift`, con contador de usuarios del sensor) y un cometa pequeño de vez en cuando (shader `cometa`).
- **Oro de ZENO:** oro de estrella pálido (`oroClaro`, `oroZeno`, `oroHondo`), nunca naranja.
- **Lumi:** color amarillo cálido que sigue a la energía (oro hondo con poca, amarillo claro con mucha), la luz propia respira apenas; con energía baja sigue grande y nítida; lo ganado al terminar tareas alarga los rayos. Halo de cada persona sin verdes ni turquesas.
- **Transiciones:** páginas que entran de lado según la barra; Lumi toma impulso al viajar.
- **Íconos de la barra:** más finos, con brillo y punto de luz.
- **Bienvenida:** viaje de cámara, sol con órbita y ZENO letra por letra. Primera vez: menú "Continuar con Apple" / "Entrar como invitado". Cada vez que se abre: presentación corta (~5,5 s, tocar la salta) y directo a Hoy (sin fecha, edad ni frase).
- **Registro profesional:** volver + línea de progreso, título y razón, opciones en filas con círculo, botón abajo (aprobado).
- **Botón principal:** píldora dorada limpia 280 × 50 (aprobado). En Hoy no hay botón: **tocar la tarea la empieza, mantenerla presionada la termina** (probado).
- **Sin texto de energía** en Hoy: la energía solo se ve en la luz.

## Hecho el 14 nov 2026 (tras probar en el iPhone de Diaz), pendiente de su aprobación
1. **Estrella** más nítida: núcleo con borde nítido, rayos finos, menos neblina y un centelleo sutil por semilla (`Comparaciones/estrella-antes-despues.jpg`).
2. **Fluidez**: `Ritmo.contenido` para páginas y secciones, sin desenfoque animado, Lumi a 60 cuadros (vistas previas a 30), sin animación doble en la barra. Hay que juzgar los 60 fps en el iPhone, el simulador no sirve para eso.
3. **Ajustes y Tareas**: el scroll ya no corta; degradado arriba y abajo y Lumi se encoge y apaga al deslizar.
4. **Idiomas**: selector en Ajustes, catálogo completo español/inglés (221 textos), detección del idioma del teléfono la primera vez.
5. **Cerebro**: `Aprendizaje` (duración real, horas fuertes, lo que pospone) + sección "Tu ritmo".
6. **Tareas con día, hora y aviso** y editor de tarea.
7. **Sesión**: carga y errores claros en el menú de entrada; Cerrar sesión en Ajustes.
- Atajos de prueba (solo DEBUG): `-sinPresentacion YES`, `-paginaInicial 0|1|2`, `-formaDePrueba 0|1`, `-idioma es|en`, `-modoPrueba YES`.

## Hecho el 14 nov 2026 (noche): dirección LUXURY
- Parada 1 aprobada: estrella versión 4 (más definida, mismos colores), presentación intacta, "Editar tarea" luxury.
- Parada 2 aprobada: Hoy con tarjetas, Tareas como vista del día, barra luxury, entradas en cascada, hoja casi transparente.
- Parte D: clave local con Face ID (crear, entrar, mostrar/ocultar, errores claros, espera tras 5 fallos, recuperar, cambiar y quitar en Ajustes); Ajustes, registro (fecha con ruedas propias), menú de entrada y "escribir tarea" con el sistema luxury; confirmaciones en hojas propias. 265 textos en español e inglés; permisos (Face ID, micrófono, voz) también traducidos.
- Atajos DEBUG nuevos: `-lumiQuieta YES`, `-energiaFija 70`, `-abrirEditor YES`, `-claveDePrueba xxxxxx`, `-sesionCerrada YES`.
- Falta por juzgar en el iPhone: fluidez a 60 fps, centelleo de la estrella, Face ID real.

## Hecho el 14 nov 2026 (noche): cinco mejoras, pendientes de que Diaz las apruebe
1. **Anillo en la Isla Dinámica y en la pantalla bloqueada** (Live Activity), con "Terminé". Probado en el simulador: la Isla muestra el anillo y el tiempo, y "Terminé" cierra la tarea. Falta ver la pantalla bloqueada en el iPhone. Sin texto de la tarea con el iPhone bloqueado (lo eligió Diaz).
2. **Widget de inicio** (pequeño y mediano) con la luz de Lumi y la tarea de ahora. Probado el mediano en el simulador.
3. **Siri y botón de Acción**: "Agrega una tarea a ZENO" y "Escribe una tarea en ZENO". Probados con `-probarSiri` y `zeno://escribir`; falta probar la voz real de Siri en el iPhone.
4. **Chispa** (nombre elegido por Diaz): vuela alrededor de Lumi al terminar y aparece discreta en Tareas y Ajustes.
5. **Cómo funciona ZENO** en Ajustes → Saber más, con cinco estudios verificados.
- Catálogo: 309 textos de la app y 10 del widget, todos con inglés (comparado con los `.stringsdata` de la compilación).
- **Para instalar en el iPhone hace falta** que Diaz conecte su Apple ID en Xcode → Settings → Accounts. Sin cuenta, `xcodebuild` no puede crear los perfiles de la extensión ni del App Group. Si el Personal Team no permite App Groups, hay que quitar `ZENO.entitlements` y `ZENOWidgets.entitlements` de los ajustes: el widget seguiría mostrando solo la luz.

## Hecho el 15 nov 2026
- Pantalla bloqueada: diseño **línea fina** (elegido por Diaz). Logo: la O como **planeta** (ícono y web). Widget: diseño **Cielo** con la Lumi y la nebulosa reales.
- Fluidez: 120 Hz en ProMotion (`CADisableMinimumFrameDurationOnPhone`) y menos trabajo por cuadro. **Medido en el iPhone 16 Pro Max (Hoy, sin tocar, 5 s por línea):** calidad vieja: 120 cuadros/s, 0 tirones. Nueva calidad (primera versión): bajones a 93 cuadros/s con 60 tirones. Nueva calidad aligerada: 119–120 cuadros/s, 0–5 tirones. Los primeros 5 s (al abrir) siempre tienen tirones. Se mide con `script -q salida.txt xcrun devicectl device process launch --device 17C74077-06F2-5731-BACE-6E5EE451C30F --console --terminate-existing app.zeno.ZENO -- -medirFluidez YES -sinPresentacion YES` (el iPhone debe estar desbloqueado). Falta medir al deslizar Tareas y Ajustes.
- **Nueva calidad del cielo y Lumi** (elegida por Diaz, también en la presentación): ver CLAUDE.md. Comparaciones en `Comparaciones/calidad-cielo-lumi.jpg` y `Comparaciones/estrella-nitida.jpg`.
- Web publicada con las novedades y la sección de ciencia.
- Para la App Store: `PrivacyInfo.xcprivacy` en la app y en el widget, `ITSAppUsesNonExemptEncryption = NO`, texto del micrófono corregido; la versión Release compila sin avisos.
- **Ojo:** Diaz trabaja con la copia `~/Desktop/ZENO` (la que abre Xcode). Las copias `ZENO-main` de Descargas y Escritorio son viejas.

## Fluidez medida con el autopiloto (15 nov 2026, iPhone 16 Pro Max, cuadros por segundo)
- Cómo medir sin tocar el iPhone (desbloqueado, Bloqueo automático en Nunca): `script -q salida.txt xcrun devicectl device process launch --device 17C74077-06F2-5731-BACE-6E5EE451C30F --console --terminate-existing app.zeno.ZENO -- -medirFluidez YES -sinPresentacion YES -autopiloto YES`. Cada línea dice la pantalla, si hay ahorro de batería y la temperatura.
- Antes → ahora: Ajustes al deslizar 39–55 → 116–120 · hojas 40–57 → 96–110 · cambio de página 49–77 → 86–101 · Hoy en reposo 120 · con ahorro de batería, Hoy 20 → 60 (el tope de iOS en ese modo).
- Lo que lo logró: el cielo ya no es Animatable (no se redibuja a 120 en las transiciones); el cielo hace una pausa invisible mientras algo se mueve (`ModoAhorro.movimiento`); menos cuadros con ahorro de batería o con el iPhone caliente; Lumi se dibuja a tamaño fijo al viajar; sombra fija en las hojas; Llavero y "Tu ritmo" recordados; foto del widget solo al salir.
- Sin cielo ni Lumi (`-sinCielo YES`) todo va a 105–120: lo que queda en el cambio de página es construir la página, no el cielo.

## DONDE NOS QUEDAMOS (15 nov 2026, tarde) — leer primero
Diaz se quejó: al cambiar de página (Hoy ↔ Tareas ↔ Ajustes) la nebulosa "salta", se ve como un cambio de imagen.
- **Causa (confirmada con Fable):** mi cambio de fluidez `f0c8b2c` pausaba el cielo mientras algo se movía y quitaba el `Animatable` de `NebulosaView`. El brillo se quedaba quieto y luego saltaba.
- **Arreglo hecho y en el iPhone, sin probar todavía por Diaz:** `NebulosaView` y `LumiView` vuelven a ser como en `a24fbb6` (cielo `Animatable`, sin pausas, sin el truco `tamanoDeDibujo`). Solo queda el recorte con **ahorro de batería** (cielo 15 cuadros, Lumi 30). Se quitaron la pausa del cielo, el recorte por calor y la sombra falsa de las hojas.
- Se conservan: autopiloto y medidor (DEBUG), Llavero y "Tu ritmo" recordados, foto del widget solo al salir, Lumis vivas en Ajustes.
- **f0c8b2c no se debe subir solo; subir junto con este arreglo.**

Pasos siguientes, uno por uno (Diaz pidió paso a paso, "razona bien", usar a Fable):
1. Que Diaz confirme en el iPhone que la nebulosa ya no salta al cambiar de página. Si aún salta, grabar el simulador con el autopiloto y mirar los cuadros del cambio.
2. Medir con el iPhone frío: `-calidadVisual 0` y `-sinMascara YES` para saber qué cuesta en el cambio de página (sin pausar el cielo).
3. **Estrella por cada tarea:** ya existe (`EstrellasGanadas`). Diaz no la ha visto porque no tiene tareas terminadas. Enseñarla con `-cieloDeEjemplo YES` y comprobar que se distingue de las estrellas con puntas nuevas.
4. **Cielo negro — APROBADO por Diaz (opción 3, "negro hondo").** `TonoDeCielo.negro` en Ajustes → Tu Lumi ("Cielo azul / Cielo negro"); el azul sale idéntico (3000 semillas). Probar en el iPhone que el cambio se ve suave.
4b. **"Hay muchas estrellas" (Diaz):** Fable vio que no eran las del fondo sino ~160 estrellas de prueba (el `-cieloDeEjemplo` se cargaba cada vez que se abría). Arreglado (se carga una sola vez). Las estrellas del fondo NO se tocaron. Las ganadas: las 24 más recientes enteras; de la 24 a la 72 se asientan (más pequeñas y tenues); nunca desaparecen. Foto: `Comparaciones/estrellas-ganadas-cantidad.jpg`. Prueba: `-cieloDeEjemplo YES -estrellasDeEjemplo 200`.
4c. **Nebulosa confirmada por Diaz ("está perfecta").** Ya no salta al cambiar de página.
4d. **Cielo negro con más vida (Fable):** uniforme `negro` en el shader (0 = azul idéntico): más estrellas solo en el negro (lejos 0,050→0,085, medias 0,060→0,080, brillantes 32 %→40 %), un segundo color en los pliegues (humo con color y luz de luna azul-violeta) y tarjetas en gris tinta neutro (`CristalDeTarjeta`). El azul no recibe estrellas nuevas (Fable: compiten con Lumi). Foto: `Comparaciones/cielo-negro-antes-ahora.jpg`. Si aún falta algo: banda de vía láctea tenue (idea B de Fable, sin hacer).
4e. **Registro "Editorial" (Fable, opción A):** contador "01 / 06" en oro, títulos Fraunces grandes con una palabra en cursiva dorada (`TituloConAcento`, `*palabra*` en el catálogo), filas de 64 pt con glifos finos (`GlifoDeHora`: amanecer, sol, atardecer, luna, estrella, esfera), al tocar se ilumina en oro con el check dibujado y pasa sola; nombre en Fraunces 40 con línea que se enciende; fecha sin caja. El botón de Apple sigue blanco (norma de Apple sobre fondo oscuro). Foto: `Comparaciones/registro-antes-ahora.jpg`. Prueba: `-pasoDeRegistro 1…7 -sinPresentacion YES` (sin persona).
4f. **Movimiento con vida (Fable, primera tanda):** tarjeta Ahora con resorte `Ritmo.contenido` al empezar/terminar/"Ahora no", etiqueta y botón se funden ("Empezar"→"Terminé"), la siguiente tarea sube y la anterior se va hacia arriba (sin desenfoque); quitada la vibración doble; Hoy llega pieza por pieza (escalón 60 ms, 14 pt, curva 0,5) y la línea de luz se enciende cuando su tarjeta ya llegó; en Tareas el check tiene estado al presionar, toque suave y la fila se aparta 8 pt antes de irse; borrar con resorte. Segunda tanda posible: reflejo único al llegar una tarea nueva y Chispa que reacciona al cambiar de frase. Probado en el simulador (empezar, terminar, marcar).
4g. **Web:** sección nueva "Tu cielo" (azul, negro y el registro) en `Web/zeno.html`.
5. "Más premium, que la app tenga vida": sin efectos nuevos hasta que lo de arriba esté aprobado.
- **No tocar** la estrella ni la nebulosa por defecto ni sus colores (Diaz lo repitió).

## Auditoría y mejoras (20 nov 2026, plan revisado con Fable) — HECHO, en el iPhone de Diaz
- **Plan B de la base de datos** (`Modelos/Almacen.swift`): si no abre, aviso tranquilo `AvisoDeDatos` en vez de cerrarse en bucle; base en memoria aparte; Siri y el Terminé de la pantalla bloqueada se detienen. Prueba: `-fallarBaseDeDatos YES`.
- **Letra grande en Hoy**: desde xxxL se retiran el campo rápido y las medianas; Hoy no pasa de xxxL (Tareas y Ajustes sí, se desplazan); la barra tiene tope xLarge. Foto: `Comparaciones/letra-grande-antes-ahora.jpg`.
- **Para qué más visible**: al escribir, el título se vuelve "¿Para qué te importa?" (un toque); abierto la primera vez (`porquePrimeraVez`); también por fila en la vista previa de la captura (con revisión de crisis); más grande en la tarjeta de Hoy.
- **Chispa**: con energía media/alta menciona el porqué 3 de 4 turnos (baja: 1 de 3), 7 frases; al terminar una tarea con porqué, referencia suave 1 de 2 (`Momento.celebrando(anzuelo:)`).
- **Salud fuera de la 1.0**: HealthKit solo compila con la condición `SALUD`; sin `NSHealthShareUsageDescription` (comprobado con `otool -L` en Release).
- **Privacidad dentro de la app** (`Pantallas/Privacidad.swift`, Ajustes → Tus datos → Privacidad). `Web/privacidad.html` ya menciona la IA del iPhone (sin publicar).
- **Vuelta amable**: tras 3+ días sin abrir, Chispa recibe sin repaso y se propone algo pequeño hasta terminar la primera cosa del día (`MotorDeEnergia.deVuelta`).
- **Registro corto**: solo como opción para que Diaz elija (`-registroCorto YES`, foto `Comparaciones/registro-corto-opciones.jpg`). El registro real no cambió.
- **Copia de seguridad**: la base de datos está en el contenedor del App Group (`.../AppGroup/.../Library/Application Support/default.store`), sin exclusión de copia: muy probablemente va en la copia de iCloud/Mac del iPhone (restaurar no está probado). Exportar se deja para después.
- **No hecho esta vez (Fable)**: widget de pantalla bloqueada (necesita diseño elegido por Diaz), recompensas que cambian (toca la celebración de Lumi), modo acompañamiento (sin definir), próximo compromiso (agranda la tarjeta de Hoy).

## Compañero TDAH (20 nov 2026, pedido de Diaz con un texto de 9 puntos; plan revisado con Fable) — HECHO, en su iPhone
1. **"¿Para qué te importa?"** (opcional): `Tarea.porque` (nuevo, con valor por defecto). Se escribe con un toque al crear (botoncito bajo el campo) o en el editor. Viste la tarjeta de Hoy (línea dorada en cursiva con estrellita), Chispa lo menciona (frases a mano, 2 de cada 3 turnos), con energía media/alta va primero dentro del mismo tamaño, y Divídemela lo usa. Si suena a crisis no se repite (`Tarea.anzuelo`).
2. **Captura por voz**: ya no se parte por puntos ni comas. El fallo real era `validarCaptura` ("Llamar" vs "llama", "5" vs "cinco"); ahora acepta la misma raíz y cifras. Sin IA solo separa por "y después / y luego / and then", y la hora va solo con su tarea. Probado en el iPhone con IA: «llama al dentista mañana a las cinco y después revisa el correo» → 2 tareas, la primera mañana 17:00.
3. **Pasos**: el siguiente paso arranca solo (en la app); anillo de fuera con un tramo por paso; si pasan 10 min sin Terminé, el anillo baja su luz despacio hasta 0,4 (`AnilloDeTiempoView.intensidad`). Prueba: `-pasosDeEjemplo 16`.
4. **Avisos según la energía esperada a esa hora**: baja → frase de Chispa y nunca dos avisos en la misma hora; media/alta → "Tienes un paso pequeño listo" (sin texto de tareas). Los avisos de tareas que pidió la persona no cambian.
5. **Lo aprendido → Divídemela**: `TipoDeTarea` (llamada, trámite, papeles, correo, compras, limpieza, estudio), guardado en cada evento (`tipoDeTareaCrudo`). Si pospone ≥50 % de un tipo (≥3 decisiones, 45 días), pasos de 2–3 min (`PedidoDeDivision.masPequenos`).
6. **Modo compañero silencioso** (`Eleccion.silencio`): energía < 22 o 3 "Ahora no" seguidos en 2 h. "Sin prisa · Estoy aquí contigo" + "Quiero hacer algo". Lo planeado para ahora sí va. Prueba: `-silencioDeEjemplo YES`. Foto: `Comparaciones/modo-silencioso.jpg`.
7. **Bucle de retorno**: Chispa dice un patrón en el momento, una vez al día cada uno (`Aprendizaje.patronDeAhora`).
8. **Salud (señal C)**: `Energia/Salud.swift`, preparada y APAGADA (`LectorDeSalud.preparado = false`). `ajusteDeSalud(nil) = 0`. Falta la capacidad HealthKit (cuenta de pago) y un interruptor en Ajustes. Texto `NSHealthShareUsageDescription` ya en Info.plist.
9. **Tests**: objetivo `ZENOTests` (carpeta `ZENOTests/`, fuera de la app), 39 tests de funciones puras. Correr: `xcodebuild test -project ZENO.xcodeproj -scheme ZENO -only-testing:ZENOTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build`.

## FASE IA (16 nov 2026, pedido de Diaz con un texto largo; plan revisado con Fable) — EN CURSO
**Parte 1 HECHA (commit 67ce1ac) y probada en el iPhone de Diaz:** `-probarIA YES` dio todo PASS y la IA de Apple dividió tareas en español de verdad (p. ej. «Limpiar la cocina» → Abre el armario / Retira los platos sucios / …). Divídemela: Hoy → tocar a Chispa → "Divídemela" (o en la pregunta del primer paso). Hoja propia: editar, borrar, subir/bajar, añadir, guardar. Con pasos, Hoy dice "Paso 2 de 5" y "Terminé" pasa al siguiente; solo el último da la estrella. Probada la actualización sobre datos existentes (no se pierde nada). En el simulador de este Mac la IA dice "disponible" pero falla al generar → se usa la plantilla (bien). Ajustes → Modo de prueba muestra el motor y lo último generado.
**Partes 2 y 3 HECHAS y probadas en el iPhone (29/29 PASS con la IA real):**
- Captura por voz: al dejar de dictar, si dijo varias cosas, `HojaCaptura` las muestra (quitar, editar, tamaño, quitar la hora) y se guardan con un toque. La IA solo separa; la fecha la calcula el sistema y solo si la persona la dijo; se rechaza toda tarea con palabras que no dijo. Sin IA: una tarea por frase (el dictado ahora pone puntuación). Una sola tarea: queda en el campo como siempre.
- Frases de Chispa (`IA/Frases.swift`): banco escrito a mano de 15 frases por momento y por idioma (5 momentos: ahora, en marcha, descanso, nada pendiente, celebración; el pedido decía 50 — se puede ampliar). La IA rellena en segundo plano un depósito (≤24 por momento), validado: 3–15 palabras, sin números, sin culpa/prisa/consejos médicos, del idioma de ZENO, sin repetir las últimas 30. Una frase por momento y turno (no parpadea). Tras "Terminé", unos segundos de frase de celebración. Las frases con números u horas siguen escritas a mano.
- Botón Empezar: Diaz dijo que las 4 primeras opciones parecían "hechas por IA". Ahora hay dos de verdad distintas (Fable): **A · Metal** (placa cepillada con canto, palabra grabada en Fraunces, se hunde al tocar) y **B · Cápsula con flecha** (de su video de referencia: cápsula marfil→oro, palabra a la izquierda, círculo oscuro con flecha que se vuelve check). Se cambian en vivo en Ajustes → Modo de prueba. Foto: `Comparaciones/boton-empezar-premium.jpg`. **Diaz eligió el Emblema** (16 nov 2026): oro cepillado de siempre + estrellita de cuatro puntas delante que se vuelve check al estar en marcha (`PlacaEmblema`); es el de por defecto. **Animación 3D (Fable):** al empezar, la placa da media vuelta sobre su eje con perspectiva y en el reverso salen el check y "Terminé"; una banda de luz cruza el metal al asentarse; al presionar se inclina como una tecla; el brillo sigue la inclinación del iPhone (lee `Inclinacion.ultima`, sin encender el sensor; apagado con Reducir Movimiento y ahorro de batería). Toques ignorados 0,9 s tras un toque. Probar ángulos fijos: `-giroEmblema 0…1`. Foto: `Comparaciones/boton-giro-3d.jpg`.
- Frases de Chispa de la IA: APAGADAS por defecto (algunas sonaban raras); se encienden en Modo de prueba ("Frases de Chispa escritas por la IA"). Por defecto, el banco escrito a mano.
- `-probarCaptura YES` abre la vista previa de la captura con tareas de ejemplo. Falta una prueba de dictado real de Diaz.
Orden: (1) servicio de IA + "Divídemela" → instalar y que Diaz pruebe; (2) captura por voz con vista previa; (3) mensajes de Lumi sin repetir. Una parte a la vez.
- Motor: Foundation Models de Apple (iOS 26+, dentro del iPhone). El iPhone de Diaz (16 Pro Max, iOS 27.2) puede; el simulador de este Mac (Intel) seguramente no → ahí solo se prueba la versión sin IA.
- `ServicioDeIA` con un protocolo y tres motores: local (Foundation Models), simple (sin IA, siempre funciona) y nube (solo la "puerta": dice "no disponible", sin red ni claves; la privacidad publicada dice que no hay servidores).
- Todo resultado se valida en código (3–7 pasos, no vacíos, frases ≤15 palabras, idioma de ZENO); si falla, versión simple. Nunca rompe la app.
- Pasos: `Tarea.pasosCrudo` (opcional) y `pasoActual`. Con pasos, Hoy muestra el paso de ahora; "Terminé" avanza al siguiente y solo el último termina la tarea (una estrella por tarea, no por paso). Probar actualización sobre datos existentes.
- Mapeo (no existe en ZENO): "porqué" e "interés" no hay → no se piden; "esfuerzo" = tamaño de tarea; "reto/novedad/pasión" → momentos de Chispa; celebración = frase de Chispa tras Terminé; HealthKit no está en la app.
- Crisis: comprobación en código (sin IA) antes de cualquier motor; mensaje amable sin números de teléfono inventados.
- Pruebas: no hay target de tests → funciones puras + `-probarIA YES` (PASS/FAIL en consola). Modo de prueba en Ajustes muestra el motor y lo último generado.

## Web 3D (15 nov 2026, plan aprobado por Diaz, revisado con Fable) — `Web/zeno-3d.html`, aparte de la web actual
- Lumi y la nebulosa son los shaders de la app (`Sombras.metal`) pasados a GLSL, con la misma semilla (comprobado: mismos números que la app). Three.js 0.160.0 desde jsDelivr, cargado solo si hay WebGL. Sin WebGL (o `?sin3d`): estrella 2D de la web. Con Reducir movimiento: imagen quieta.
- Partes: Lumi, Tu cielo (velos de gas + estrellas con profundidad), Energía (aro de 24 horas con la curva base), Ahora (tarjeta), Tus estrellas, Tiempo visible (anillo: solo se ve al elegirlo o al ver por dentro; Diaz no lo quiere en la vista normal).
- Pestañas (la cámara viaja y separa la parte), "Ver por dentro" (3 s, frena al final, etiquetas con línea fina que no se pisan), giro lento constante, arrastrar y pellizcar.
- `?play` = grabación de 25 s en bucle (sin botones ni cursor); `?play&vertical` = escenario 9:16 para Reels (Diaz lo graba con la grabación de pantalla). `?fps` muestra cuadros por segundo. `?nombre=Diaz&fecha=1999-06-15` = estrella de esa persona.
- Revisión contra la app (misma semilla, mismo tamaño en el iPhone 17 Pro Max): corregidos rayos casi invisibles en pantallas pequeñas (mínimo 1,1 px), mezcla de luz como en la app (rayos largos y núcleo cálido), anillo quitado de la vista, tarjeta que se cortaba en vertical. Sigue distinto: el ángulo de los rayos (Lumi gira), la nebulosa es de la hora actual, y la estrella del respaldo 2D es más simple.
- Calidad automática: baja primero la resolución del cielo y luego hasta 1 píxel por punto, nunca menos (la estrella no se ve borrosa). En el simulador va lento porque no tiene gráficos reales: medir en el iPhone con `?fps`.
- Decisiones tomadas por defecto (Diaz no contestó): las anclas semanales se cambiaron por "Tus estrellas" (las anclas no existen aún); el botón dice "Próximamente en iPhone" y lleva a la web actual; la nebulosa sigue azul; es una página aparte.

## Tarjetas Hoy y Tu mejor hora (15 nov 2026, Fable eligió por Diaz)
- Opción 2 · Estrellas y curva (foto `Comparaciones/hoy-tarjetas-opciones.jpg`). Las otras con `-disenoMedianas 0|1|3` (solo en pruebas).
- Arreglo de paso: en iPhones más bajos que el Pro Max la barra de abajo quedaba fuera de la pantalla en Hoy (ya pasaba antes). Ahora ahí el campo "Escribe una tarea…" no se muestra (el "+" de la barra hace lo mismo), y las tarjetas son un poco más compactas. Medido en 17 Pro y 17 Pro Max.
- La presentación al abrir tiene también las estrellas nuevas: Fable aconsejó no separarla (si no, aparecerían estrellas de golpe al pasar a Hoy).

## Web con movimiento y cielo (15 nov 2026, plan de Fable)
- Web: titular palabra por palabra con brillo de oro, teléfono que llega y se inclina con el cursor, todo aparece al bajar (con respaldo para que nada quede invisible), barra fija con línea de progreso dorada, cielo con estrellas que titilan y una fugaz cada 14–22 s, gráfica que se dibuja sola, reflejo en botones y luz en el canto de las tarjetas. Sin desenfoque en las tarjetas (era lo que más frenaba). Con Reducir movimiento todo se ve quieto y completo.
- App: +20 % de estrellas pequeñas en los dos cielos (pedido de Diaz) y el cielo negro negro de verdad: humo carbón y luz plateada (uniforme `negro` también quita los tintes violeta). Foto: `Comparaciones/estrellas-y-negro-real.jpg`.

## Arreglos rápidos para la App Store (15 nov 2026, revisados por Fable)
- "Continuar con Apple" escondido (`Sesion.conApple = false`); la entrada es "Empezar" (o "Entrar" al volver) y "Crear una clave". Ajustes dice "Sin cuenta". Poner `true` cuando haya cuenta de pago y la capacidad activada.
- Frase de Safren reescrita (app, catálogo y web): describe el estudio y dice que ZENO no es esa terapia.
- Permisos en inglés (Face ID, voz) revisados. Versión 1.0.
- `Web/privacidad.html` (ES + EN), enlazada desde el pie de la web. **Falta:** un correo de contacto de Diaz (privacidad y página de soporte), una dirección pública (los enlaces de Claude son privados: GitHub Pages u otro), y una fila "Privacidad" en Ajustes → Saber más con esa dirección.

## Qué le falta a ZENO para ser número uno (Fable, 15 nov 2026)
Ya resuelve bien: una sola tarea, sin culpa ("Ahora no" sin castigo), energía según la hora, anillo de tiempo, capturar con voz/Siri/widget.
Huecos principales: (1) empezar sigue siendo trabajo de la persona (escribe ella el primer paso); (2) nada la acompaña durante la tarea; (3) volver tras días sin usarla muestra una lista acumulada; (4) la recompensa es siempre igual (se aburre a las 2 semanas); (5) no se puede anotar algo en descanso o con una tarea en marcha; (6) no avisa del próximo compromiso; (7) la presentación de 5,5 s cada vez frena (decide Diaz).
Funciones por orden: 1 Chispa propone el primer paso y micro-pasos (IA en el teléfono, Apple Foundation Models; reserva sin IA) · 2 Vuelta amable tras 3+ días · 3 Modo "Lumi se queda contigo" (acompañamiento) · 4 Anotar siempre disponible · 5 Tiempo hasta el próximo compromiso · 6 Recompensas que varían (sin confeti) · 7 Widget de pantalla bloqueada y filtro de Enfoque · 8 Apple Watch (después).
No hacer: rachas, puntos, red social, planificador tipo calendario, chat de IA en la nube, diario de ánimo, cuentas.
Posicionamiento: "La única app para TDAH que elige la tarea que encaja con tu energía ahora, te ayuda a empezarla y nunca te hace sentir atrasado; todo se queda en tu iPhone". Precio: 1.0 gratis; luego ZENO Plus ~4,99 $/mes o 29,99 $/año, y vitalicio 59–79 $.
Riesgos de rechazo: botón "Continuar con Apple" sin la capacidad (esconderlo en 1.0); frase de Safren en Cómo funciona y en la web suena a promesa médica (reescribir); que la clave local nunca deje fuera al revisor; textos en inglés de Face ID y voz marcados para revisar (`InfoPlist.xcstrings`); falta página de privacidad y de soporte con contacto; versión 0.1 → 1.0.

## Lista para subir a la App Store (lo que falta)
- **Salud:** la app ya importa HealthKit y trae el texto `NSHealthShareUsageDescription`, pero sin la capacidad (apagada). Antes de enviar: confirmar que la revisión lo acepta así (o quitar el import) y que la página de privacidad lo menciona.
1. **Cuenta Apple Developer de pago** (99 USD al año). Con el Personal Team gratis no se puede subir.
2. **"Continuar con Apple"**: activar la capacidad Sign in with Apple con la cuenta de pago, o esconder ese botón antes de enviar. Si no funciona, Apple rechaza la app.
3. **App Store Connect**: crear la app (nombre ZENO, si está libre), subtítulo, descripción en español e inglés, palabras clave, categoría (Productividad; evitar "Salud/Medicina" para no prometer tratamiento), clasificación por edad.
4. **Política de privacidad (URL obligatoria)** y URL de soporte: se pueden publicar como página. En "Privacidad de la app" marcar **"No se recopilan datos"**.
5. **Capturas**: iPhone 6,9" (1320 × 2868) y 6,5". Opcional: video corto.
6. **Versión 1.0** (hoy `MARKETING_VERSION = 0.1`) y número de compilación.
7. **TestFlight** en el iPhone de Diaz: probar Isla Dinámica, widget, Siri, avisos, Face ID y la fluidez.
8. Revisar los textos de la ficha: ZENO acompaña, **no diagnostica ni trata** el TDAH (regla 1.4.1 de Apple).
9. Aprobar lo pendiente: Fase 7 (avisos) y las mejoras del 14 y 15 nov.

## Pendiente (en este orden)
1. **Probar en el iPhone de Diaz** (gratis con su Apple ID, hay que reinstalar cada 7 días). Le di los pasos: conectar y confiar; en Xcode, Signing & Capabilities → Team → su Apple ID (Personal Team); Modo desarrollador en el iPhone; ▶ Run; confiar en el desarrollador en Ajustes → General → VPN y gestión de dispositivos. Comprobar con `xcrun devicectl list devices`. Si el identificador `app.zeno.ZENO` no está disponible, cambiarlo por uno único.
2. **Fluidez** (medir en el iPhone, con números antes y después, mostrando los fps solo en la consola):
   - el gas del cielo a media resolución, con estrellas, lucecitas y cometa nítidos;
   - ~~limitar los cuadros de Lumi~~ y ~~brillo de la tarea por opacidad~~ hechos.
3. ~~Inglés~~ hecho (selector propio dentro de ZENO).
4. ~~"Cómo funciona ZENO"~~ hecho (falta que Diaz lo apruebe). Sobre el "respaldo médico": un certificado oficial (FDA o CE) no se logra con código; lo útil es este respaldo científico, la categoría Salud en App Store y que un profesional de TDAH pruebe la app.
7. **IA dentro de ZENO** (Diaz lo preguntó el 14 nov): la recomendación es el modelo de Apple que corre en el iPhone (Foundation Models, iOS 26), sin internet ni servidor. Serviría para proponer el primer paso de dos minutos, calcular mejor el tamaño de las tareas y que Chispa hable con más naturalidad. Antes hay que confirmar que existe en el SDK y que corre en el iPhone 16 Pro Max.
5. **iCloud y "Continuar con Apple" de verdad:** cuando Diaz tenga la cuenta de desarrollador de pago (aún no la tiene). Activar las capacidades "Sign in with Apple" e iCloud y sincronizar SwiftData con CloudKit.
6. **Fase 7 (avisos):** construida, falta que Diaz la apruebe.

## Cosas a tener en cuenta
- Los toques en el simulador a veces fallan la primera vez; repetir y mirar con una foto.
- `-datosDeEjemplo YES` crea una persona de prueba con tareas (solo si no hay persona).
- `-galeriaBotones YES` (solo DEBUG) muestra 8 estrellas distintas para revisar colores de halo.
- Hay variantes viejas sin usar en `Lumi/Estilo.swift` (`IconoOrbita`, `BotonSecundario`); no estorban.
- `Comparaciones/video-vs-zeno.jpg` es la referencia que mandó Diaz; no está en git.
