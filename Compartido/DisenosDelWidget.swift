import SwiftUI
import UIKit

/// El retrato de Lumi que la app guarda para el widget: su estrella y su nebulosa de verdad
/// (dibujadas por el shader dentro de la app), no un dibujo aproximado.
enum RetratoGuardado {
    static func url(ancho: Bool) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FotoDeZeno.grupo)?
            .appendingPathComponent(ancho ? "retrato-ancho.png" : "retrato-cuadrado.png")
    }

    static func imagen(ancho: Bool) -> UIImage? {
        guard let url = url(ancho: ancho) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

/// Los diseños del widget de inicio. Viven en `Compartido` para compararlos dentro de la app
/// (`-galeriaWidget YES`) con el mismo código que usa el widget.
enum EstiloDeWidget: Int, CaseIterable, Identifiable {
    /// 1 · Cielo: tu nebulosa y tu Lumi de fondo, a sangre; el texto a un lado, pequeño.
    case cielo
    /// 2 · Tarjeta: fondo azul hondo con canto fino de oro y Lumi en un medallón.
    case tarjeta
    /// 3 · Mínimo: el cielo muy apagado y solo la frase, centrada.
    case minimo
    var id: Int { rawValue }
}

struct VistaDeWidget: View {
    let foto: FotoDeZeno
    var mediano: Bool
    var estilo: EstiloDeWidget
    /// El retrato real de Lumi (si la app ya lo guardó), del tamaño del widget.
    var retrato: UIImage?
    /// El retrato cuadrado (Lumi centrada), para el medallón.
    var retratoCuadrado: UIImage?

    var body: some View {
        switch estilo {
        case .cielo: cielo
        case .tarjeta: tarjeta
        case .minimo: minimo
        }
    }

    // MARK: Piezas comunes

    private var etiqueta: some View {
        Versalitas(foto.inicio != nil ? "En curso" : "Ahora")
    }

    @ViewBuilder
    private var frase: some View {
        if let tarea = foto.tarea {
            // El texto es de la persona: se oculta si el iPhone está bloqueado.
            Text(verbatim: tarea)
                .font(.titulo(mediano ? 18 : 15))
                .foregroundStyle(Tinta.marfil)
                .lineLimit(mediano ? 2 : 3)
                .minimumScaleFactor(0.85)
                .privacySensitive()
        } else {
            Text("Una sola cosa, cuando quieras.")
                .font(.titulo(mediano ? 18 : 15, cursiva: true))
                .foregroundStyle(Tinta.marfil.opacity(0.92))
                .lineLimit(mediano ? 2 : 3)
                .minimumScaleFactor(0.85)
        }
    }

    @ViewBuilder
    private var tiempo: some View {
        if let inicio = foto.inicio, let fin = foto.fin, fin > .now {
            Text(timerInterval: inicio...fin, countsDown: true)
                .font(.texto(11, "Medium"))
                .monospacedDigit()
                .foregroundStyle(Tinta.marfilSecundario)
        }
    }

    /// La firma pequeña de abajo: ZENO en su letra, muy discreta.
    private var firma: some View {
        Text(verbatim: "ZENO")
            .font(.custom("BebasNeue-Regular", size: 11))
            .kerning(2.4)
            .foregroundStyle(Tinta.oro.opacity(0.55))
    }

    @ViewBuilder
    private var fondoReal: some View {
        if let retrato {
            Image(uiImage: retrato)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        } else {
            ZStack {
                CieloDelWidget(foto: foto)
                LuzDeLumi(foto: foto).padding(18)
            }
        }
    }

    // MARK: 1 · Cielo

    private var cielo: some View {
        ZStack(alignment: mediano ? .trailing : .bottomLeading) {
            fondoReal
            // Un velo suave donde va el texto, para que se lea sin tapar a Lumi.
            LinearGradient(colors: [Tinta.cielo.opacity(0), Tinta.cielo.opacity(0.78)],
                           startPoint: mediano ? .leading : .top, endPoint: mediano ? .trailing : .bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: mediano ? .trailing : .bottom)
            VStack(alignment: .leading, spacing: 5) {
                etiqueta
                frase
                tiempo
                Spacer(minLength: 0)
                firma
            }
            .frame(width: mediano ? 168 : nil, alignment: .leading)
            .frame(maxWidth: mediano ? nil : .infinity, maxHeight: mediano ? .infinity : 74, alignment: .topLeading)
            .padding(16)
        }
    }

    // MARK: 2 · Tarjeta

    private var tarjeta: some View {
        ZStack {
            LinearGradient(colors: [Tinta.cieloClaro.opacity(0.55), Tinta.cielo], startPoint: .topLeading, endPoint: .bottomTrailing)
            ContainerRelativeShape()
                .inset(by: 5)
                .strokeBorder(LinearGradient(colors: [Tinta.oro.opacity(0.45), Tinta.oro.opacity(0.08)],
                                             startPoint: .top, endPoint: .bottom), lineWidth: 0.6)
            HStack(alignment: .center, spacing: 14) {
                if mediano { medallon(78) }
                VStack(alignment: .leading, spacing: 5) {
                    if !mediano { medallon(46).padding(.bottom, 4) }
                    etiqueta
                    frase
                    tiempo
                    Spacer(minLength: 0)
                    firma
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(18)
        }
    }

    /// Lumi en un círculo, con el cielo que la rodea fundido en los bordes.
    private func medallon(_ lado: CGFloat) -> some View {
        Group {
            if let imagen = retratoCuadrado ?? retrato {
                Image(uiImage: imagen).resizable().interpolation(.high).scaledToFill()
                    .scaleEffect(1.25, anchor: UnitPoint(x: 0.5, y: 0.40))
            } else {
                fondoReal
            }
        }
            .frame(width: lado, height: lado)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Tinta.oro.opacity(0.35), lineWidth: 0.6))
    }

    // MARK: 3 · Mínimo

    private var minimo: some View {
        ZStack {
            fondoReal
            Tinta.cielo.opacity(0.62)
            VStack(spacing: 6) {
                PuntoDeLuz(tamano: 5)
                etiqueta
                frase.multilineTextAlignment(.center)
                tiempo
            }
            .padding(18)
        }
    }
}
