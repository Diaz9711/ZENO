import SwiftUI

/// Cada tarea terminada es una estrella nueva en tu cielo (decisión de Diaz, 14 nov 2026).
/// Sin líneas ni números: solo estrellas que se quedan para siempre. La nueva nace de Lumi y viaja
/// hasta su lugar. Es una capa encima de la nebulosa: la nebulosa y Lumi no se tocan.
struct EstrellasGanadas: View {
    /// Las tareas terminadas (del historial ligero), de la más antigua a la más reciente.
    let hechas: [Senal]
    let semilla: Semilla
    /// Dónde está Lumi (proporción de la pantalla): de ahí sale la estrella nueva.
    var origen: UnitPoint = UnitPoint(x: 0.5, y: 0.245)

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    private static let maximo = 200

    struct Punto {
        var x: Double, y: Double      // proporción de la pantalla
        var tamano: Double            // radio en puntos
        var fase: Double              // para el centelleo
        var fecha: Date
    }

    var body: some View {
        let puntos = Self.puntos(de: Array(hechas.suffix(Self.maximo)), semilla: semilla)
        let ultima = puntos.last
        // Las que ya están en su sitio se dibujan una sola vez (sin animación: no cuestan nada
        // mientras usas la app). Solo la recién ganada se anima, durante sus primeros segundos.
        let naciendo = !reducirMovimiento && (ultima.map { Date.now.timeIntervalSince($0.fecha) < Self.duracion } ?? false)
        ZStack {
            Canvas { ctx, size in
                for (i, p) in puntos.enumerated() where !(naciendo && i == puntos.count - 1) {
                    let edad = Double(puntos.count - 1 - i) / Double(max(puntos.count, 1))
                    let luz = (0.95 - 0.35 * edad) * (0.85 + 0.15 * sin(p.fase))
                    Self.estrella(en: &ctx, centro: CGPoint(x: p.x * size.width, y: p.y * size.height),
                                  radio: p.tamano, luz: luz)
                }
            }
            if naciendo, let p = ultima {
                NacimientoDeEstrella(punto: p, origen: origen)
                    .id(p.fecha)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    static let duracion: TimeInterval = 4.4

    static func estrella(en ctx: inout GraphicsContext, centro: CGPoint, radio: Double, luz: Double) {
        let halo = radio * 4.5
        ctx.fill(Path(ellipseIn: CGRect(x: centro.x - halo, y: centro.y - halo, width: halo * 2, height: halo * 2)),
                 with: .radialGradient(Gradient(colors: [Color.oroClaro.opacity(0.28 * luz), .clear]),
                                       center: centro, startRadius: 0, endRadius: halo))
        ctx.fill(Path(ellipseIn: CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2)),
                 with: .color(Color.marfil.opacity(luz)))
    }

    /// El lugar de cada estrella sale de tu semilla y del instante en que terminaste la tarea:
    /// siempre el mismo, repartidas por todo el cielo de arriba.
    static func puntos(de hechas: [Senal], semilla: Semilla) -> [Punto] {
        hechas.map { s in
            let segundos = UInt64(truncatingIfNeeded: Int64(s.fecha.timeIntervalSinceReferenceDate))
            var g = GeneradorDeSemilla(Semilla(valor: semilla.valor ^ (segundos &* 0xBF58_476D_1CE4_E5B9)))
            let x = g.entre(0.05, 0.95)
            let y = g.entre(0.05, 0.62)
            // Las tareas grandes dejan una estrella un poco mayor.
            let base: Double = s.tamano == .grande && !s.conPrimerPaso ? 1.7 : (s.tamano == .chica ? 1.0 : 1.3)
            return Punto(x: x, y: y, tamano: base * g.entre(0.85, 1.15), fase: g.entre(0, 2 * .pi), fecha: s.fecha)
        }
    }
}

/// La estrella recién ganada: sale de Lumi tras la onda de luz, viaja con su estela y se asienta con un destello.
/// Solo esta pieza se anima, y solo unos segundos; luego desaparece y la estrella queda en el dibujo fijo.
private struct NacimientoDeEstrella: View {
    let punto: EstrellasGanadas.Punto
    let origen: UnitPoint
    @State private var terminado = false

    var body: some View {
        if !terminado {
            TimelineView(.animation(minimumInterval: 1 / 60)) { linea in
                Canvas { ctx, size in
                    let vida = linea.date.timeIntervalSince(punto.fecha) - 1.0
                    guard vida >= 0 else { return }
                    let viaje = 1.8
                    let desde = CGPoint(x: origen.x * size.width, y: origen.y * size.height)
                    let hasta = CGPoint(x: punto.x * size.width, y: punto.y * size.height)
                    let k = min(vida / viaje, 1)
                    let suave = 1 - pow(1 - k, 3)
                    func enArco(_ f: Double) -> CGPoint {
                        CGPoint(x: desde.x + (hasta.x - desde.x) * f,
                                y: desde.y + (hasta.y - desde.y) * f - sin(.pi * f) * size.height * 0.06)
                    }
                    let centro = enArco(suave)
                    if k < 1 {
                        let cola = enArco(max(suave - 0.12, 0))
                        var estela = Path()
                        estela.move(to: cola)
                        estela.addLine(to: centro)
                        ctx.stroke(estela, with: .linearGradient(Gradient(colors: [.clear, Color.oroClaro.opacity(0.7)]),
                                                                 startPoint: cola, endPoint: centro),
                                   style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                        EstrellasGanadas.estrella(en: &ctx, centro: centro, radio: punto.tamano * 1.6, luz: 1)
                    } else {
                        let llegada = min((vida - viaje) / 1.4, 1)
                        let anillo = 5 + 22 * llegada
                        ctx.stroke(Path(ellipseIn: CGRect(x: centro.x - anillo, y: centro.y - anillo,
                                                          width: anillo * 2, height: anillo * 2)),
                                   with: .color(Color.oroClaro.opacity(0.35 * (1 - llegada))), lineWidth: 0.8)
                        EstrellasGanadas.estrella(en: &ctx, centro: centro,
                                                  radio: punto.tamano * (1 + 0.8 * (1 - llegada)), luz: 1 - 0.1 * llegada)
                    }
                }
            }
            .task {
                let resta = EstrellasGanadas.duracion - Date.now.timeIntervalSince(punto.fecha)
                try? await Task.sleep(for: .seconds(max(resta, 0)))
                terminado = true
            }
        } else {
            // Ya asentada: se queda quieta en su sitio, igual que las demás.
            Canvas { ctx, size in
                EstrellasGanadas.estrella(en: &ctx, centro: CGPoint(x: punto.x * size.width, y: punto.y * size.height),
                                          radio: punto.tamano, luz: 0.95)
            }
        }
    }
}
