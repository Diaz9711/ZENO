import SwiftUI

// MARK: - Transiciones propias

/// Lo que entra se enfoca: llega desde un desenfoque, un poco más pequeño y más abajo.
/// Lo que sale se desenfoca igual. Nunca un corte.
private struct Desenfoque: ViewModifier {
    let activo: Bool
    func body(content: Content) -> some View {
        content
            // Solo transformación y opacidad (sin desenfoque animado): fluido a 60–120 cuadros.
            .opacity(activo ? 0 : 1)
            .scaleEffect(activo ? 0.97 : 1)
            .offset(y: activo ? 12 : 0)
    }
}

/// El ritmo común de ZENO: el contenido cambia rápido y suave; Lumi viaja con su propio resorte, más lento.
enum Ritmo {
    /// Páginas, secciones y contenido: lento y delicado, sin rebote. cubic-bezier(0.22, 1, 0.36, 1).
    static let contenido = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.34)
    /// Lumi y el cielo: un objeto físico, con un poco de inercia. Es el resorte original de Lumi
    /// (su comportamiento no se toca): 0,95 s y amortiguación 0,68.
    static let lumi = Animation.spring(response: 0.95, dampingFraction: 0.68)
}

/// La salida original de la presentación (intocable): desenfoque 16, escala 0,955 y 18 pt hacia abajo.
private struct DesenfoqueDePresentacion: ViewModifier {
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
    /// Solo para la presentación de ZENO: se queda exactamente como estaba.
    static var presentacion: AnyTransition {
        .modifier(active: DesenfoqueDePresentacion(activo: true), identity: DesenfoqueDePresentacion(activo: false))
    }

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
            .opacity(fuera ? 0 : 1)
            .scaleEffect(fuera && !reducirMovimiento ? 0.98 : 1)
            .offset(x: reducirMovimiento ? 0 : lado * 28)
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
            // Fundido + subida corta, escalonados. Sin desenfoque animado: con varias piezas a la vez
            // era lo que más frenaba la entrada a cada página. Con Reducir Movimiento, solo fundido.
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reducirMovimiento ? 0 : 10)
            .onAppear {
                withAnimation(Lujo.curva(0.38).delay(0.02 + 0.035 * Double(orden))) {
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

/// Trazos finos con luz propia: el metal va de casi blanco a oro, y cada glifo tiene
/// un punto encendido con su halo. Una sola familia, hecha de cosas del cielo.
struct GlifoView: View {
    let glifo: Glifo
    var color: Color = .marfil
    var acento: Color = .oroZeno
    /// La página elegida: el glifo se enciende un poco más.
    var activo: Bool = false
    var tamano: CGFloat = 24

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let trazo = StrokeStyle(lineWidth: s * 0.056, lineCap: .round, lineJoin: .round)
            let fino = StrokeStyle(lineWidth: s * 0.034, lineCap: .round, lineJoin: .round)
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + (x - 0.5) * s, y: c.y + (y - 0.5) * s) }
            // El trazo brilla arriba a la izquierda, como si Lumi lo iluminara.
            let metal = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [activo ? Color.oroClaro : color, color.opacity(activo ? 0.95 : 0.72)]),
                startPoint: p(0.1, 0.05), endPoint: p(0.9, 0.95))
            func circulo(_ centro: CGPoint, _ r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: centro.x - r, y: centro.y - r, width: r * 2, height: r * 2))
            }
            /// Un punto de luz: halo suave, cuerpo dorado y un brillo blanco diminuto.
            func luz(_ centro: CGPoint, _ r: CGFloat) {
                let halo = r * (activo ? 3.4 : 2.6)
                ctx.fill(circulo(centro, halo), with: .radialGradient(
                    Gradient(colors: [acento.opacity(activo ? 0.55 : 0.32), acento.opacity(0)]),
                    center: centro, startRadius: 0, endRadius: halo))
                ctx.fill(circulo(centro, r), with: .radialGradient(
                    Gradient(colors: [.oroClaro, acento]), center: CGPoint(x: centro.x - r * 0.3, y: centro.y - r * 0.3),
                    startRadius: 0, endRadius: r * 1.3))
            }
            /// Destello de cuatro puntas con lados curvos.
            func destello(_ centro: CGPoint, _ r: CGFloat, hundido: CGFloat = 0.20) -> Path {
                var d = Path()
                let puntas = [CGPoint(x: centro.x, y: centro.y - r), CGPoint(x: centro.x + r, y: centro.y),
                              CGPoint(x: centro.x, y: centro.y + r), CGPoint(x: centro.x - r, y: centro.y)]
                d.move(to: puntas[0])
                for i in 1...4 {
                    d.addQuadCurve(to: puntas[i % 4],
                                   control: centro.desplazado(hacia: puntos(medio: puntas[i - 1], puntas[i % 4]), factor: hundido))
                }
                d.closeSubpath()
                return d
            }

            switch glifo {
            case .hoy:
                // Lumi en pequeño: un destello grande, su corazón de luz y una chispa que lo acompaña.
                let estrella = destello(p(0.46, 0.54), s * 0.40)
                ctx.fill(estrella, with: .radialGradient(
                    Gradient(colors: [acento.opacity(activo ? 0.42 : 0.24), acento.opacity(0.04)]),
                    center: p(0.46, 0.54), startRadius: 0, endRadius: s * 0.40))
                ctx.stroke(estrella, with: metal, style: trazo)
                luz(p(0.46, 0.54), s * 0.060)
                ctx.fill(destello(p(0.86, 0.16), s * 0.115, hundido: 0.12), with: .color(activo ? .oroClaro : color.opacity(0.9)))

            case .tareas:
                // Tres líneas que se apagan hacia la derecha; la primera ya tiene su punto encendido.
                for (i, y) in [0.24, 0.5, 0.76].enumerated() {
                    var linea = Path()
                    let fin = [0.92, 0.80, 0.66][i]
                    linea.move(to: p(0.36, y))
                    linea.addLine(to: p(fin, y))
                    ctx.stroke(linea, with: .linearGradient(
                        Gradient(colors: [activo ? Color.oroClaro : color, color.opacity(0.35)]),
                        startPoint: p(0.36, y), endPoint: p(fin, y)), style: trazo)
                    if i == 0 {
                        luz(p(0.15, y), s * 0.075)
                    } else {
                        ctx.stroke(circulo(p(0.15, y), s * 0.068), with: .color(color.opacity(0.8)), style: fino)
                    }
                }

            case .ajustes:
                // Un pequeño sistema: la estrella, su órbita ladeada, una órbita lejana y una luna.
                func orbita(_ ancho: CGFloat, _ alto: CGFloat) -> Path {
                    Path(ellipseIn: CGRect(x: -s * ancho / 2, y: -s * alto / 2, width: s * ancho, height: s * alto))
                        .applying(CGAffineTransform(rotationAngle: -.pi / 7))
                        .applying(CGAffineTransform(translationX: c.x, y: c.y))
                }
                ctx.stroke(orbita(1.02, 0.56), with: .color(color.opacity(0.28)), style: fino)
                ctx.stroke(orbita(0.86, 0.36), with: metal, style: trazo)
                luz(c, s * 0.115)
                let luna = p(0.855, 0.285)
                ctx.fill(circulo(luna, s * 0.058), with: .color(activo ? .oroClaro : color))
                ctx.fill(circulo(p(0.10, 0.80), s * 0.030), with: .color(color.opacity(0.7)))

            case .mas:
                var cruz = Path()
                cruz.move(to: p(0.5, 0.18)); cruz.addLine(to: p(0.5, 0.82))
                cruz.move(to: p(0.18, 0.5)); cruz.addLine(to: p(0.82, 0.5))
                ctx.stroke(cruz, with: .color(color), style: StrokeStyle(lineWidth: s * 0.078, lineCap: .round))
            }
        }
        .frame(width: tamano, height: tamano)
        .shadow(color: acento.opacity(activo ? 0.55 : 0), radius: 6)
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
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    /// La entrada: la píldora nace pequeña y se estira; los iconos llegan después.
    @State private var estirada = false
    @State private var iconos = false

    var body: some View {
        HStack(spacing: 6) {
            pestana(.hoy, "Hoy", .hoy)
            pestana(.tareas, "Tareas", .tareas)
            pestana(.ajustes, "Ajustes", .ajustes)

            BotonMasLujo(accion: alAgregar)
                .padding(.leading, 4)
                .accessibilityLabel(Text("Agregar tarea"))
        }
        .opacity(iconos ? 1 : 0)
        .padding(7)
        .background {
            // Píldora oscura flotante: cristal casi opaco con canto pulido y sombra larga y suave.
            Capsule()
                .fill(Color(red: 0.06, green: 0.065, blue: 0.11).opacity(0.9))
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [Lujo.marfil.opacity(0.2), Lujo.marfil.opacity(0.03)],
                                                               startPoint: .top, endPoint: .bottom), lineWidth: 0.75))
                .shadow(color: .black.opacity(0.4), radius: 28, y: 14)
                .scaleEffect(x: estirada ? 1 : 0.35, y: estirada ? 1 : 0.8)
                .opacity(estirada ? 1 : 0)
        }
        .sensoryFeedback(.selection, trigger: pagina)
        .onAppear {
            if reducirMovimiento {
                withAnimation(.easeInOut(duration: 0.4)) { estirada = true; iconos = true }
                return
            }
            // Llega la última de la cascada.
            withAnimation(Lujo.curva(0.6).delay(0.35)) { estirada = true }
            withAnimation(Lujo.curva(0.5).delay(0.6)) { iconos = true }
        }
    }

    private func pestana(_ destino: Pagina, _ titulo: LocalizedStringKey, _ glifo: Glifo) -> some View {
        let activa = pagina == destino
        return Button {
            // La animación la pone `ir(a:)` en UniversoView: una sola, no dos encimadas.
            pagina = destino
        } label: {
            HStack(spacing: 7) {
                GlifoView(glifo: glifo, color: Lujo.marfil, acento: Lujo.oro, activo: activa, tamano: 22)
                if activa {
                    Text(titulo)
                        .font(.lujoEtiqueta(.caption, .medium))
                        .versalitas(1.4)
                        .foregroundStyle(Lujo.oro)
                        .fixedSize()
                        .transition(.opacity.combined(with: .offset(x: -6)))
                }
            }
            .padding(.horizontal, activa ? 16 : 13)
            .frame(height: 48)
            .background {
                if activa {
                    // El mismo oro fino que los chips elegidos; se desliza de una pestaña a otra.
                    Capsule()
                        .fill(Lujo.oro.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Lujo.oro.opacity(0.8), lineWidth: 0.75))
                        .matchedGeometryEffect(id: "activa", in: espacio)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(EstiloLujo())
        .accessibilityAddTraits(activa ? .isSelected : [])
    }
}

// MARK: - Encabezado y tarjeta de hoy

/// Arriba de la pantalla: el saludo según la hora y el nombre.
/// La energía no se escribe: Lumi y el cielo la muestran con su luz (decisión de Diaz).
struct EncabezadoDeHoy: View {
    let nombre: String
    let puntaje: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                EtiquetaLujo(saludo)
                Text(nombre)
                    .font(.zenoTitulo(.title, .regular, cursiva: true))
                    .foregroundStyle(Lujo.marfil)
                    .lineSpacing(4)
            }
            Spacer()
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
        .tarjetaLujo(radio: 24)
        .padding(.horizontal, 22)
    }

    private var separador: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, Lujo.oro.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
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
            .fill(LinearGradient(colors: [Lujo.oro.opacity(0.15), Lujo.oro, Lujo.oro.opacity(0.15)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 2.5)
            .scaleEffect(x: visible ? llena : 0.05)
            .shadow(color: Lujo.oro.opacity(0.7), radius: 4)
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
                    .fill(Lujo.oro)
                    .frame(width: 6, height: 6)
                    .shadow(color: Lujo.oro.opacity(0.9), radius: 4)
                    .offset(x: geo.size.width * CGFloat(min(max(hora, 0), 23)) / 23 - 3)
            }
            .frame(maxHeight: .infinity)
        }
    }
}
