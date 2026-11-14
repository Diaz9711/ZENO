import SwiftUI
import Observation

/// Cuánto se ha deslizado la página actual (Tareas o Ajustes), en puntos.
/// Vive aparte de `UniversoView` para que, al deslizar, solo se redibuje Lumi y no todo el universo.
@Observable
final class Desplazamiento {
    static let compartido = Desplazamiento()
    var valor: CGFloat = 0

    /// De 0 (arriba del todo) a 1 (ya se deslizó lo suficiente para que Lumi se retire).
    var progreso: CGFloat { min(max(valor / 170, 0), 1) }
}

/// Lumi se retira con el contenido: se encoge, sube un poco y se desvanece hacia el cielo.
/// Así la página y la estrella se sienten una sola pieza.
struct RetiradaAlDeslizar<Contenido: View>: View {
    var activa: Bool
    @ViewBuilder var contenido: Contenido

    var body: some View {
        let p = activa ? Desplazamiento.compartido.progreso : 0
        contenido
            .scaleEffect(1 - 0.30 * p)
            .opacity(1 - 0.80 * p)
            .offset(y: -34 * p)
    }
}

extension View {
    /// Para una página que se desliza: informa cuánto se movió (solo transform, sin tocar el diseño).
    func informaDesplazamiento() -> some View {
        // `onGeometryChange` funciona desde iOS 16; se mide el contenido dentro del espacio "pagina".
        onGeometryChange(for: CGFloat.self) { geo in
            -geo.frame(in: .named("pagina")).minY
        } action: { nuevo in
            let d = Desplazamiento.compartido
            if abs(d.valor - nuevo) > 0.5 { d.valor = nuevo }
        }
    }

    /// Bordes que se funden: el contenido entra y sale por degradados, nunca por una línea de corte.
    /// `arriba` es dónde empieza a verse del todo; por encima se va desvaneciendo bajo Lumi.
    func bordesFundidos(arriba: CGFloat, abajo: CGFloat = 150) -> some View {
        mask {
            VStack(spacing: 0) {
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .clear, location: 0.35),
                                       .init(color: .black, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: max(arriba, 1))
                Color.black
                // Abajo se apaga del todo antes de la barra, para que nada asome a sus lados.
                LinearGradient(stops: [.init(color: .black, location: 0),
                                       .init(color: .clear, location: 0.62),
                                       .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: abajo)
            }
        }
    }

}
