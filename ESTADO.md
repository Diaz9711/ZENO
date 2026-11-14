# ZENO — dónde vamos (para empezar una conversación nueva)

Última actualización: 14 nov 2026. Repositorio privado: https://github.com/Diaz9711/ZENO (rama `main`).

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

## Pendiente (en este orden)
1. **Probar en el iPhone de Diaz** (gratis con su Apple ID, hay que reinstalar cada 7 días). Le di los pasos: conectar y confiar; en Xcode, Signing & Capabilities → Team → su Apple ID (Personal Team); Modo desarrollador en el iPhone; ▶ Run; confiar en el desarrollador en Ajustes → General → VPN y gestión de dispositivos. Comprobar con `xcrun devicectl list devices`. Si el identificador `app.zeno.ZENO` no está disponible, cambiarlo por uno único.
2. **Fluidez** (medir en el iPhone, con números antes y después, mostrando los fps solo en la consola):
   - el gas del cielo a media resolución, con estrellas, lucecitas y cometa nítidos;
   - limitar los cuadros por segundo de Lumi (hoy sin límite: a 120 Hz el shader corre 120 veces por segundo);
   - que el brillo de la tarea anime la opacidad de un resplandor fijo, no el radio de la sombra.
3. **Inglés:** traducir toda la app en `Localizable.xcstrings` (casi vacío). Luego una fila "Idioma" en Ajustes que abra la página de ZENO en los ajustes del iPhone. Probar con `-AppleLanguages "(en)"`.
4. **"Cómo funciona ZENO":** sección con el respaldo científico sobre TDAH (tareas pequeñas, energía, ceguera del tiempo, sin culpa) con fuentes reales verificadas. Diaz preguntó por "respaldo médico": se le explicó que un certificado oficial (FDA o CE) no se logra con código; lo útil es este respaldo científico, la categoría Salud en App Store y que un profesional de TDAH pruebe la app.
5. **iCloud y "Continuar con Apple" de verdad:** cuando Diaz tenga la cuenta de desarrollador de pago (aún no la tiene). Activar las capacidades "Sign in with Apple" e iCloud y sincronizar SwiftData con CloudKit.
6. **Fase 7 (avisos):** construida, falta que Diaz la apruebe.

## Cosas a tener en cuenta
- Los toques en el simulador a veces fallan la primera vez; repetir y mirar con una foto.
- `-datosDeEjemplo YES` crea una persona de prueba con tareas (solo si no hay persona).
- `-galeriaBotones YES` (solo DEBUG) muestra 8 estrellas distintas para revisar colores de halo.
- Hay variantes viejas sin usar en `Lumi/Estilo.swift` (`IconoOrbita`, `BotonSecundario`); no estorban.
- `Comparaciones/video-vs-zeno.jpg` es la referencia que mandó Diaz; no está en git.
