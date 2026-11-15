#if DEBUG
import UIKit

/// Solo para medir (`-medirFluidez YES`): cuenta cada 5 segundos los cuadros dibujados y los
/// "tirones" (cuadros que llegaron tarde, más de 1,5 veces el tiempo esperado). Escribe en la consola.
final class MedidorDeTirones: NSObject {
    static let compartido = MedidorDeTirones()
    private var enlace: CADisplayLink?
    private var anterior: CFTimeInterval = 0
    private var cuadros = 0
    private var tirones = 0
    private var peor: CFTimeInterval = 0
    private var desde: CFTimeInterval = 0

    func empezar() {
        guard enlace == nil else { return }
        let e = CADisplayLink(target: self, selector: #selector(cuadro(_:)))
        e.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        e.add(to: .main, forMode: .common)
        enlace = e
    }

    @objc private func cuadro(_ e: CADisplayLink) {
        let ahora = e.timestamp
        let esperado = e.targetTimestamp - e.timestamp
        if anterior > 0 {
            let delta = ahora - anterior
            cuadros += 1
            if delta > esperado * 1.5 { tirones += 1 }
            peor = max(peor, delta)
        } else {
            desde = ahora
        }
        anterior = ahora
        if ahora - desde >= 5 {
            let fps = Double(cuadros) / (ahora - desde)
            let linea = String(format: "[fluidez] %.0f cuadros/s · %d tirones en 5 s · peor cuadro %.0f ms\n", fps, tirones, peor * 1000)
            FileHandle.standardError.write(Data(linea.utf8))   // sin búfer: llega al instante a la consola
            cuadros = 0; tirones = 0; peor = 0; desde = ahora
        }
    }
}
#endif
