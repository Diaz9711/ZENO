import SwiftUI

/// El amigo de ZENO (idea de Diaz, 14 nov 2026): un cohete pequeño que siempre ayuda.
/// Es la voz de la app: dice una sola frase según el momento (sustituye las pistas sueltas)
/// y, al tocarlo, ofrece ayuda real. Nunca cuenta pendientes ni regaña. Dibujado a mano, sin emojis.
enum DisenoDeCohete: Int, CaseIterable, Identifiable {
    case clasico, capsula, chispa
    var id: Int { rawValue }
    static let clave = "disenoDeCohete"
}

// MARK: - Lo que dice (función pura)

enum Cohete {
    /// Su nombre lo eligió Diaz (14 nov 2026). Es un nombre propio: no se traduce.
    static let nombre = "Chispa"

    enum Momento {
        case tarea(enMarcha: Bool, primerPaso: Bool, minutosReales: Int?, enRacha: Bool)
        case descanso
        case masTarde(vuelveA: Date?)
        case nada(hechasHoy: Int)
    }

    /// Una sola frase, amable y útil. Sale del estado y de lo que el cerebro aprendió.
    static func consejo(_ momento: Momento) -> String {
        switch momento {
        case .tarea(let enMarcha, let primerPaso, let minutos, let enRacha):
            if enMarcha { return Idioma.texto("Vas bien. Cuando acabes, toca Terminé.") }
            if enRacha { return Idioma.texto("¡Qué buen ritmo! Una más si te apetece, sin prisa.") }
            if primerPaso { return Idioma.texto("Solo dos minutos. Yo te acompaño.") }
            if let minutos { return Idioma.texto("Algo así suele tomarte unos \(minutos) min. ¿Despegamos?") }
            return Idioma.texto("Cuando quieras, toca Empezar. Yo te acompaño.")
        case .descanso:
            return Idioma.texto("Tu energía está baja, y está bien. Descansar también cuenta.")
        case .masTarde(let vuelveA):
            if let vuelveA {
                return Idioma.texto("Te propongo algo otra vez a las \(vuelveA.formatted(date: .omitted, time: .shortened)).")
            }
            return Idioma.texto("Lo intentamos más tarde. Aquí sigo.")
        case .nada(let hechas):
            if hechas > 0 { return Idioma.texto("Hoy ya encendiste \(hechas) estrellas. Tu cielo las guarda.") }
            return Idioma.texto("Escribe una sola cosa y despegamos juntos.")
        }
    }
}

// MARK: - El amigo en pantalla

/// El cohete con su frase. Flota apenas (solo movimiento, nada costoso). Tocarlo pide ayuda.
struct CoheteAmigo: View {
    let frase: String
    var alTocar: () -> Void
    @AppStorage(DisenoDeCohete.clave) private var diseno = 0
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var flota = false
    @State private var toques = 0

    var body: some View {
        Button {
            toques += 1
            alTocar()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                DibujoDeCohete(diseno: DisenoDeCohete(rawValue: diseno) ?? .clasico)
                    .frame(width: 34, height: 40)
                    .offset(y: flota ? -2.5 : 2.5)
                Text(verbatim: frase)
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfil.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(Lujo.curva(), value: frase)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(minHeight: Lujo.altoMinimo)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.45), trigger: toques)
        .accessibilityLabel(Text(verbatim: frase))
        .accessibilityHint(Text("Toca para pedir ayuda"))
        .onAppear {
            guard !reducirMovimiento else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { flota = true }
        }
    }
}

/// La ayuda del cohete: como mucho tres cosas que ya existen en la app.
struct HojaDeAyuda: View {
    struct Accion: Identifiable {
        let id = UUID()
        let titulo: LocalizedStringKey
        let icono: IconoLujo
        let hacer: () -> Void
    }
    let acciones: [Accion]
    @AppStorage(DisenoDeCohete.clave) private var diseno = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                DibujoDeCohete(diseno: DisenoDeCohete(rawValue: diseno) ?? .clasico)
                    .frame(width: 40, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: Cohete.nombre.uppercased())
                        .font(.zenoTexto(.caption2, .semibold))
                        .kerning(1.6)
                        .foregroundStyle(Lujo.oro)
                    Text("¿En qué te ayudo?")
                        .font(.zenoTitulo(.title2, .regular))
                        .foregroundStyle(Lujo.marfil)
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(acciones.enumerated()), id: \.element.id) { i, accion in
                    if i > 0 { SeparadorLujo() }
                    Button {
                        Hojas.compartidas.cerrar()
                        accion.hacer()
                    } label: {
                        HStack(spacing: 14) {
                            IconoFino(icono: accion.icono, color: Lujo.oro, tamano: 18)
                            Text(accion.titulo).font(.zenoTexto(.body)).foregroundStyle(Lujo.marfil)
                            Spacer()
                        }
                        .frame(minHeight: 54)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(EstiloLujo())
                }
            }
            .padding(.horizontal, 20)
            .tarjetaLujo()
        }
    }
}

