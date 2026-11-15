import SwiftUI

/// El logo nuevo de ZENO (pedido de Diaz, 14 nov 2026): una órbita que dice ZENO.
/// Tres versiones para elegir; todas en oro champán y marfil, con trazo fino.
enum DisenoDeLogo: Int, CaseIterable, Identifiable {
    /// ZENO en el centro y una órbita ladeada que lo rodea, con su luna.
    case rodea
    /// ZENO escrito siguiendo la órbita, con el sol en el centro.
    case escrito
    /// La O de ZENO es una órbita con su luna.
    case laO
    var id: Int { rawValue }
}

/// Cómo se dibuja la O-órbita (Diaz, 14 nov 2026: la primera se veía chica y borrosa).
enum EstiloDeO: Int, CaseIterable, Identifiable {
    /// La primera versión: aro fino y órbita tenue.
    case fina
    /// 1 · Sólida: el aro tiene el mismo grosor que las letras y la órbita lo cruza por delante y por detrás.
    case solida
    /// 2 · Planeta: aro un poco más grande, órbita más ancha y una luna con brillo.
    case planeta
    var id: Int { rawValue }
}

struct LogoOrbita: View {
    var diseno: DisenoDeLogo = .rodea
    var tamano: CGFloat = 220
    var estiloO: EstiloDeO = .planeta

    private var metal: LinearGradient {
        LinearGradient(colors: [Lujo.marfil, Lujo.oroLuz, Lujo.oro], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        Group {
            switch diseno {
            case .rodea: rodea
            case .escrito: escrito
            case .laO: laO
            }
        }
        .frame(width: tamano, height: tamano)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "ZENO"))
    }

    // 1 · La órbita rodea la palabra (y pasa por detrás de ella en la parte de arriba).
    private var rodea: some View {
        ZStack {
            Orbita(inclinacion: -14, mitad: .atras)
                .stroke(Lujo.oro.opacity(0.45), lineWidth: tamano * 0.006)
                .frame(width: tamano * 0.98, height: tamano * 0.34)
            Text(verbatim: "ZENO")
                .font(.zenoMarca(tamano * 0.30))
                .tracking(tamano * 0.06)
                .padding(.leading, tamano * 0.06)
                .foregroundStyle(metal)
            Orbita(inclinacion: -14, mitad: .delante)
                .stroke(Lujo.oro.opacity(0.85), lineWidth: tamano * 0.007)
                .frame(width: tamano * 0.98, height: tamano * 0.34)
            Luna(tamano: tamano * 0.035)
                .offset(x: tamano * 0.43, y: -tamano * 0.13)
        }
    }

    // 2 · ZENO escrito sobre el círculo de la órbita, con el sol en el centro.
    private var escrito: some View {
        ZStack {
            Circle()
                .stroke(Lujo.oro.opacity(0.5), lineWidth: tamano * 0.005)
                .frame(width: tamano * 0.62, height: tamano * 0.62)
            ForEach(Array("ZENO".enumerated()), id: \.offset) { i, letra in
                Text(verbatim: String(letra))
                    .font(.zenoMarca(tamano * 0.15))
                    .foregroundStyle(metal)
                    .offset(y: -tamano * 0.40)
                    .rotationEffect(.degrees(-36 + Double(i) * 24))
            }
            Sol(tamano: tamano * 0.16)
            Luna(tamano: tamano * 0.03)
                .offset(x: tamano * 0.22, y: tamano * 0.22)
        }
    }

    // 3 · La O es una órbita con su luna.
    private var laO: some View {
        HStack(spacing: tamano * (estiloO == .fina ? 0.03 : (estiloO == .planeta ? 0.075 : 0.045))) {
            Text(verbatim: "ZEN")
                .font(.zenoMarca(tamano * 0.30))
                .tracking(tamano * 0.05)
                .foregroundStyle(metal)
            if estiloO == .fina {
                ZStack {
                    Circle()
                        .stroke(Lujo.oro.opacity(0.9), lineWidth: tamano * 0.012)
                        .frame(width: tamano * 0.19, height: tamano * 0.19)
                    Ellipse()
                        .stroke(Lujo.oro.opacity(0.45), lineWidth: tamano * 0.005)
                        .frame(width: tamano * 0.34, height: tamano * 0.09)
                        .rotationEffect(.degrees(-18))
                    Luna(tamano: tamano * 0.03)
                        .offset(x: tamano * 0.15, y: -tamano * 0.05)
                }
                .frame(width: tamano * 0.24)
            } else {
                // La O mide lo mismo que las mayúsculas de Bebas Neue (≈ 0,70 del tamaño de letra).
                OOrbita(diametro: tamano * (estiloO == .planeta ? 0.225 : 0.21), estilo: estiloO)
                    .frame(width: tamano * 0.24, height: tamano * 0.24)
            }
        }
    }
}

/// La O de ZENO como un planeta con su órbita: nítida, del mismo metal que las letras.
/// La órbita pasa por detrás del aro arriba y por delante abajo, así se lee en 3D.
struct OOrbita: View {
    let diametro: CGFloat
    var estilo: EstiloDeO = .solida

