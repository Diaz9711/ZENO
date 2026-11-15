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
    /// El iPhone está caliente: iOS ya recorta la potencia, así que el cielo también se aligera.
    private(set) var caliente = ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    /// Hay un movimiento de la interfaz en marcha (cambio de página, deslizar, una hoja): el cielo
    /// espera ese instante sin recalcularse, para que toda la potencia vaya al dedo. Su gas se mueve
    /// tan despacio que la pausa no se ve.
    private(set) var enMovimiento = false
    private var finDelMovimiento = Date.distantPast

    /// Cuadros por segundo del cielo según el momento.
    var cuadrosDelCielo: Double { activo || caliente ? 12 : 30 }
    /// Tope de cuadros de Lumi según el momento.
    var topeDeLumi: Double { activo || caliente || enMovimiento ? 30 : 60 }

    private init() {
        NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { _ in
            Task { @MainActor in ModoAhorro.compartido.activo = ProcessInfo.processInfo.isLowPowerModeEnabled }
        }
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                ModoAhorro.compartido.caliente = ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
            }
        }
    }

    /// Avisa de un movimiento de la interfaz que durará `segundos` (se alarga si llegan más).
    func movimiento(_ segundos: Double) {
        let fin = Date().addingTimeInterval(segundos)
        guard fin > finDelMovimiento else { return }
        finDelMovimiento = fin
        if !enMovimiento { enMovimiento = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + segundos + 0.02) {
            if Date() >= self.finDelMovimiento { self.enMovimiento = false }
        }
    }
}
