import SwiftUI

// MARK: - ZENO Primary Button
// El estándar de calidad visual de ZENO (archivo de Diaz, 21 nov 2026), con el oro champán de la marca.
// Botón principal con profundidad real: degradado, brillo superior, borde de luz, resplandor dorado,
// presión física y háptico.
// Adaptado a las reglas de ZENO: oro de `Lujo` (nunca naranja), letra Manrope (nada de letras de sistema),
// iconos finos propios (`IconoFino`) y textos traducibles (`LocalizedStringKey`).
// Uso:
//   ZenoPrimaryButton("Empezar") { ... }
//   ZenoPrimaryButton("Hecho", icono: .check) { ... }

/// El acabado del botón principal. Diaz pidió vidrio ("glass", 21 nov 2026); el oro queda para comparar.
enum AcabadoZeno { case vidrio, oro }

struct ZenoPrimaryButton: View {
    /// El acabado de todos los botones principales de la app.
    static let acabado: AcabadoZeno = .vidrio

    let titulo: LocalizedStringKey
    /// nil = el de la app (`acabado`).
    var acabadoPropio: AcabadoZeno? = nil
    var icono: IconoLujo? = nil
    /// Ancho fijo (nil = todo el ancho disponible).
    var ancho: CGFloat? = nil
    /// 58 pt el estándar; 48 en filas junto a otros controles de 48.
    var alto: CGFloat = 58
    /// Solo para comparar en la galería: la letra y el icono del sistema del archivo original.
    var letraDelSistema = false
    var simboloDelSistema: String? = nil
    let accion: () -> Void

    @Environment(\.isEnabled) private var activo
    @State private var toques = 0

    init(_ titulo: LocalizedStringKey, icono: IconoLujo? = nil, ancho: CGFloat? = nil, alto: CGFloat = 58,
         letraDelSistema: Bool = false, simboloDelSistema: String? = nil, acabado: AcabadoZeno? = nil,
         accion: @escaping () -> Void) {
        self.titulo = titulo
        self.acabadoPropio = acabado
        self.icono = icono
        self.ancho = ancho
        self.alto = alto
        self.letraDelSistema = letraDelSistema
        self.simboloDelSistema = simboloDelSistema
        self.accion = accion
    }

    private var deVidrio: Bool { (acabadoPropio ?? Self.acabado) == .vidrio }

    var body: some View {
        let boton = Button {
            toques += 1
            accion()
        } label: {
            HStack(spacing: 10) {
                if let simboloDelSistema {
                    Image(systemName: simboloDelSistema).font(.system(size: 17, weight: .semibold))
                } else if let icono {
                    IconoFino(icono: icono, color: deVidrio ? Lujo.oroLuz : Lujo.tinta.opacity(0.92), tamano: 16, trazo: 1.6)
                }
                Text(titulo)
                    .font(letraDelSistema ? .system(size: 18, weight: .semibold, design: .rounded)
                                          : .zenoTexto(.headline, .semibold))
                    .tracking(0.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: ancho == nil ? .infinity : nil)
            .frame(width: ancho, height: alto)
        }
        Group {
            if deVidrio { boton.buttonStyle(ZenoGlassStyle()) } else { boton.buttonStyle(ZenoPrimaryStyle()) }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: toques)
    }
}

// MARK: - Estilo vidrio (Liquid Glass)

/// Vidrio de verdad: en iOS 26 el Liquid Glass de Apple (refracta la nebulosa de detrás y reacciona al
/// dedo), con un tinte de oro, borde de luz dorado y resplandor. Antes de iOS 26, un vidrio dibujado con
/// las mismas capas. Texto marfil. Sirve para cualquier forma (cápsula, círculo).
struct ZenoGlassStyle<Forma: InsettableShape>: ButtonStyle {
    let forma: Forma
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(Lujo.marfil)
            .background { FondoDeVidrio(forma: forma, presionado: pressed) }
            .scaleEffect(pressed ? 0.965 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .saturation(isEnabled ? 1 : 0.3)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: pressed)
            .contentShape(forma)
    }
}

extension ZenoGlassStyle where Forma == Capsule {
    init() { self.forma = Capsule(style: .continuous) }
}

