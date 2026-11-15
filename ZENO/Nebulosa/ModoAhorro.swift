import Foundation
import Observation

/// El "Modo de bajo consumo" del iPhone. Con él activado iOS recorta mucho la potencia gráfica
/// (medido en el iPhone de Diaz: ZENO bajaba a 20 cuadros/s). Entonces el cielo y Lumi se
/// recalculan menos veces por segundo; se ven igual. Nada más se recorta: nunca se pausa el cielo
/// (una pausa al cambiar de página se veía como un corte de imagen, 15 nov 2026).
@MainActor @Observable
final class ModoAhorro {
    static let compartido = ModoAhorro()
    private(set) var activo = ProcessInfo.processInfo.isLowPowerModeEnabled

    private init() {
        NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { _ in
            Task { @MainActor in ModoAhorro.compartido.activo = ProcessInfo.processInfo.isLowPowerModeEnabled }
        }
    }
}
