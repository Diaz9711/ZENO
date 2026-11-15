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
- Fluidez: 120 Hz en ProMotion (`CADisableMinimumFrameDurationOnPhone`), menos trabajo por cuadro (cielo y Lumi intactos). Medidor DEBUG `-medirFluidez YES`; **falta medir en el iPhone** (`devicectl device process launch --console ... app.zeno.ZENO -- -medirFluidez YES`).
- Web publicada con las novedades y la sección de ciencia.
- Para la App Store: `PrivacyInfo.xcprivacy` en la app y en el widget, `ITSAppUsesNonExemptEncryption = NO`, texto del micrófono corregido; la versión Release compila sin avisos.
- **Ojo:** Diaz trabaja con la copia `~/Desktop/ZENO` (la que abre Xcode). Las copias `ZENO-main` de Descargas y Escritorio son viejas.

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
