import Foundation
import WidgetKit

/// Mantiene al día la foto que lee el widget de inicio.
@MainActor
enum Widgets {
    private static var ultima: FotoDeZeno?

    /// La luz de Lumi (colores de su semilla, forma y energía).
    static func luz(apariencia: AparienciaLumi, forma: FormaDeLumi, energia: Double) {
        var foto = FotoDeZeno.leer() ?? FotoDeZeno()
        foto.nucleo = apariencia.colorNucleo.comoLista
        foto.corona = apariencia.colorCorona.comoLista
        foto.halo = apariencia.colorHalo.comoLista
        foto.fondo = apariencia.colorFondo.comoLista
        foto.rayos = apariencia.lobulos + 1   // igual que el shader (nR = lobulos + 1)
        foto.esfera = forma == .esfera
        // La energía se guarda en pasos, para no recargar el widget por cambios mínimos.
        foto.energia = (energia * 10).rounded() / 10
        // El retrato real de Lumi para el widget (solo si cambió algo que se vea).
        let firma = "\(foto.nucleo)|\(foto.halo)|\(foto.esfera)|\(foto.energia)"
        if RetratoDeLumi.guardar(apariencia: apariencia, forma: forma, energia: foto.energia, firma: firma) {
            foto.retratoEn = .now
        }
        guardarSiCambia(foto)
    }

    /// La tarea de ahora (o ninguna) y, si está en marcha, su anillo.
    static func tarea(_ texto: String?, inicio: Date?, minutos: Double) {
        var foto = FotoDeZeno.leer() ?? FotoDeZeno()
        foto.tarea = texto
        foto.inicio = inicio
        foto.fin = inicio.map { $0.addingTimeInterval(minutos * 60) }
        guardarSiCambia(foto)
    }

    static func tareaTerminadaFuera() {
        var foto = FotoDeZeno.leer() ?? FotoDeZeno()
        foto.tarea = nil
        foto.inicio = nil
        foto.fin = nil
        guardarSiCambia(foto)
    }

    /// Al borrar todos los datos, el widget vuelve a la luz neutra.
    static func olvidar() {
        FotoDeZeno.borrar()
        RetratoDeLumi.olvidar()
        ultima = nil
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Si la tarea del widget ya no está pendiente (terminada, borrada o editada en Tareas), se quita.
    static func revisarTarea(pendientes: Set<String>) {
        guard let foto = FotoDeZeno.leer(), let visible = foto.tarea, !pendientes.contains(visible) else { return }
        tarea(nil, inicio: nil, minutos: 0)
    }

    private static func guardarSiCambia(_ foto: FotoDeZeno) {
        var foto = foto
        foto.idioma = Idioma.actual.rawValue
        var comparable = foto
        comparable.guardadaEn = ultima?.guardadaEn ?? foto.guardadaEn
        guard comparable != ultima else { return }
        var nueva = foto
        nueva.guardadaEn = .now
        nueva.guardar()
        ultima = nueva
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private extension SIMD3 where Scalar == Float {
    var comoLista: [Double] { [Double(x), Double(y), Double(z)] }
}
