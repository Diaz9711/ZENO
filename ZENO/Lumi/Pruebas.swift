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

    /// `-sinMascara YES`: los bordes fundidos no se aplican (para medir cuánto cuestan).
    static var sinMascara: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "sinMascara")
        #else
        false
        #endif
    }

    /// `-sinCielo YES`: sin nebulosa ni Lumi (para saber si lo caro es el cielo o la página).
    static var sinCielo: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "sinCielo")
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

#if DEBUG
/// Para elegir el widget de inicio (`-galeriaWidget YES`, solo DEBUG): los tres diseños,
/// mediano y pequeño, con el retrato real de Lumi que verá el widget.
struct GaleriaDeWidgets: View {
    let apariencia: AparienciaLumi
    let forma: FormaDeLumi
    @State private var ancho: UIImage?
    @State private var cuadrado: UIImage?

    private var foto: FotoDeZeno {
        var f = FotoDeZeno()
        f.tarea = Idioma.texto("Ordenar el escritorio")
        return f
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(EstiloDeWidget.allCases) { estilo in
                    HStack(alignment: .top, spacing: 8) {
                        Text(verbatim: "\(estilo.rawValue + 1)")
                            .font(.zenoTitulo(.title2)).foregroundStyle(Lujo.oro).frame(width: 18)
                        HStack(alignment: .top, spacing: 10) {
                            VistaDeWidget(foto: foto, mediano: true, estilo: estilo, retrato: ancho, retratoCuadrado: cuadrado)
                                .frame(width: 338, height: 158)
                                .background(Tinta.cielo)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .scaleEffect(0.62, anchor: .topLeading)
                                .frame(width: 210, height: 98, alignment: .topLeading)
                            VistaDeWidget(foto: foto, mediano: false, estilo: estilo, retrato: cuadrado, retratoCuadrado: cuadrado)
                                .frame(width: 158, height: 158)
                                .background(Tinta.cielo)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .scaleEffect(0.62, anchor: .topLeading)
                                .frame(width: 98, height: 98, alignment: .topLeading)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [Color(red: 0.16, green: 0.17, blue: 0.30), Color(red: 0.06, green: 0.06, blue: 0.12)],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .task {
            ancho = RetratoDeLumi.imagen(apariencia: apariencia, forma: forma, energia: 0.7, ancho: true)
            cuadrado = RetratoDeLumi.imagen(apariencia: apariencia, forma: forma, energia: 0.7, ancho: false)
        }
    }
}
#endif
