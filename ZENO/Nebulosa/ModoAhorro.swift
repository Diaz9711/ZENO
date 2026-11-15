import Foundation
import Observation

/// El "Modo de bajo consumo" del iPhone. Con él activado iOS recorta mucho la potencia gráfica
/// (medido en el iPhone de Diaz: ZENO bajaba a 20 cuadros/s). Entonces el cielo y Lumi se
/// recalculan menos veces por segundo; se ven exactamente igual y su movimiento es muy lento,
/// así que no se nota, y deslizar y abrir hojas recuperan la fluidez.
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
