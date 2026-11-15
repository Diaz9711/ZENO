import Foundation

/// Atajos para comparar imágenes en el simulador. En la app publicada no hacen nada.
/// `-lumiQuieta YES` congela el tiempo de Lumi y del cielo; `-energiaFija 70` fija la energía.
enum Pruebas {
    static var quieto: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "lumiQuieta")
        #else
        false
        #endif
    }

    static var energia: Double? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "energiaFija").flatMap(Double.init)
        #else
        nil
        #endif
    }
}

#if DEBUG
import SwiftUI

/// Para elegir cómo se ve el anillo en la pantalla bloqueada (`-galeriaAnillo YES`, solo DEBUG).
/// Usa exactamente las mismas vistas que el widget, sobre un fondo de pantalla bloqueada.
struct GaleriaDeAnillos: View {
    private let estado = AtributosDelAnillo.ContentState(inicio: .now.addingTimeInterval(-200),
                                                         fin: .now.addingTimeInterval(400))
    var body: some View {
        VStack(spacing: 22) {
            Text(verbatim: "Pantalla bloqueada").font(.zenoTitulo(.title2, .regular)).foregroundStyle(.white)
            ForEach(EstiloDeBloqueo.allCases) { estilo in
                HStack(alignment: .center, spacing: 10) {
                    Text(verbatim: "\(estilo.rawValue + 1)")
                        .font(.zenoTitulo(.title2)).foregroundStyle(Lujo.oro).frame(width: 22)
                    VistaDeBloqueo(estado: estado, estilo: estilo)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Tinta.cielo.opacity(0.78)))
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [Color(red: 0.35, green: 0.55, blue: 0.62), Color(red: 0.16, green: 0.30, blue: 0.62),
                                            Color(red: 0.05, green: 0.12, blue: 0.20)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea())
    }
}
#endif
