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

struct ZenoPrimaryButton: View {
    let titulo: LocalizedStringKey
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
         letraDelSistema: Bool = false, simboloDelSistema: String? = nil, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.icono = icono
        self.ancho = ancho
        self.alto = alto
        self.letraDelSistema = letraDelSistema
        self.simboloDelSistema = simboloDelSistema
        self.accion = accion
    }

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            HStack(spacing: 10) {
                if let simboloDelSistema {
                    Image(systemName: simboloDelSistema).font(.system(size: 17, weight: .semibold))
                } else if let icono {
                    IconoFino(icono: icono, color: Lujo.tinta.opacity(0.92), tamano: 16, trazo: 1.6)
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
        .buttonStyle(ZenoPrimaryStyle())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: toques)
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
