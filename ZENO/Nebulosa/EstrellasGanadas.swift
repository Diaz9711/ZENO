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
        let ultima = puntos.last?.fecha
        TimelineView(.animation(minimumInterval: 1 / 24, paused: reducirMovimiento)) { linea in
            Canvas { ctx, size in
                let t = reducirMovimiento ? 0 : linea.date.timeIntervalSinceReferenceDate
                for (i, p) in puntos.enumerated() {
                    var centro = CGPoint(x: p.x * size.width, y: p.y * size.height)
                    // Las más antiguas brillan un poco menos; nunca se apagan.
                    let edad = Double(puntos.count - 1 - i) / Double(max(puntos.count, 1))
                    var luz = (0.95 - 0.35 * edad) * (0.80 + 0.20 * sin(t * 0.9 + p.fase))
                    var radio = p.tamano

                    // La recién ganada: sale de Lumi después de la onda de luz y viaja hasta su sitio.
                    if p.fecha == ultima, !reducirMovimiento {
                        let vida = linea.date.timeIntervalSince(p.fecha) - 1.0
                        if vida < 0 { continue }
                        let viaje = 1.8
                        if vida < viaje + 1.4 {
                            let desde = CGPoint(x: origen.x * size.width, y: origen.y * size.height)
                            let k = min(vida / viaje, 1)
                            let suave = 1 - pow(1 - k, 3)
                            // Un arco suave, como si flotara hacia arriba.
                            let arco = sin(.pi * suave) * size.height * 0.06
                            let hasta = centro
                            centro = CGPoint(x: desde.x + (hasta.x - desde.x) * suave,
                                             y: desde.y + (hasta.y - desde.y) * suave - arco)
                            if k < 1 {
                                // Su estela, que se apaga detrás.
                                let atras = max(suave - 0.12, 0)
                                let cola = CGPoint(x: desde.x + (hasta.x - desde.x) * atras,
                                                   y: desde.y + (hasta.y - desde.y) * atras - sin(.pi * atras) * size.height * 0.06)
                                var estela = Path()
                                estela.move(to: cola)
                                estela.addLine(to: centro)
                                ctx.stroke(estela, with: .linearGradient(
                                    Gradient(colors: [.clear, Color.oroClaro.opacity(0.7)]),
                                    startPoint: cola, endPoint: centro), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                                luz = 1
                                radio *= 1.6
                            } else {
                                // Al llegar, un destello que se asienta.
                                let llegada = (vida - viaje) / 1.4
                                let anillo = 5 + 22 * llegada
                                ctx.stroke(Path(ellipseIn: CGRect(x: centro.x - anillo, y: centro.y - anillo,
                                                                  width: anillo * 2, height: anillo * 2)),
                                           with: .color(Color.oroClaro.opacity(0.35 * (1 - llegada))), lineWidth: 0.8)
                                luz = max(luz, 1 - 0.3 * llegada)
                                radio *= 1 + 0.8 * (1 - llegada)
                            }
                        }
                    }
                    let halo = radio * 4.5
                    ctx.fill(Path(ellipseIn: CGRect(x: centro.x - halo, y: centro.y - halo, width: halo * 2, height: halo * 2)),
                             with: .radialGradient(Gradient(colors: [Color.oroClaro.opacity(0.28 * luz), .clear]),
                                                   center: centro, startRadius: 0, endRadius: halo))
                    ctx.fill(Path(ellipseIn: CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2)),
                             with: .color(Color.marfil.opacity(luz)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
