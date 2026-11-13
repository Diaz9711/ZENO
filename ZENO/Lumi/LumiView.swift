import SwiftUI

/// Las dos formas de Lumi. Nunca se mezclan. La persona elige la que más le guste
/// (en el registro, y después en Ajustes); si no elige, es `.estrella`.
enum FormaDeLumi: Int, CaseIterable, Identifiable {
    case estrella, esfera
    var id: Int { rawValue }
}

/// Lumi: una estrella de luz que respira. Comunica con luz y movimiento, nunca con texto.
struct LumiView: View, Animatable {
    let apariencia: AparienciaLumi
    /// Energía de 0 a 1.
    var energia: Double
    var forma: FormaDeLumi = .estrella

    // Permite que la energía cambie poco a poco con `withAnimation`.
    var animatableData: Double {
        get { energia }
        set { energia = newValue }
    }

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var reloj = RelojDeLumi()

    var body: some View {
        TimelineView(.animation(paused: reducirMovimiento)) { linea in
            let m = reloj.avanzar(hasta: linea.date,
                                  energia: energia,
                                  apariencia: apariencia,
                                  quieto: reducirMovimiento)
            GeometryReader { geo in
                Rectangle()
                    .fill(.white)
                    .colorEffect(ShaderLibrary.lumi(
                        .float2(geo.size),
                        .float(m.tiempo),
                        .float2(apariencia.desplazamiento.x, apariencia.desplazamiento.y),
                        .float(energia),
                        .float(m.respiro),
                        .float(m.giro),
                        .float(Double(apariencia.lobulos)),
                        .float(apariencia.profundidadLobulo),
                        .float(0),
                        .float(m.fase),
                        .float(Double(apariencia.olaDeRayos)),
                        .float2(apariencia.inclinacionOrbita, apariencia.giroOrbita),
                        .float(Double(forma.rawValue)),
                        .float3(apariencia.colorNucleo.x, apariencia.colorNucleo.y, apariencia.colorNucleo.z),
                        .float3(apariencia.colorCorona.x, apariencia.colorCorona.y, apariencia.colorCorona.z),
                        .float3(apariencia.colorHalo.x, apariencia.colorHalo.y, apariencia.colorHalo.z)
                    ))
                    .offset(x: m.flotarX * geo.size.width, y: m.flotarY * geo.size.width)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(Text("Lumi, tu estrella"))
    }
}

/// Lleva el ritmo de Lumi. Acumula el movimiento poco a poco para que,
/// al cambiar la energía, la estrella acelere o frene sin dar saltos.
final class RelojDeLumi {
    struct Momento {
        var tiempo: Double = 0
        var respiro: Double = 0
        var giro: Double = 0
        var fase: Double = 0
        var flotarX: Double = 0
        var flotarY: Double = 0
    }

    private var ultima: Date?
    private var tiempo = 0.0
    private var faseRespiro = 0.0
    private var faseFlotar = 0.0
    private var giro = 0.0

    func avanzar(hasta fecha: Date, energia: Double, apariencia: AparienciaLumi, quieto: Bool) -> Momento {
        if quieto { return Momento() }

        let dt = min(max(fecha.timeIntervalSince(ultima ?? fecha), 0), 0.1)
        ultima = fecha
        tiempo += dt

        // Energía baja: respira y flota más lento.
        let ritmo = 0.62 + 0.38 * energia
        faseRespiro += dt * 2 * .pi / apariencia.periodoRespiracion * ritmo
        faseFlotar += dt * (0.22 + 0.36 * energia)
        giro += dt * apariencia.sentidoDeGiro * (0.05 + 0.10 * energia)

        // Mantener los números pequeños aunque la app pase horas abierta.
        if faseRespiro > 2000 * .pi { faseRespiro -= 2000 * .pi }
        if abs(giro) > 2000 * .pi { giro -= giro.sign == .minus ? -2000 * .pi : 2000 * .pi }

        // Inhalar toma un poco menos que exhalar: se siente vivo.
        let s = sin(faseRespiro)
        let respiro = s - 0.18 * sin(2 * faseRespiro)

        let amplitud = 0.012 + 0.010 * energia
        return Momento(
            tiempo: tiempo,
            respiro: respiro,
            giro: giro,
            fase: faseRespiro / (2 * .pi),
            // Cada persona flota con su propio vaivén.
            flotarX: sin(faseFlotar * apariencia.ritmoDeFlote + 1.3) * amplitud * 0.7,
            flotarY: sin(faseFlotar) * amplitud + sin(faseFlotar * 0.47 * apariencia.ritmoDeFlote) * amplitud * 0.5
        )
    }
}
