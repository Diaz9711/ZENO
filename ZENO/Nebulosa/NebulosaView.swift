import SwiftUI

/// El fondo vivo de ZENO. Cambia con la persona (semilla), con la hora y con la energía.
struct NebulosaView: View {
    let apariencia: AparienciaLumi
    /// Energía de 0 a 1.
    var energia: Double
    /// 0 = noche violeta, 1 = mañana dorada.
    var calidez: Double
    /// Dónde está Lumi, en proporción de la pantalla. El calor nace ahí.
    var centro: UnitPoint = .center

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var usaSensor = false
    /// Sigue los cambios (energía, calor, dónde está Lumi) a su propio ritmo de cuadros.
    @State private var seguidor = SeguidorDelCielo()

    private static let inicio = Date()

    // Antes el cielo era `Animatable`: mientras Lumi viajaba entre páginas, SwiftUI lo redibujaba
    // entero en cada cuadro de la animación (hasta 120 por segundo), sin respetar sus 30. Medido en el
    // iPhone: los cambios de página bajaban a 30–43 cuadros/s. Ahora el cielo sigue el cambio él solo,
    // con el mismo resorte, pero solo en sus propios cuadros. Se ve igual.

    var body: some View {
        let _ = seguidor.apuntar(SeguidorDelCielo.Valores(energia: energia, calidez: calidez,
                                                          x: centro.x, y: centro.y),
                                 inmediato: reducirMovimiento)
        // 30 cuadros por segundo bastan: el gas se mueve muy despacio.
        // 30 cuadros por segundo; con el ahorro de batería, 12 (el gas se mueve tan despacio que no se nota).
        TimelineView(.animation(minimumInterval: 1.0 / ModoAhorro.compartido.cuadrosDelCielo,
                                paused: reducirMovimiento || ModoAhorro.compartido.enMovimiento)) { linea in
            GeometryReader { geo in
                let t = reducirMovimiento || Pruebas.quieto ? 0 : linea.date.timeIntervalSince(Self.inicio)
                let inclina = reducirMovimiento ? .zero : Inclinacion.compartida.leer()
                let v = seguidor.valores(en: linea.date)
                let energia = v.energia
                let calidez = v.calidez
                let centro = UnitPoint(x: v.x, y: v.y)
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

/// Lleva los valores del cielo desde donde estaban hasta los nuevos con un resorte suave
/// (sin rebote), calculado solo cuando el cielo dibuja un cuadro. No es observable a propósito.
final class SeguidorDelCielo {
    struct Valores: Equatable {
        var energia: Double, calidez: Double, x: CGFloat, y: CGFloat
    }
    private var desde: Valores?
    private var hacia: Valores?
    private var cambio = Date.distantPast

    /// Se llama al redibujar con los valores pedidos; si cambiaron, empieza un viaje nuevo.
    func apuntar(_ nuevos: Valores, inmediato: Bool) {
        guard nuevos != hacia else { return }
        let ahora = Date()
        desde = hacia == nil || inmediato ? nuevos : valores(en: ahora)
        hacia = nuevos
        cambio = ahora
    }

    func valores(en fecha: Date) -> Valores {
        guard let desde, let hacia else { return Valores(energia: 0.5, calidez: 0.5, x: 0.5, y: 0.5) }
        let t = max(fecha.timeIntervalSince(cambio), 0)
        // Resorte críticamente amortiguado: el centro sigue a Lumi (~1 s); la energía cambia más despacio.
        func k(_ w: Double) -> Double { 1 - (1 + w * t) * exp(-w * t) }
        let kc = k(6.5), ke = k(3.2)
        return Valores(energia: desde.energia + (hacia.energia - desde.energia) * ke,
                       calidez: desde.calidez + (hacia.calidez - desde.calidez) * ke,
                       x: desde.x + (hacia.x - desde.x) * kc,
                       y: desde.y + (hacia.y - desde.y) * kc)
    }
}
