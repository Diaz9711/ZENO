import SwiftUI

// MARK: - Transiciones propias

/// Lo que entra se enfoca: llega desde un desenfoque, un poco más pequeño y más abajo.
/// Lo que sale se desenfoca igual. Nunca un corte.
private struct Desenfoque: ViewModifier {
    let activo: Bool
    func body(content: Content) -> some View {
        content
            .blur(radius: activo ? 16 : 0)
            .opacity(activo ? 0 : 1)
            .scaleEffect(activo ? 0.955 : 1)
            .offset(y: activo ? 18 : 0)
    }
}

extension AnyTransition {
    static var desenfoque: AnyTransition {
        .modifier(active: Desenfoque(activo: true), identity: Desenfoque(activo: false))
    }
}

/// Cambio de página con dirección: la página nueva llega desde el lado hacia donde se avanza
/// y la anterior se va por el lado contrario. Así se siente que las páginas están una junto a otra.
private struct PasoLateral: ViewModifier {
    let lado: CGFloat      // -1 izquierda, 1 derecha, 0 en su sitio
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    func body(content: Content) -> some View {
        let fuera = lado != 0
        content
            .blur(radius: fuera && !reducirMovimiento ? 14 : 0)
            .opacity(fuera ? 0 : 1)
            .scaleEffect(fuera && !reducirMovimiento ? 0.93 : 1)
            .offset(x: reducirMovimiento ? 0 : lado * 84)
    }
}

extension AnyTransition {
    /// `sentido` 1 = se avanza hacia la derecha de la barra; -1 = se vuelve.
    static func pasoDePagina(sentido: CGFloat) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(active: PasoLateral(lado: sentido), identity: PasoLateral(lado: 0)),
            removal: .modifier(active: PasoLateral(lado: -sentido), identity: PasoLateral(lado: 0)))
    }
}

/// Entrada escalonada: cada pieza de la pantalla llega un instante después de la anterior.
private struct Aparece: ViewModifier {
    let orden: Int
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    func body(content: Content) -> some View {
        content
            .blur(radius: visible || reducirMovimiento ? 0 : 12)
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reducirMovimiento ? 0 : 30)
            .onAppear {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.82).delay(0.12 + 0.11 * Double(orden))) {
                    visible = true
                }
            }
    }
}

extension View {
    func aparece(_ orden: Int) -> some View { modifier(Aparece(orden: orden)) }
}

// MARK: - Glifos: los íconos de ZENO, dibujados a mano

enum Glifo { case hoy, tareas, ajustes, mas }