    private var metal: LinearGradient {
        LinearGradient(colors: [Lujo.marfil, Lujo.oroLuz, Lujo.oro], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        let planeta = estilo == .planeta
        let grosorAro = diametro * (planeta ? 0.12 : 0.165)
        let grosorOrbita = diametro * (planeta ? 0.055 : 0.06)
        let ancho = diametro * (planeta ? 1.95 : 1.75)
        let alto = diametro * (planeta ? 0.50 : 0.44)
        let inclinacion = -18.0
        // La luna va sobre la parte delantera de la órbita, arriba a la derecha.
        let a = -0.32
        let x0 = ancho / 2 * cos(a), y0 = alto / 2 * sin(a)
        let r = inclinacion * .pi / 180
        let luna = CGPoint(x: x0 * cos(r) - y0 * sin(r), y: x0 * sin(r) + y0 * cos(r))
        ZStack {
            Orbita(inclinacion: inclinacion, mitad: .atras)
                .stroke(metal.opacity(0.75), style: StrokeStyle(lineWidth: grosorOrbita, lineCap: .round))
                .frame(width: ancho, height: alto)
            Circle()
                .strokeBorder(metal, lineWidth: grosorAro)
                .frame(width: diametro, height: diametro)
            Orbita(inclinacion: inclinacion, mitad: .delante)
                .stroke(metal, style: StrokeStyle(lineWidth: grosorOrbita, lineCap: .round))
                .frame(width: ancho, height: alto)
            Circle()
                .fill(RadialGradient(colors: [Lujo.marfil, Lujo.oroLuz, Lujo.oro],
                                     center: UnitPoint(x: 0.35, y: 0.35), startRadius: 0, endRadius: diametro * 0.09))
                .frame(width: diametro * (planeta ? 0.17 : 0.15), height: diametro * (planeta ? 0.17 : 0.15))
                .shadow(color: Lujo.oroLuz.opacity(planeta ? 0.7 : 0.35), radius: diametro * (planeta ? 0.08 : 0.03))
                .offset(x: luna.x, y: luna.y)
        }
    }
}

/// Media elipse, para que la órbita pase por detrás y por delante de las letras.
private struct Orbita: Shape {
    enum Mitad { case atras, delante }
    var inclinacion: Double
    var mitad: Mitad

    func path(in r: CGRect) -> Path {
        var p = Path()
        let desde: Double = mitad == .atras ? .pi : 0
        for i in 0...60 {
            let a = desde + .pi * Double(i) / 60
            let punto = CGPoint(x: r.midX + r.width / 2 * cos(a), y: r.midY + r.height / 2 * sin(a))
            if i == 0 { p.move(to: punto) } else { p.addLine(to: punto) }
        }
        return p.applying(CGAffineTransform(translationX: -r.midX, y: -r.midY)
            .concatenating(CGAffineTransform(rotationAngle: inclinacion * .pi / 180))
            .concatenating(CGAffineTransform(translationX: r.midX, y: r.midY)))
    }
}

private struct Luna: View {
    let tamano: CGFloat
    var body: some View {
        Circle()
            .fill(Lujo.oroLuz)
            .frame(width: tamano, height: tamano)
            .shadow(color: Lujo.oro.opacity(0.8), radius: tamano * 0.8)
    }
}

private struct Sol: View {
    let tamano: CGFloat
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Lujo.marfil, Lujo.oro, Lujo.oroHondo],
                                 center: UnitPoint(x: 0.38, y: 0.36), startRadius: 0, endRadius: tamano * 0.6))
            .frame(width: tamano, height: tamano)
            .shadow(color: Lujo.oro.opacity(0.6), radius: tamano * 0.4)
    }
}

#if DEBUG
/// Para elegir la O (`-galeriaLogos YES`): cada opción como ícono grande y al tamaño real de la pantalla de inicio.
struct GaleriaDeLogos: View {
    private struct Opcion: Identifiable { let id: Int; let estilo: EstiloDeO; let soloO: Bool }
    private let opciones = [Opcion(id: 0, estilo: .fina, soloO: false),
                            Opcion(id: 1, estilo: .solida, soloO: false),
                            Opcion(id: 2, estilo: .planeta, soloO: false),
                            Opcion(id: 3, estilo: .solida, soloO: true)]
    var body: some View {
        VStack(spacing: 16) {
            ForEach(opciones) { o in
                HStack(spacing: 18) {
                    Text(verbatim: o.id == 0 ? "Hoy" : "\(o.id)")
                        .font(.zenoTitulo(.title3))
                        .foregroundStyle(Lujo.oro)
                        .frame(width: 44)
                    IconoDeMuestra(estilo: o.estilo, soloO: o.soloO, lado: 150)
                    IconoDeMuestra(estilo: o.estilo, soloO: o.soloO, lado: 62)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13).ignoresSafeArea())
    }
}

/// El ícono de la app en pequeño, con la esquina redondeada de iOS.
struct IconoDeMuestra: View {
    let estilo: EstiloDeO
    var soloO = false
    let lado: CGFloat
    var body: some View {
        ZStack {
            NebulosaView(apariencia: AparienciaLumi(semilla: Semilla(nombre: "lumi", anio: 2026, mes: 1, dia: 1)),
                         energia: 0.45, calidez: 0.15, centro: .center)
            ContenidoDelIcono(estilo: estilo, soloO: soloO, lado: lado)
        }
        .frame(width: lado, height: lado)
        .clipShape(RoundedRectangle(cornerRadius: lado * 0.2237, style: .continuous))
    }
}
#endif

/// Lo que va encima de la nebulosa en el ícono: la palabra con su O, o solo la O-órbita en grande.
struct ContenidoDelIcono: View {
    let estilo: EstiloDeO
    var soloO = false
    let lado: CGFloat
    var body: some View {
        if soloO {
            OOrbita(diametro: lado * 0.40, estilo: estilo)
                .shadow(color: .black.opacity(0.45), radius: lado * 0.03)
        } else {
            LogoOrbita(diseno: .laO, tamano: lado * 0.86, estiloO: estilo)
                .shadow(color: .black.opacity(0.45), radius: lado * 0.03)
                .offset(x: -lado * 0.035)
        }
    }
}
