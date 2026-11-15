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

struct LogoOrbita: View {
    var diseno: DisenoDeLogo = .rodea
    var tamano: CGFloat = 220

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
        HStack(spacing: tamano * 0.03) {
            Text(verbatim: "ZEN")
                .font(.zenoMarca(tamano * 0.30))
                .tracking(tamano * 0.05)
                .foregroundStyle(metal)
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
/// Para elegir (`-galeriaLogos YES`).
struct GaleriaDeLogos: View {
    var body: some View {
        VStack(spacing: 22) {
            ForEach(DisenoDeLogo.allCases) { d in
                HStack(spacing: 18) {
                    Text(verbatim: "\(d.rawValue + 1)")
                        .font(.zenoTitulo(.title2))
                        .foregroundStyle(Lujo.oro)
                        .frame(width: 26)
                    LogoOrbita(diseno: d, tamano: 200)
                        .frame(height: 170)
                        .clipped()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .tarjetaLujo()
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35))
    }
}
#endif
