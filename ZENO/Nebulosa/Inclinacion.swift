import CoreMotion
import CoreGraphics

/// Cuánto está inclinado el teléfono, de -1 a 1 en cada eje.
/// El cielo lo usa para dar profundidad: lo cercano se mueve más que lo lejano.
/// No pide permiso ni guarda nada; solo se lee mientras el cielo está en pantalla.
final class Inclinacion {
    static let compartida = Inclinacion()

    private let sensor = CMMotionManager()
    private var suave = CGPoint.zero
    /// La postura en la que la persona sostiene el teléfono: desde ahí se mide.
    private var reposo: CGPoint?

    func empezar() {
        guard sensor.isDeviceMotionAvailable, !sensor.isDeviceMotionActive else { return }
        reposo = nil
        sensor.deviceMotionUpdateInterval = 1.0 / 30.0
        sensor.startDeviceMotionUpdates()
    }

    func detener() {
        sensor.stopDeviceMotionUpdates()
    }

    /// Se llama una vez por cuadro. Devuelve el valor ya suavizado.
    func leer() -> CGPoint {
        guard let postura = sensor.deviceMotion?.attitude else { return suave }
        let ahora = CGPoint(x: postura.roll, y: postura.pitch)
        var base = reposo ?? ahora
        // La postura de reposo sigue muy despacio a la mano: el cielo siempre vuelve al centro.
        base.x += (ahora.x - base.x) * 0.01
        base.y += (ahora.y - base.y) * 0.01
        reposo = base
        let limite = 0.45   // radianes: unos 25 grados
        let meta = CGPoint(x: max(-1, min(1, (ahora.x - base.x) / limite)),
                           y: max(-1, min(1, (ahora.y - base.y) / limite)))
        suave.x += (meta.x - suave.x) * 0.12
        suave.y += (meta.y - suave.y) * 0.12
        return suave
    }
}
