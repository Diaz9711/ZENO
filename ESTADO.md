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

## Qué le falta a ZENO para ser número uno (Fable, 15 nov 2026)
Ya resuelve bien: una sola tarea, sin culpa ("Ahora no" sin castigo), energía según la hora, anillo de tiempo, capturar con voz/Siri/widget.
Huecos principales: (1) empezar sigue siendo trabajo de la persona (escribe ella el primer paso); (2) nada la acompaña durante la tarea; (3) volver tras días sin usarla muestra una lista acumulada; (4) la recompensa es siempre igual (se aburre a las 2 semanas); (5) no se puede anotar algo en descanso o con una tarea en marcha; (6) no avisa del próximo compromiso; (7) la presentación de 5,5 s cada vez frena (decide Diaz).
Funciones por orden: 1 Chispa propone el primer paso y micro-pasos (IA en el teléfono, Apple Foundation Models; reserva sin IA) · 2 Vuelta amable tras 3+ días · 3 Modo "Lumi se queda contigo" (acompañamiento) · 4 Anotar siempre disponible · 5 Tiempo hasta el próximo compromiso · 6 Recompensas que varían (sin confeti) · 7 Widget de pantalla bloqueada y filtro de Enfoque · 8 Apple Watch (después).
No hacer: rachas, puntos, red social, planificador tipo calendario, chat de IA en la nube, diario de ánimo, cuentas.
Posicionamiento: "La única app para TDAH que elige la tarea que encaja con tu energía ahora, te ayuda a empezarla y nunca te hace sentir atrasado; todo se queda en tu iPhone". Precio: 1.0 gratis; luego ZENO Plus ~4,99 $/mes o 29,99 $/año, y vitalicio 59–79 $.
Riesgos de rechazo: botón "Continuar con Apple" sin la capacidad (esconderlo en 1.0); frase de Safren en Cómo funciona y en la web suena a promesa médica (reescribir); que la clave local nunca deje fuera al revisor; textos en inglés de Face ID y voz marcados para revisar (`InfoPlist.xcstrings`); falta página de privacidad y de soporte con contacto; versión 0.1 → 1.0.

## Lista para subir a la App Store (lo que falta)
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
