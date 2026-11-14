import SwiftUI

/// Los idiomas de ZENO. Para añadir uno nuevo:
///   1. Agregar el caso aquí (con su código: "fr", "pt"…) y su nombre en `nombre`.
///   2. En Xcode, abrir `Localizable.xcstrings`, pulsar "+" y elegir el idioma; traducir las frases.
/// Todo lo demás (detección, guardado, cambio en vivo) funciona solo.
enum Idioma: String, CaseIterable, Identifiable {
    case espanol = "es"
    case ingles = "en"

    var id: String { rawValue }

    /// El nombre de cada idioma escrito en ese mismo idioma (así se reconoce aunque no se entienda el resto).
    var nombre: String {
        switch self {
        case .espanol: "Español"
        case .ingles: "English"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }

    static let clave = "idioma"

    /// El idioma elegido. La primera vez se toma el del teléfono (si ZENO lo tiene; si no, inglés)
    /// y se guarda, para que después solo cambie cuando la persona lo decida en Ajustes.
    static var actual: Idioma {
        let ajustes = UserDefaults.standard
        if let guardado = ajustes.string(forKey: clave).flatMap(Idioma.init(rawValue:)) {
            return guardado
        }
        let detectado = deDispositivo()
        ajustes.set(detectado.rawValue, forKey: clave)
        return detectado
    }

    static func deDispositivo(_ preferidos: [String] = Locale.preferredLanguages) -> Idioma {
        for codigo in preferidos {
            let base = String(codigo.prefix(2)).lowercased()
            if let idioma = Idioma(rawValue: base) { return idioma }
        }
        return .ingles
    }

    /// Las traducciones del idioma elegido (la carpeta `xx.lproj` dentro de la app).
    /// El español es el idioma base: sus frases son las del código y no tiene carpeta propia.
    var paquete: Bundle? {
        Bundle.main.path(forResource: rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    /// Para textos que no son `Text` de SwiftUI (avisos, frases armadas en código):
    /// salen del catálogo en el idioma elegido, no en el del teléfono.
    static func texto(_ clave: String.LocalizationValue) -> String {
        let idioma = actual
        guard let paquete = idioma.paquete else {
            // Idioma base: una tabla que no existe devuelve la frase original (con sus datos ya puestos).
            return String(localized: clave, table: "Base", bundle: .main, locale: idioma.locale)
        }
        return String(localized: clave, bundle: paquete, locale: idioma.locale)
    }
}
