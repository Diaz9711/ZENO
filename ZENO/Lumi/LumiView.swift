import SwiftUI
import simd

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
    /// Brillo extra (0–1): Lumi queda más luminosa después de una tarea difícil.
    var destello: Double = 0
    /// Cuadros por segundo. 60 bastan para la estrella grande (en un iPhone de 120 Hz el shader
    /// corría el doble sin que se notara); las vistas previas pequeñas van a 30.
    var cuadros: Double = 60

    // Permite que la energía cambie poco a poco con `withAnimation`.
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(energia, destello) }
        set { energia = newValue.first; destello = newValue.second }
    }

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var reloj = RelojDeLumi()

    // Amarillos cálidos de la estrella según la energía (tono, saturación, brillo).
    private static let coronaBaja = AparienciaLumi.hsb(0.108, 0.72, 1.0)   // oro cálido y hondo
    private static let coronaAlta = AparienciaLumi.hsb(0.138, 0.55, 1.0)   // amarillo claro
    private static let nucleoBajo = AparienciaLumi.hsb(0.112, 0.46, 1.0)
    private static let nucleoAlto = AparienciaLumi.hsb(0.142, 0.30, 1.0)

    /// Lumi ya muestra la energía con su luz; VoiceOver la dice en palabras.
    private var nivelDeEnergia: LocalizedStringKey {
        switch MotorDeEnergia.nivel(energia * 100) {
        case .alta: "Energía alta"
        case .media: "Energía media"
        case .baja: "Energía baja"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / cuadros, paused: reducirMovimiento)) { linea in
            let m = reloj.avanzar(hasta: linea.date,
                                  energia: energia,
                                  apariencia: apariencia,
                                  quieto: reducirMovimiento || Pruebas.quieto)
            // La luz va y viene entre sus dos tonos: viva, pero siempre ella misma.
            // El color sigue a la energía: con poca, oro cálido y hondo; con mucha, amarillo claro
            // y brillante. Nunca naranja. La luz de cada persona tiñe el resultado y respira apenas.
            let e = Float(min(max(energia, 0), 1))
            let mezcla = Float(0.5 - 0.5 * cos(m.tiempo * 2 * .pi / apariencia.periodoDeLuz)) * 0.35
            let propiaCorona = simd_mix(apariencia.colorCorona, apariencia.colorCoronaVecino, SIMD3(repeating: mezcla))
            let propioNucleo = simd_mix(apariencia.colorNucleo, apariencia.colorNucleoVecino, SIMD3(repeating: mezcla))
            let coronaEnergia = simd_mix(Self.coronaBaja, Self.coronaAlta, SIMD3(repeating: e))
            let nucleoEnergia = simd_mix(Self.nucleoBajo, Self.nucleoAlto, SIMD3(repeating: e))
            let corona = simd_mix(propiaCorona, coronaEnergia, SIMD3(repeating: 0.65))
            let nucleo = simd_mix(propioNucleo, nucleoEnergia, SIMD3(repeating: 0.65))
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
                        .float(destello),
                        .float(m.fase),
                        .float(Double(apariencia.olaDeRayos)),
                        .float2(apariencia.inclinacionOrbita, apariencia.giroOrbita),
                        .float(Double(forma.rawValue)),
                        .float3(nucleo.x, nucleo.y, nucleo.z),
                        .float3(corona.x, corona.y, corona.z),
                        .float3(apariencia.colorHalo.x, apariencia.colorHalo.y, apariencia.colorHalo.z),
                        .float(CalidadVisual.nivel)
                    ))
                    .offset(x: m.flotarX * geo.size.width, y: m.flotarY * geo.size.width)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(Text("Lumi, tu estrella"))
        .accessibilityValue(Text(nivelDeEnergia))
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
