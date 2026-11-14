# ZENO — reglas para Claude Code

La especificación completa está en `ZENO_SPEC.md`. Léela antes de cambiar algo. Esto es el resumen que nunca se rompe.

## Con quién trabajas
- Diaz, el dueño, **no programa**. Explica cada paso en español sencillo y dile exactamente qué tocar en Xcode.
- Una fase a la vez. No avances hasta que Diaz confirme que lo que ve en el simulador le gusta.
- Al terminar cada fase: que compile, que corra en el simulador y decirle qué probar.

## Regla de oro
**ZENO nunca pide atención, la merece.** Sin culpa, sin rachas rotas, sin números en rojo, sin confeti, sin sonidos agudos. Lumi nunca pierde luz como castigo.

## Técnica
- iPhone nativo, SwiftUI, iOS 17+. SwiftData, todo en el teléfono. Sin cuentas, sin servidor, sin analíticas de terceros. Cambio de Diaz (14 nov 2026, más tarde): la bienvenida tiene **menú de entrada** (`MenuDeEntrada`): "Continuar con Apple" y "Entrar como invitado". Los datos siguen solo en el teléfono; `Persona.cuentaApple` guarda el identificador para sincronizar con iCloud más adelante. Falta activar la capacidad "Sign in with Apple" (y luego iCloud) en Xcode con la cuenta de desarrollador de pago.
- Lumi y la nebulosa se dibujan por código (shaders Metal en `ZENO/Nebulosa/Sombras.metal`). Nada de imágenes fijas.
- La estrella nace de la semilla (nombre + fecha de nacimiento). La misma semilla da siempre la misma estrella. La persona no elige colores ni movimiento; solo la forma (estrella o esfera).
- Fondo: nebulosa azul profundo, que se aclara hacia la estrella. **Nunca negro puro.** (Diaz eligió azulado sobre el vino original el 12 nov 2026; el vino sigue en el código pero ya no tiene selector.)
- Lumi tiene **dos formas que nunca se mezclan** (`FormaDeLumi`): `.estrella` (corazón de luz sin borde + rayos finos, 4 a 8 según la semilla) y `.esfera` (bola dorada de luz líquida con contorno nítido). **La persona elige cuál quiere** (decisión de Diaz): en el registro al nacer su Lumi (Fase 2) y luego en Ajustes; se guarda en `Persona.formaDeLumi`, por defecto estrella. Diaz probó unirlas y le pareció rara: no combinar esfera con rayos. Comparten halo, resplandor y motas.
- **Animación única por persona**, toda derivada de la semilla en `AparienciaLumi`: número de rayos, ola de rayos, sentido de giro, periodo de respiración, órbita de las motas y vaivén al flotar.
- **La energía cambia la luz, el tamaño y el ritmo, nunca el detalle.** Con energía baja Lumi es más pequeña y tenue y el cielo más oscuro, pero todo sigue nítido (pedido expreso de Diaz).
- Una sola acción por pantalla. Mucho espacio vacío.
- Tipografía (Diaz pidió nada genérico, nada de letras de sistema): títulos con `Font.zenoTitulo`, botones y textos pequeños con `Font.zenoTexto` (Manrope). Logotipo `MarcaZeno`: sol dibujado + ZENO en Bebas Neue espaciada. Texto en `Color.marfil`, acentos en `Color.oroZeno`. El oro de ZENO es **luz de estrella** (pálido, amarillo, metálico: `oroClaro` → `oroZeno` → `oroHondo`); **nunca naranja ni durazno**, porque se parece a Claude y a otras apps (Diaz, 14 nov 2026).
- Botones y campos usan `.cristal()` (vidrio oscuro con borde de luz dorada) y `EstiloPresion`; nunca grises planos de sistema. Íconos dibujados a mano (`IconoOrbita`), sin SF Symbols genéricos.
- Texto sobre el cielo: títulos con `.luminoso()` (marfil→oro, sombra y halo), etiquetas `Etiqueta` en mayúsculas doradas, y un velo oscuro suave bajo Lumi. Acciones secundarias con `BotonSecundario`; listas con filas de cristal, nunca `List` de sistema; interruptores con `InterruptorZeno`.
- Navegación (inspirada en un video de referencia que mandó Diaz): `BarraZeno` flotante abajo con glifos propios (`GlifoView`: hoy, tareas, ajustes, más) y la página activa encendida en oro. Tareas y Ajustes son **páginas dentro del universo, no hojas de sistema**: Lumi viaja arriba y se hace pequeña (`Pagina`). Todo entra y sale con `.transition(.desenfoque)` y `.aparece(n)` escalonado; nunca cortes ni hojas grises.
- Botón principal (`BotonZeno`): **en revisión con Diaz**. Propuesta actual: una sola píldora de oro con la palabra, 280 × 50 (igual que los botones de la bienvenida), sin flecha ni adornos; al tocar se hunde y se enciende. Se borraron las variantes descartadas (órbita, cometa, nebulosa, galaxia, cristal). En Hoy no hay botón: la tarea misma se toca para empezar y se mantiene para terminar.
- Registro: estructura común en todos los pasos (volver dibujado + línea de progreso, título Fraunces + una línea de razón en Manrope, contenido, botón abajo). Opciones como filas de cristal con círculo; margen 28, radio 16.
- La pantalla de hoy no debe verse vacía: `EncabezadoDeHoy` (saludo + nombre; la energía solo se ve en la luz) y `TarjetaDeHoy` (hechas hoy, minutos en foco, mejor hora). Solo datos de progreso, nunca pendientes ni deuda.
- Los controles de prueba solo aparecen con Ajustes → Modo de prueba (solo en DEBUG).
- Tipografías propias incluidas en `ZENO/Fuentes` (Google Fonts, licencia OFL en `Licencias/`): **Fraunces** para títulos (`Font.zenoTitulo`, con `cursiva:`), **Manrope** para texto (`Font.zenoTexto`), **Bebas Neue** para el logotipo (`Font.zenoMarca`). Decisión de Diaz; no volver a letras de sistema.
- Bienvenida (decisión de Diaz, 14 nov 2026): solo el universo, el sol con su órbita y ZENO letra por letra, más el botón "Crear mi estrella". Sin frases. El aviso de que ZENO no diagnostica va en el paso del nombre. Cada vez que se abre la app sale la **presentación corta** (universo, sol y ZENO, unos 5,5 s, sin botón; tocar la salta) y luego se entra directo a Hoy: sin fecha, sin edad ni frase (Diaz quitó el momento de presencia; `PresenciaView` queda solo en el modo de prueba).
- Transiciones continuas: Lumi nunca desaparece y reaparece; se mueve como objeto físico.
- Respetar Reducir Movimiento, Dynamic Type y contraste.
- Español e inglés con String Catalog (`Localizable.xcstrings`). El español es el idioma base.
- ZENO no diagnostica ni reemplaza tratamiento.

