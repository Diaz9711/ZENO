import SwiftUI
import UIKit

/// Lumi en foto: el mismo shader, dibujado una sola vez en alta calidad y guardado.
/// Para las vistas previas pequeñas dentro de listas (Ajustes → Tu Lumi): dos Lumis vivas ahí
/// se redibujaban sin parar y, bajo los bordes fundidos, obligaban a redibujar toda la página
/// (Ajustes bajaba a 39–55 cuadros/s en el iPhone). La foto se ve igual y no cuesta nada.
struct LumiFija: View {
    let apariencia: AparienciaLumi
    let forma: FormaDeLumi
    var energia: Double = 0.75
    var lado: CGFloat = 124

    @State private var imagen: UIImage?
    private static var memoria: [String: UIImage] = [:]

    private var clave: String {
        "\(apariencia.colorNucleo)|\(apariencia.colorHalo)|\(apariencia.lobulos)|\(forma.rawValue)|\(energia)|\(lado)|\(CalidadVisual.nivel)"
    }

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: lado, height: lado)
                    .transition(.opacity)
            } else {
                Color.clear.frame(width: lado, height: lado)
            }
        }
        .accessibilityLabel(Text("Lumi, tu estrella"))
        .task(id: clave) {
            if let ya = Self.memoria[clave] { imagen = ya; return }
            let vista = LumiView(apariencia: apariencia, energia: energia, forma: forma)
                .frame(width: lado, height: lado)
            let renderer = ImageRenderer(content: vista)
            renderer.scale = 3
            if let hecha = renderer.uiImage {
                Self.memoria[clave] = hecha
                withAnimation(.easeOut(duration: 0.25)) { imagen = hecha }
            }
        }
    }
}
