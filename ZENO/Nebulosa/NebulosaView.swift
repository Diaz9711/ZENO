import SwiftUI

/// El fondo vivo de ZENO. Cambia con la persona (semilla), con la hora y con la energía.
struct NebulosaView: View, Animatable {
    let apariencia: AparienciaLumi
    /// Energía de 0 a 1.
    var energia: Double
    /// 0 = noche violeta, 1 = mañana dorada.
    var calidez: Double
    /// Dónde está Lumi, en proporción de la pantalla. El calor nace ahí.
    var centro: UnitPoint = .center

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var usaSensor = false

    private static let inicio = Date()

    // Permite que la energía, la calidez y el centro cambien poco a poco con `withAnimation`:
    // cuando Lumi se mueve, el calor del cielo la sigue.
    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(energia, calidez), AnimatablePair(centro.x, centro.y)) }
        set {
            energia = newValue.first.first
            calidez = newValue.first.second
            centro = UnitPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    var body: some View {
        // 30 cuadros por segundo bastan: el gas se mueve muy despacio.
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reducirMovimiento)) { linea in
            GeometryReader { geo in
                let t = reducirMovimiento || Pruebas.quieto ? 0 : linea.date.timeIntervalSince(Self.inicio)
                let inclina = reducirMovimiento ? .zero : Inclinacion.compartida.leer()
                Rectangle()
                    .fill(Color("FondoArranque"))
                    .colorEffect(ShaderLibrary.nebulosa(
                        .float2(geo.size),
                        .float2(geo.size.width * centro.x, geo.size.height * centro.y),
                        .float(t),
                        .float2(inclina.x, inclina.y),
                        .float2(apariencia.desplazamiento.x, apariencia.desplazamiento.y),
                        .float(energia),
                        .float(calidez),
                        .float3(apariencia.colorFondo.x, apariencia.colorFondo.y, apariencia.colorFondo.z),
                        .float3(apariencia.colorNube.x, apariencia.colorNube.y, apariencia.colorNube.z),
                        .float3(apariencia.colorBrasa.x, apariencia.colorBrasa.y, apariencia.colorBrasa.z),
                        .float3(apariencia.colorOro.x, apariencia.colorOro.y, apariencia.colorOro.z),
                        .float(CalidadVisual.nivel)
                    ))
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear { if !reducirMovimiento { Inclinacion.compartida.empezar(); usaSensor = true } }
        .onDisappear { if usaSensor { Inclinacion.compartida.detener(); usaSensor = false } }
    }
}
