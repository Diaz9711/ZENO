import SwiftUI
import Observation

/// Cuánto se ha deslizado la página de Ajustes o de Tareas.
/// Lo lee solo la envoltura de Lumi (`LumiQueSeRetira`): así, al deslizar, no se vuelve a
/// dibujar todo el universo en cada cuadro, solo la estrella.
@Observable
final class DesplazamientoDePagina {
    /// Puntos deslizados desde arriba (0 = la página en su sitio).
    var valor: CGFloat = 0
}

private struct ClaveDesplazamiento: EnvironmentKey {
    static let defaultValue: DesplazamientoDePagina? = nil
}

extension EnvironmentValues {
    var desplazamientoDePagina: DesplazamientoDePagina? {
        get { self[ClaveDesplazamiento.self] }
        set { self[ClaveDesplazamiento.self] = newValue }
    }
}

/// Lumi se retira con calma mientras la página sube: se hace más pequeña, sube un poco
/// y se apaga a medias, como si se alejara. Nunca desaparece del todo.
struct LumiQueSeRetira<Contenido: View>: View {
    let desplazamiento: DesplazamientoDePagina
    /// Solo en Tareas y Ajustes; en Hoy Lumi no se mueve con nada.
    let activo: Bool
    @ViewBuilder let contenido: () -> Contenido

    var body: some View {
        // 0 arriba del todo; 1 después de 160 puntos deslizados.
        let p = activo ? min(max(desplazamiento.valor / 160, 0), 1) : 0
        contenido()
            .scaleEffect(1 - 0.32 * p)
            .opacity(1 - 0.62 * p)
            .offset(y: -26 * p)
    }
}

/// Lleva la cuenta del desplazamiento de un `ScrollView` (iOS 17: con una geometría dentro del contenido).
private struct ClaveDeAltura: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    /// Para poner al principio del contenido de un `ScrollView` con `.coordinateSpace(name:)`.
    func medirDesplazamiento(en espacio: String) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: ClaveDeAltura.self,
                                       value: -geo.frame(in: .named(espacio)).minY)
            }
        )
    }

    /// Escucha el desplazamiento medido y se lo pasa a Lumi.
    func alDesplazar(_ desplazamiento: DesplazamientoDePagina?) -> some View {
        onPreferenceChange(ClaveDeAltura.self) { valor in
            // Redondeado a medio punto: menos trabajo y ningún temblor.
            let redondo = (max(valor, 0) * 2).rounded() / 2
            if desplazamiento?.valor != redondo { desplazamiento?.valor = redondo }
        }
    }

    /// El contenido se funde con el cielo al subir: arriba transparente, después opaco.
    /// Sin líneas de corte ni bordes duros. `inicio` es dónde empieza a verse del todo.
    func fundidoSuperior(inicio: CGFloat, largo: CGFloat = 70) -> some View {
        mask {
            VStack(spacing: 0) {
                Color.clear.frame(height: max(inicio - largo, 0))
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .black.opacity(0.55), location: 0.55),
                                       .init(color: .black, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: largo)
                Color.black
            }
        }
    }
}
