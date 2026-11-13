# ZENO — reglas para Claude Code

La especificación completa está en `ZENO_SPEC.md`. Léela antes de cambiar algo. Esto es el resumen que nunca se rompe.

## Con quién trabajas
- Diaz, el dueño, **no programa**. Explica cada paso en español sencillo y dile exactamente qué tocar en Xcode.
- Una fase a la vez. No avances hasta que Diaz confirme que lo que ve en el simulador le gusta.
- Al terminar cada fase: que compile, que corra en el simulador y decirle qué probar.

## Regla de oro
**ZENO nunca pide atención, la merece.** Sin culpa, sin rachas rotas, sin números en rojo, sin confeti, sin sonidos agudos. Lumi nunca pierde luz como castigo.

## Técnica
- iPhone nativo, SwiftUI, iOS 17+. SwiftData, todo en el teléfono. Sin cuentas, sin servidor, sin analíticas de terceros.
- Lumi y la nebulosa se dibujan por código (shaders Metal en `ZENO/Nebulosa/Sombras.metal`). Nada de imágenes fijas.
- La estrella nace de la semilla (nombre + fecha de nacimiento). La misma semilla da siempre la misma estrella. La persona no elige colores ni movimiento; solo la forma (estrella o esfera).
- Fondo: nebulosa azul profundo, que se aclara hacia la estrella. **Nunca negro puro.** (Diaz eligió azulado sobre el vino original el 12 nov 2026; el vino sigue en el código pero ya no tiene selector.)
- Lumi tiene **dos formas que nunca se mezclan** (`FormaDeLumi`): `.estrella` (corazón de luz sin borde + rayos finos, 4 a 8 según la semilla) y `.esfera` (bola dorada de luz líquida con contorno nítido). **La persona elige cuál quiere** (decisión de Diaz): en el registro al nacer su Lumi (Fase 2) y luego en Ajustes; se guarda en `Persona.formaDeLumi`, por defecto estrella. Diaz probó unirlas y le pareció rara: no combinar esfera con rayos. Comparten halo, resplandor y motas.
- **Animación única por persona**, toda derivada de la semilla en `AparienciaLumi`: número de rayos, ola de rayos, sentido de giro, periodo de respiración, órbita de las motas y vaivén al flotar.
- **La energía cambia la luz, el tamaño y el ritmo, nunca el detalle.** Con energía baja Lumi es más pequeña y tenue y el cielo más oscuro, pero todo sigue nítido (pedido expreso de Diaz).
- Una sola acción por pantalla. Mucho espacio vacío.
- Tipografía: SF Pro Rounded. Bebas Neue solo para el logotipo.
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

Estado: Fases 0, 1 y 2 aprobadas y guardadas en git. Fase 3 (momento de presencia) construida, pendiente de que Diaz la apruebe. La tarea del momento es todavía un texto provisional (`TareaProvisionalView`).