/// Trazos finos y redondeados, con el mismo grosor y un punto de luz: una sola familia.
struct GlifoView: View {
    let glifo: Glifo
    var color: Color = .marfil
    var acento: Color = .oroZeno
    var tamano: CGFloat = 24

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let trazo = StrokeStyle(lineWidth: s * 0.068, lineCap: .round, lineJoin: .round)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + (x - 0.5) * s, y: c.y + (y - 0.5) * s) }

            switch glifo {
            case .hoy:
                // Un destello de cuatro puntas con lados curvos: Lumi en pequeño.
                var estrella = Path()
                let puntas = [p(0.5, 0.08), p(0.92, 0.5), p(0.5, 0.92), p(0.08, 0.5)]
                estrella.move(to: puntas[0])
                for i in 1...4 {
                    estrella.addQuadCurve(to: puntas[i % 4], control: p(0.5, 0.5).applying(.identity)
                        .desplazado(hacia: puntos(medio: puntas[i - 1], puntas[i % 4]), factor: 0.16))
                }
                estrella.closeSubpath()
                ctx.fill(estrella, with: .color(acento.opacity(0.22)))
                ctx.stroke(estrella, with: .color(color), style: trazo)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.07, y: c.y - s * 0.07, width: s * 0.14, height: s * 0.14)),
                         with: .color(acento))

            case .tareas:
                // Tres líneas; la primera ya tiene su círculo encendido.
                for (i, y) in [0.26, 0.5, 0.74].enumerated() {
                    var linea = Path()
                    linea.move(to: p(0.38, y))
                    linea.addLine(to: p(i == 2 ? 0.74 : 0.9, y))
                    ctx.stroke(linea, with: .color(color), style: trazo)
                    let r = s * 0.075
                    let punto = Path(ellipseIn: CGRect(x: p(0.16, y).x - r, y: p(0.16, y).y - r, width: r * 2, height: r * 2))
                    if i == 0 {
                        ctx.fill(punto, with: .color(acento))
                    } else {
                        ctx.stroke(punto, with: .color(color.opacity(0.85)), lineWidth: s * 0.055)
                    }
                }

            case .ajustes:
                // Una órbita ladeada con su estrella y una luna.
                var orbita = Path(ellipseIn: CGRect(x: -s * 0.44, y: -s * 0.19, width: s * 0.88, height: s * 0.38))
                orbita = orbita.applying(CGAffineTransform(rotationAngle: -.pi / 7))
                    .applying(CGAffineTransform(translationX: c.x, y: c.y))
                ctx.stroke(orbita, with: .color(color), style: trazo)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.13, y: c.y - s * 0.13, width: s * 0.26, height: s * 0.26)),
                         with: .color(acento))
                let luna = p(0.86, 0.27)
                ctx.fill(Path(ellipseIn: CGRect(x: luna.x - s * 0.06, y: luna.y - s * 0.06, width: s * 0.12, height: s * 0.12)),
                         with: .color(color))

            case .mas:
                var cruz = Path()
                cruz.move(to: p(0.5, 0.2)); cruz.addLine(to: p(0.5, 0.8))
                cruz.move(to: p(0.2, 0.5)); cruz.addLine(to: p(0.8, 0.5))
                ctx.stroke(cruz, with: .color(color), style: StrokeStyle(lineWidth: s * 0.085, lineCap: .round))
            }
        }
        .frame(width: tamano, height: tamano)
    }

    private func puntos(medio a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

private extension CGPoint {
    /// Un punto entre el centro (self) y `destino`.
    func desplazado(hacia destino: CGPoint, factor: CGFloat) -> CGPoint {
        CGPoint(x: x + (destino.x - x) * factor, y: y + (destino.y - y) * factor)
    }
}

// MARK: - Barra inferior

enum Pagina: Int, Hashable { case hoy, tareas, ajustes }

/// La barra de ZENO: cristal flotante, la página activa encendida en oro y un "+" siempre a mano.
struct BarraZeno: View {
    @Binding var pagina: Pagina
    var alAgregar: () -> Void
    @Namespace private var espacio

    var body: some View {
        HStack(spacing: 6) {
            pestana(.hoy, "Hoy", .hoy)
            pestana(.tareas, "Tareas", .tareas)
            pestana(.ajustes, "Ajustes", .ajustes)

            Button(action: alAgregar) {
                GlifoView(glifo: .mas, color: Color(red: 0.10, green: 0.09, blue: 0.16), tamano: 20)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(LinearGradient(colors: [.oroClaro, .oroZeno, .oroHondo],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color.oroZeno.opacity(0.55), radius: 12)
                    }
            }
            .buttonStyle(EstiloPresion())
            .padding(.leading, 4)
            .accessibilityLabel(Text("Agregar tarea"))
        }
        .padding(7)
        .cristal(radio: 40)
        // Fondo más sólido: lo que pasa por debajo al desplazar no ensucia la barra.
        .background(Color("FondoArranque").opacity(0.86), in: Capsule())
        .shadow(color: .black.opacity(0.35), radius: 22, y: 10)
        .sensoryFeedback(.selection, trigger: pagina)
    }

    private func pestana(_ destino: Pagina, _ titulo: LocalizedStringKey, _ glifo: Glifo) -> some View {
        let activa = pagina == destino
        return Button {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.74)) { pagina = destino }
        } label: {
            HStack(spacing: 7) {
                GlifoView(glifo: glifo, tamano: 22)
                if activa {
                    Text(titulo)
                        .font(.zenoTexto(.subheadline, .semibold))
                        .foregroundStyle(Color.marfil)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: .leading)))
                }
            }
            .padding(.horizontal, activa ? 16 : 13)
            .frame(height: 48)
            .background {
                if activa {
                    Capsule()
                        .fill(LinearGradient(colors: [Color.oroZeno.opacity(0.34), Color.oroZeno.opacity(0.12)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(Capsule().strokeBorder(Color.oroZeno.opacity(0.75), lineWidth: 1))
                        .shadow(color: Color.oroZeno.opacity(0.35), radius: 10)
                        .matchedGeometryEffect(id: "activa", in: espacio)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(EstiloPresion())
        .accessibilityAddTraits(activa ? .isSelected : [])
    }
}

// MARK: - Encabezado y tarjeta de hoy

/// Arriba de la pantalla: el saludo según la hora y la energía en palabras (nunca en números).
struct EncabezadoDeHoy: View {
    let nombre: String
    let puntaje: Double

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(saludo)
                    .textCase(.uppercase)
                    .font(.zenoTexto(.caption2, .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Color.oroZeno)
                Text(nombre)
                    .font(.zenoTitulo(.title2, .regular, cursiva: true))
                    .luminoso()
            }
            Spacer()
            HStack(spacing: 9) {
                // Cinco barritas que se encienden con la energía.
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(Double(i) < (puntaje / 20).rounded(.up) ? Color.oroZeno : Color.marfil.opacity(0.22))
                            .frame(width: 3.5, height: 7 + CGFloat(i) * 2.6)
                    }
                }
                Text(nivel)
                    .font(.zenoTexto(.footnote, .semibold))
                    .foregroundStyle(Color.marfil)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .cristal()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(nivel))
        }
        .shadow(color: .black.opacity(0.35), radius: 8)
    }

    private var saludo: LocalizedStringKey {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Buenos días"
        case 12..<20: "Buenas tardes"
        default: "Buenas noches"
        }
    }

    private var nivel: LocalizedStringKey {
        switch MotorDeEnergia.nivel(puntaje) {
        case .alta: "Energía alta"
        case .media: "Energía media"
        case .baja: "Energía baja"
        }
    }
}