// MARK: - Chispa en otras páginas y en las celebraciones

/// Chispa, discreta, en Tareas y Ajustes: pequeña, quieta salvo un leve flote, con una pista útil.
struct ChispaDiscreta: View {
    let frase: String

    var body: some View {
        HStack(spacing: 10) {
            // Quieta a propósito: dentro de una lista con desplazamiento, una animación sin fin
            // obligaba a redibujar toda la página en cada cuadro.
            DibujoDeCohete(diseno: .clasico, llamaQuieta: true)
                .frame(width: 20, height: 24)
            Text(verbatim: frase)
                .font(.zenoTexto(.caption))
                .foregroundStyle(Lujo.marfilSecundario)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(Cohete.nombre): \(frase)"))
    }
}

/// Al terminar una tarea, Chispa sale de Lumi, da una vuelta a su alrededor y vuelve a ella.
/// Solo movimiento (posición, giro, escala y opacidad). Con Reducir Movimiento no vuela.
struct VueloDeChispa: View {
    /// Cambia con cada celebración.
    let numero: Int
    /// Radio de la vuelta alrededor de Lumi.
    let radio: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    /// Chispa solo existe mientras vuela (antes quedaba invisible y su llama seguía latiendo).
    @State private var volando = false

    struct Estado {
        var angulo: Double = -.pi / 2   // empieza arriba
        var distancia: Double = 0       // 0 = dentro de Lumi, 1 = en la órbita
        var escala: Double = 0.5
        var opacidad: Double = 0
    }

    var body: some View {
        ZStack {
            if volando && !reducirMovimiento {
                UnVuelo(radio: radio).id(numero)
            }
        }
        .onChange(of: numero) { _, _ in
            guard !reducirMovimiento else { return }
            volando = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4.2))
                volando = false
            }
        }
    }

}

/// Una sola vuelta de Chispa: arranca al aparecer y luego desaparece.
private struct UnVuelo: View {
    let radio: CGFloat
    @State private var disparo = 0
    private typealias Vuelo = VueloDeChispa.Estado