## Código
- Nombres en español, sin acentos ni ñ en nombres de archivos y tipos (`EventoDeEnergia`, `TamanoDeTarea`).
- La carpeta `ZENO/` se sincroniza sola con Xcode: un archivo nuevo ahí ya forma parte de la app.
- Carpetas: `Modelos/` (SwiftData), `Lumi/` (semilla, apariencia, estrella), `Nebulosa/` (fondo y shaders), `Pantallas/`.
- Dejar sitio para la versión 2 (salud, hiperfoco, anclas, reporte) sin construirla todavía.

## Compilar y correr
```bash
xcodebuild -project ZENO.xcodeproj -scheme ZENO -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
```

## Fases
0 Proyecto · 1 Lumi y nebulosa · 2 Registro · 3 Presencia · 4 Tareas · 5 Energía · 6 Anillo y celebración · 7 Notificaciones · 8 Pulido.

- `UniversoView` es la raíz: el cielo y Lumi viven ahí y nunca se destruyen; el contenido (registro, casa, y luego presencia y tareas) va encima. No crear otra LumiView por pantalla.

- Dictado por voz: **solo reconocimiento dentro del teléfono** (`requiresOnDeviceRecognition`); si el idioma no lo permite, se avisa y se escribe. La voz nunca sale del dispositivo.
- Tamaño de tarea: `ClasificadorDeTamano`, regla simple por palabras clave. La tarea del momento por ahora es la más antigua; la elección por energía llega en la Fase 5.

- Energía: `MotorDeEnergia` (funciones puras). Puntaje = curva base del cronotipo + lo aprendido por franja horaria + ajuste de hoy; todo se recalcula desde el historial `EventoDeEnergia`. Niveles: baja < 34, media 34–66, alta ≥ 67. "Ahora no" pospone esa tarea 90 minutos. Lumi y la nebulosa usan el puntaje real.
- Celebración y anillo: `Lumi/Celebracion.swift`. Anillo de tiempo según `Tarea.minutosPrevistos` (primer paso 2, chica 5, mediana 15, grande 25 min); al acabarse no hay alarma. Al terminar: Lumi inhala, onda de luz de 1,5 s y ola háptica (Core Haptics). Grande: onda más amplia y Lumi más brillante el resto del día. Tres seguidas: giro lento. Con energía baja: el cielo se calienta ese día.

- Avisos (Fase 7): `Notificaciones/Avisos.swift`. Plan puro `Avisos.plan` + programación al abrir y al salir (iOS no corre código cuando llega un aviso). Aviso diario no repetitivo a `mejorHora`, nunca el día en que ya se abrió; 'Lumi sigue aquí' a los 3 días sin uso; pausa tras 2 ignorados (ignorado = no tocado y sin abrir la app en 3 h). Nunca texto de tareas ni sonido. El delegado `CentroDeAvisos` se instala en `ZENOApp.init`.

Estado: Fases 0 a 6 aprobadas y guardadas en git; letra Fraunces elegida. Fase 7 (avisos) construida, pendiente de que Diaz la apruebe.