/// Tres datos amables del día. Todos son progreso; ninguno es una deuda.
struct TarjetaDeHoy: View {
    let hechas: Int
    let minutos: Int
    let mejorHora: Int

    var body: some View {
        HStack(spacing: 0) {
            dato("\(hechas)", "Hechas hoy") { LineaDeLuz(cantidad: Double(hechas) / 4) }
            separador
            dato("\(minutos)′", "En foco") { LineaDeLuz(cantidad: Double(minutos) / 45) }
            separador
            dato("\(mejorHora):00", "Tu mejor hora") { PuntoDelDia(hora: mejorHora) }
        }
        .padding(.vertical, 14)
        .cristal(radio: 24)
        .padding(.horizontal, 22)
    }

    private var separador: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, Color.oroZeno.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
            .frame(width: 1, height: 34)
    }

    private func dato<Barra: View>(_ valor: String, _ titulo: LocalizedStringKey,
                                   @ViewBuilder barra: () -> Barra) -> some View {
        VStack(spacing: 3) {
            Text(valor)
                .font(.zenoTitulo(.title2, .regular))
                .luminoso()
                .contentTransition(.numericText())
            Text(titulo)
                .textCase(.uppercase)
                .font(.zenoTexto(.caption2, .medium))
                .tracking(1.2)
                .foregroundStyle(Color.marfil.opacity(0.62))
            barra()
                .frame(width: 58, height: 6)
                .padding(.top, 5)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Una línea de luz que solo crece y se satura: no tiene carril vacío detrás,
/// así nunca se lee como "te falta". Empieza en el centro y se abre hacia los lados.
struct LineaDeLuz: View {
    let cantidad: Double
    @State private var visible = false

    var body: some View {
        let llena = 0.25 + 0.75 * min(max(cantidad, 0), 1)
        Capsule()
            .fill(LinearGradient(colors: [Color.oroZeno.opacity(0.15), Color.oroZeno, Color.oroZeno.opacity(0.15)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 2.5)
            .scaleEffect(x: visible ? llena : 0.05)
            .shadow(color: Color.oroZeno.opacity(0.7), radius: 4)
            .frame(maxHeight: .infinity)
            .onAppear { withAnimation(.easeOut(duration: 1.2).delay(0.3)) { visible = true } }
            .animation(.easeInOut(duration: 0.8), value: cantidad)
    }
}

/// La mejor hora como un punto de luz sobre la línea del día (0 a 24 h), no como un relleno.
struct PuntoDelDia: View {
    let hora: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.marfil.opacity(0.10)).frame(height: 1)
                Circle()
                    .fill(Color.oroZeno)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.oroZeno.opacity(0.9), radius: 4)
                    .offset(x: geo.size.width * CGFloat(min(max(hora, 0), 23)) / 23 - 3)
            }
            .frame(maxHeight: .infinity)
        }
    }
}
