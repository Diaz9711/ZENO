import SwiftUI

/// Tu cielo guarda lo que haces (decisión de Diaz): cada tarea terminada deja una estrellita fija.
/// Las de un mismo día se unen con líneas finísimas y forman tus constelaciones.
/// Es una capa encima de la nebulosa: la nebulosa y Lumi no se tocan. Sin números ni culpa: solo crece.
struct ConstelacionView: View {
    /// Las tareas terminadas (del historial ligero), de la más antigua a la más reciente.
    let hechas: [Senal]
    let semilla: Semilla

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    private static let maximo = 160

    struct Punto {
        var x: Double, y: Double      // proporción de la pantalla
        var tamano: Double            // radio en puntos
        var fase: Double              // para el centelleo
        var dia: Int                  // para unir las del mismo día
        var fecha: Date
    }

    var body: some View {
        let puntos = Self.puntos(de: Array(hechas.suffix(Self.maximo)), semilla: semilla)
        let ultima = puntos.last?.fecha
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reducirMovimiento)) { linea in
            Canvas { ctx, size in
                let t = reducirMovimiento ? 0 : linea.date.timeIntervalSinceReferenceDate
                dibujarLineas(puntos, en: &ctx, size: size)
                for (i, p) in puntos.enumerated() {
                    let centro = CGPoint(x: p.x * size.width, y: p.y * size.height)
                    // Las más antiguas brillan un poco menos; nunca se apagan.
                    let edad = Double(puntos.count - 1 - i) / Double(max(puntos.count, 1))
                    var luz = 0.95 - 0.4 * edad
                    luz *= 0.82 + 0.18 * sin(t * 0.9 + p.fase)          // centelleo lento
                    var radio = p.tamano

                    // La recién nacida: aparece después de la onda de luz, con un destello.
                    if p.fecha == ultima {
                        let vida = linea.date.timeIntervalSince(p.fecha) - 1.2
                        if vida < 0 { continue }
                        if vida < 2.4 {
                            let k = vida / 2.4
                            let destello = sin(.pi * min(k * 1.6, 1))
                            radio *= 0.4 + 0.6 * min(k * 2, 1)
                            let anillo = 6 + 26 * k
                            ctx.stroke(Path(ellipseIn: CGRect(x: centro.x - anillo, y: centro.y - anillo,
                                                              width: anillo * 2, height: anillo * 2)),
                                       with: .color(Color.oroClaro.opacity(0.35 * (1 - k))), lineWidth: 0.8)
                            luz = max(luz, 0.6 + 0.4 * destello)
                            radio += 2.2 * destello
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

    /// Líneas casi invisibles entre las estrellas de un mismo día (de izquierda a derecha).
    private func dibujarLineas(_ puntos: [Punto], en ctx: inout GraphicsContext, size: CGSize) {
        let porDia = Dictionary(grouping: puntos, by: \.dia)
        for (_, delDia) in porDia where delDia.count > 1 {
            let orden = delDia.sorted { $0.x < $1.x }
            var camino = Path()
            for (i, p) in orden.enumerated() {
                let punto = CGPoint(x: p.x * size.width, y: p.y * size.height)
                if i == 0 { camino.move(to: punto); continue }
                let previo = orden[i - 1]
                let lejos = hypot((p.x - previo.x) * size.width, (p.y - previo.y) * size.height) > size.width * 0.42
                if lejos { camino.move(to: punto) } else { camino.addLine(to: punto) }
            }
            ctx.stroke(camino, with: .color(Color.oroClaro.opacity(0.13)),
                       style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round))
        }
    }

    /// El lugar de cada estrella sale de tu semilla y del instante en que terminaste la tarea:
    /// siempre el mismo, en cualquier teléfono. Las de un mismo día quedan cerca unas de otras.
    static func puntos(de hechas: [Senal], semilla: Semilla, calendario: Calendar = .current) -> [Punto] {
        hechas.map { s in
            let dia = calendario.ordinality(of: .day, in: .era, for: s.fecha) ?? 0
            // Centro de la constelación de ese día.
            var gDia = GeneradorDeSemilla(Semilla(valor: semilla.valor ^ UInt64(truncatingIfNeeded: dia &* 0x9E37_79B9)))
            let cx = gDia.entre(0.16, 0.84), cy = gDia.entre(0.10, 0.50)
            // La estrella, alrededor de ese centro.
            let segundos = UInt64(truncatingIfNeeded: Int64(s.fecha.timeIntervalSinceReferenceDate))
            var g = GeneradorDeSemilla(Semilla(valor: semilla.valor ^ (segundos &* 0xBF58_476D_1CE4_E5B9)))
            let angulo = g.entre(0, 2 * .pi), distancia = g.entre(0.03, 0.16)
            let x = min(max(cx + cos(angulo) * distancia, 0.05), 0.95)
            let y = min(max(cy + sin(angulo) * distancia * 0.8, 0.05), 0.60)
            // Las tareas grandes dejan una estrella un poco mayor.
            let base: Double = s.tamano == .grande && !s.conPrimerPaso ? 1.7 : (s.tamano == .chica ? 1.0 : 1.3)
            return Punto(x: x, y: y, tamano: base * g.entre(0.85, 1.15), fase: g.entre(0, 2 * .pi), dia: dia, fecha: s.fecha)
        }
    }
}