    var body: some View {
            DibujoDeCohete(diseno: .clasico)
                .frame(width: 22, height: 26)
                .keyframeAnimator(initialValue: Vuelo(), trigger: disparo) { vista, v in
                    vista
                        // La nariz mira hacia donde va (vuelta en el sentido del reloj).
                        .rotationEffect(.radians(v.angulo + .pi))
                        .scaleEffect(v.escala)
                        .offset(x: cos(v.angulo) * radio * v.distancia, y: sin(v.angulo) * radio * v.distancia)
                        .opacity(v.opacidad)
                } keyframes: { _ in
                    KeyframeTrack(\.angulo) {
                        LinearKeyframe(-.pi / 2, duration: 0.6)          // espera a que Lumi inhale
                        CubicKeyframe(-.pi / 2 + 2 * .pi, duration: 2.4)
                        CubicKeyframe(-.pi / 2 + 2.25 * .pi, duration: 0.5)
                    }
                    KeyframeTrack(\.distancia) {
                        LinearKeyframe(0, duration: 0.6)
                        SpringKeyframe(1, duration: 0.6, spring: .smooth)
                        LinearKeyframe(1, duration: 1.8)
                        CubicKeyframe(0, duration: 0.5)
                    }
                    KeyframeTrack(\.escala) {
                        LinearKeyframe(0.5, duration: 0.6)
                        CubicKeyframe(1, duration: 0.5)
                        LinearKeyframe(1, duration: 1.9)
                        CubicKeyframe(0.4, duration: 0.5)
                    }
                    KeyframeTrack(\.opacidad) {
                        LinearKeyframe(0, duration: 0.6)
                        CubicKeyframe(1, duration: 0.3)
                        LinearKeyframe(1, duration: 2.2)
                        CubicKeyframe(0, duration: 0.4)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onAppear { disparo += 1 }
    }
}


// MARK: - Los tres dibujos

/// Trazo fino en oro champán y marfil; la llama es luz pálida, nunca naranja.
struct DibujoDeCohete: View {
    let diseno: DisenoDeCohete
    /// Sin el latido de la llama (para los sitios donde Chispa está quieta).
    var llamaQuieta = false
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var llama = false

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
            let trazo = StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
            let metal = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo]), startPoint: p(0.3, 0), endPoint: p(0.7, 1))
            let cuerpo = GraphicsContext.Shading.color(Color(red: 0.10, green: 0.11, blue: 0.20).opacity(0.85))

            switch diseno {
            case .clasico:
                var c = Path()
                c.move(to: p(0.5, 0.04))
                c.addQuadCurve(to: p(0.72, 0.42), control: p(0.74, 0.16))
                c.addLine(to: p(0.68, 0.74)); c.addLine(to: p(0.32, 0.74)); c.addLine(to: p(0.28, 0.42))
                c.addQuadCurve(to: p(0.5, 0.04), control: p(0.26, 0.16))
                c.closeSubpath()
                ctx.fill(c, with: cuerpo); ctx.stroke(c, with: metal, style: trazo)
                var aletas = Path()
                aletas.move(to: p(0.30, 0.56)); aletas.addLine(to: p(0.10, 0.78)); aletas.addLine(to: p(0.31, 0.72))
                aletas.move(to: p(0.70, 0.56)); aletas.addLine(to: p(0.90, 0.78)); aletas.addLine(to: p(0.69, 0.72))
                ctx.stroke(aletas, with: metal, style: trazo)
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.40, y: h * 0.28, width: w * 0.20, height: w * 0.20)),
                           with: .color(Lujo.marfil.opacity(0.9)), lineWidth: 1)
            case .capsula:
                let c = Path(roundedRect: CGRect(x: w * 0.27, y: h * 0.08, width: w * 0.46, height: h * 0.64),
                             cornerRadius: w * 0.23)
                ctx.fill(c, with: cuerpo); ctx.stroke(c, with: metal, style: trazo)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.38, y: h * 0.22, width: w * 0.24, height: w * 0.24)),
                         with: .color(Lujo.oroLuz.opacity(0.35)))
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.38, y: h * 0.22, width: w * 0.24, height: w * 0.24)),
                           with: .color(Lujo.marfil.opacity(0.9)), lineWidth: 1)
                // Un anillo de órbita ladeado: es del cielo de ZENO.
                let anillo = Path(ellipseIn: CGRect(x: -w * 0.46, y: -h * 0.07, width: w * 0.92, height: h * 0.14))
                    .applying(CGAffineTransform(rotationAngle: -.pi / 9))
                    .applying(CGAffineTransform(translationX: w * 0.5, y: h * 0.48))
                ctx.stroke(anillo, with: .color(Lujo.oro.opacity(0.55)), lineWidth: 0.9)
            case .chispa:
                ctx.translateBy(x: w * 0.5, y: h * 0.5)
                ctx.rotate(by: .degrees(28))
                ctx.translateBy(x: -w * 0.5, y: -h * 0.5)
                var c = Path()
                c.move(to: p(0.5, 0.06))
                c.addQuadCurve(to: p(0.64, 0.66), control: p(0.70, 0.30))
                c.addLine(to: p(0.36, 0.66))
                c.addQuadCurve(to: p(0.5, 0.06), control: p(0.30, 0.30))
                ctx.fill(c, with: cuerpo); ctx.stroke(c, with: metal, style: trazo)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.28, width: w * 0.12, height: w * 0.12)),
                         with: .color(Lujo.marfil))
                // Chispas de estela.
                for (x, y, r) in [(0.46, 0.94, 0.035), (0.58, 1.02, 0.025), (0.40, 1.06, 0.02)] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * (x - r), y: h * y - w * r, width: w * r * 2, height: w * r * 2)),
                             with: .color(Lujo.oroLuz.opacity(0.8)))
                }
            }
        }
        .overlay(alignment: .bottom) {
            // La llama: luz pálida que late (solo opacidad y escala: barato).
            Ellipse()
                .fill(RadialGradient(colors: [Color.marfil, Lujo.oroLuz.opacity(0.6), .clear],
                                     center: .top, startRadius: 0, endRadius: 9))
                .frame(width: 8, height: 12)
                .scaleEffect(y: llama ? 1.15 : 0.8, anchor: .top)
                .opacity(llama ? 0.95 : 0.6)
                .offset(y: diseno == .chispa ? -6 : 2)
                .rotationEffect(.degrees(diseno == .chispa ? 28 : 0))
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reducirMovimiento, !llamaQuieta else { return }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { llama = true }
        }
    }
}

#if DEBUG
/// Para elegir: los tres cohetes en grande, con su número (`-galeriaCohetes YES`).
struct GaleriaDeCohetes: View {
    var body: some View {
        VStack(spacing: 30) {
            Text(verbatim: "Elige tu cohete").font(.zenoTitulo(.title, .regular)).foregroundStyle(Lujo.marfil)
            HStack(spacing: 28) {
                ForEach(DisenoDeCohete.allCases) { d in
                    VStack(spacing: 14) {
                        DibujoDeCohete(diseno: d).frame(width: 80, height: 96)
                        Text(verbatim: "\(d.rawValue + 1)").font(.zenoTitulo(.title2)).foregroundStyle(Lujo.oro)
                    }
                    .padding(18)
                    .tarjetaLujo()
                }
            }
            CoheteAmigo(frase: Cohete.consejo(.tarea(enMarcha: false, primerPaso: false, minutosReales: 10, enRacha: false))) {}
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35))
    }
}
#endif