/// El vidrio con tinte de oro, su borde de luz y su resplandor (lo usan los botones, el "+" y los chips).
struct FondoDeVidrio<Forma: InsettableShape>: View {
    let forma: Forma
    var presionado = false
    /// false: vidrio dibujado (sin Liquid Glass ni desenfoque del fondo). Para lo que gira en 3D (el Emblema),
    /// porque el Liquid Glass no sigue la rotación y se deforma a mitad del giro.
    var liquido = true

    var body: some View {
        cuerpo
            .overlay {
                // Borde de luz: dorado arriba, se apaga abajo.
                forma.strokeBorder(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro.opacity(0.20)],
                                                  startPoint: .top, endPoint: .bottom), lineWidth: 1)
            }
            // Resplandor dorado suave (el vidrio no lleva sombra gris).
            .shadow(color: Lujo.oro.opacity(presionado ? 0.18 : 0.36), radius: presionado ? 8 : 18, y: presionado ? 3 : 8)
    }

    @ViewBuilder
    private var cuerpo: some View {
        if !liquido {
            ZStack {
                forma.fill(LinearGradient(colors: [Color(red: 0.36, green: 0.33, blue: 0.30).opacity(0.62),
                                                   Color(red: 0.20, green: 0.19, blue: 0.20).opacity(0.58)],
                                          startPoint: .top, endPoint: .bottom))
                forma.fill(LinearGradient(colors: [Lujo.oro.opacity(presionado ? 0.30 : 0.22), Lujo.oro.opacity(0.06)],
                                          startPoint: .top, endPoint: .bottom))
                forma.inset(by: 1.5)
                    .fill(LinearGradient(colors: [.white.opacity(presionado ? 0.06 : 0.14), .clear], startPoint: .top, endPoint: .center))
                    .blendMode(.plusLighter)
            }
        } else if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.tint(Lujo.oro.opacity(presionado ? 0.42 : 0.34)).interactive(), in: forma)
        } else {
            ZStack {
                forma.fill(.ultraThinMaterial)
                forma.fill(LinearGradient(colors: [Lujo.oro.opacity(presionado ? 0.38 : 0.30), Lujo.oro.opacity(0.10)],
                                          startPoint: .top, endPoint: .bottom))
                forma.inset(by: 1.5)
                    .fill(LinearGradient(colors: [.white.opacity(presionado ? 0.08 : 0.18), .clear], startPoint: .top, endPoint: .center))
                    .blendMode(.plusLighter)
            }
            .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - Estilo

struct ZenoPrimaryStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    // Dorado de marca: los tres tonos del oro champán de ZENO (`Lujo`), luz → oro → hondo.
    private let goldTop    = Lujo.oroLuz
    private let goldMid    = Lujo.oro
    private let goldBottom = Lujo.oroHondo
    private let ink        = Lujo.tinta // texto sobre dorado

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .foregroundStyle(ink.opacity(0.92))
            .background {
                ZStack {
                    // 1. Cuerpo: degradado vertical (luz arriba, sombra abajo)
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: pressed
                                ? [goldMid, goldBottom]
                                : [goldTop, goldMid, goldBottom],
                            startPoint: .top, endPoint: .bottom))

                    // 2. Brillo superior: reflejo suave en la mitad de arriba
                    // (más tenue que en el original: el champán ya es claro y se lavaba).
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [.white.opacity(pressed ? 0.06 : 0.22), .clear],
                            startPoint: .top, endPoint: .center))
                        .padding(.horizontal, 2)
                        .padding(.top, 1.5)
                        .blendMode(.plusLighter)

                    // 3. Borde de luz: fino arriba, desaparece abajo
                    Capsule(style: .continuous)
                        .strokeBorder(LinearGradient(
                            colors: [.white.opacity(0.65), .white.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom),
                                      lineWidth: 1)

                    // 4. Sombra interior inferior: da volumen
                    Capsule(style: .continuous)
                        .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                        .blur(radius: 1.5)
                        .offset(y: 1.5)
                        .mask(Capsule(style: .continuous))
                }
            }
            // 5. Resplandor dorado (no sombra gris)
            .shadow(color: goldMid.opacity(pressed ? 0.25 : 0.45),
                    radius: pressed ? 8 : 18, y: pressed ? 3 : 8)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            // 6. Presión física
            .scaleEffect(pressed ? 0.965 : 1)
            .brightness(pressed ? -0.03 : 0)
            .opacity(isEnabled ? 1 : 0.4)
            .saturation(isEnabled ? 1 : 0.3)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: pressed)
            .contentShape(Capsule())
    }
}
