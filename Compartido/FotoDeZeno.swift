import Foundation

/// Una foto pequeña de ZENO para el widget de inicio: la luz de Lumi y la tarea de ahora.
/// La base de datos se queda donde siempre (dentro de la app); el widget solo lee esto,
/// guardado en el grupo compartido de la app.
struct FotoDeZeno: Codable, Equatable {
    /// Colores de Lumi (rojo, verde, azul de 0 a 1), sacados de su semilla.
    var nucleo: [Double] = [1, 0.96, 0.82]
    var corona: [Double] = [1, 0.86, 0.45]
    var halo: [Double] = [0.75, 0.62, 1]
    var fondo: [Double] = [0.05, 0.08, 0.22]
    var rayos: Int = 6
    var esfera = false
    /// Energía de 0 a 1 en el momento de la foto: cambia la luz, nunca el detalle.
    var energia: Double = 0.6
    /// La tarea que ZENO propone ahora (nil si no hay ninguna: descanso o nada pendiente).
    var tarea: String?
    /// Si está en marcha, cuándo empezó y cuándo se acaba su anillo.
    var inicio: Date?
    var fin: Date?
    var guardadaEn: Date = .now
    /// Cuándo se guardó el último retrato real de Lumi (para que el widget se redibuje).
    var retratoEn: Date?
    /// El idioma elegido dentro de ZENO ("es" o "en"): el widget habla igual que la app.
    var idioma: String = "es"

    static let grupo = "group.app.zeno.ZENO"
    private static let clave = "fotoDeZeno"

    static var almacen: UserDefaults? { UserDefaults(suiteName: grupo) }

    static func leer() -> FotoDeZeno? {
        guard let datos = almacen?.data(forKey: clave) else { return nil }
        return try? JSONDecoder().decode(FotoDeZeno.self, from: datos)
    }

    func guardar() {
        guard let datos = try? JSONEncoder().encode(self) else { return }
        Self.almacen?.set(datos, forKey: Self.clave)
    }

    static func borrar() { almacen?.removeObject(forKey: clave) }
}
