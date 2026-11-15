import SwiftUI
import UIKit

/// Saca una foto de la Lumi y la nebulosa reales de la persona (el mismo shader de la app,
/// sin tocarlo) para que el widget las muestre con toda su calidad. Se rehace solo cuando
/// cambia la persona, la forma o la energía.
@MainActor
enum RetratoDeLumi {
    private static var ultimaFirma: String?

    static func guardar(apariencia: AparienciaLumi, forma: FormaDeLumi, energia: Double, firma: String) -> Bool {
        guard firma != ultimaFirma else { return false }
        ultimaFirma = firma
        var listo = false
        for ancho in [true, false] {
            guard let url = RetratoGuardado.url(ancho: ancho),
                  let imagen = imagen(apariencia: apariencia, forma: forma, energia: energia, ancho: ancho),
                  let datos = imagen.pngData() else { continue }
            listo = ((try? datos.write(to: url, options: .atomic)) != nil) || listo
        }
        return listo
    }

    /// Al borrar los datos o cerrar sesión: la foto de Lumi también se va.
    static func olvidar() {
        ultimaFirma = nil
        for ancho in [true, false] {
            if let url = RetratoGuardado.url(ancho: ancho) { try? FileManager.default.removeItem(at: url) }
        }
    }

    /// Ancho: Lumi a la izquierda (widget mediano). Cuadrado: Lumi arriba (widget pequeño).
    static func imagen(apariencia: AparienciaLumi, forma: FormaDeLumi, energia: Double, ancho: Bool) -> UIImage? {
        let tamano = ancho ? CGSize(width: 364, height: 170) : CGSize(width: 170, height: 170)
        let centro = ancho ? UnitPoint(x: 0.24, y: 0.5) : UnitPoint(x: 0.5, y: 0.40)
        let lado = ancho ? 176.0 : 150.0
        let vista = ZStack {
            NebulosaView(apariencia: apariencia, energia: energia, calidez: 0.25, centro: centro)
            LumiView(apariencia: apariencia, energia: energia, forma: forma)
                .frame(width: lado, height: lado)
                .position(x: tamano.width * centro.x, y: tamano.height * centro.y)
        }
        .frame(width: tamano.width, height: tamano.height)
        let renderer = ImageRenderer(content: vista)
        renderer.scale = 3
        return renderer.uiImage
    }
}
