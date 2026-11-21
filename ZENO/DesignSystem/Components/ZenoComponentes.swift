import SwiftUI

// MARK: - Componentes ZENO (21 nov 2026), con la misma calidad que `ZenoPrimaryButton`:
// degradado, brillo superior, borde de luz, resplandor, presión física y háptico.
// Oro champán de `Lujo` (nunca naranja), letra Manrope, iconos `IconoFino`, textos traducibles.
// Aún no se usan en la app: primero Diaz los aprueba en la galería (Ajustes → Modo de prueba → Componentes).

/// El vidrio de ZENO: oscuro, con luz arriba y un borde que se apaga hacia abajo. Lo comparten todos.
private struct VidrioZeno<Forma: InsettableShape>: View {
    let forma: Forma
    var presionado = false
    /// Borde de luz dorado (en vez de marfil) y resplandor: para lo seleccionado o lo importante.
    var oro = false

    var body: some View {
        ZStack {
            // 1. Cuerpo: vidrio oscuro con algo de luz arriba.
            forma.fill(LinearGradient(colors: [Lujo.marfil.opacity(presionado ? 0.10 : 0.075), Lujo.marfil.opacity(0.02)],
                                      startPoint: .top, endPoint: .bottom))
            forma.fill(Color.black.opacity(0.18))
            // 2. Brillo superior: un reflejo muy suave en la mitad de arriba.
            forma.inset(by: 1.5)
                .fill(LinearGradient(colors: [.white.opacity(presionado ? 0.04 : 0.09), .clear], startPoint: .top, endPoint: .center))
                .blendMode(.plusLighter)
            // 3. Borde de luz: fino arriba, desaparece abajo.
            forma.strokeBorder(LinearGradient(colors: oro ? [Lujo.oroLuz.opacity(0.95), Lujo.oro.opacity(0.15)]
                                                          : [.white.opacity(0.32), .white.opacity(0.03)],
                                              startPoint: .top, endPoint: .bottom), lineWidth: 1)
            // 4. Sombra interior inferior: volumen.
            forma.strokeBorder(Color.black.opacity(0.35), lineWidth: 1)
                .blur(radius: 1.5).offset(y: 1.5).mask(forma)
        }
        // 5. Resplandor: dorado si es importante; si no, una sombra profunda y suave.
        .shadow(color: oro ? Lujo.oro.opacity(presionado ? 0.18 : 0.30) : .black.opacity(0.35),
                radius: presionado ? 6 : 14, y: presionado ? 2 : 6)
    }
}

/// Presión física común: se aprieta con un resorte vivo, como el principal.
private struct PresionZeno: ButtonStyle {
    var escala: CGFloat = 0.965
    @Environment(\.isEnabled) private var activo
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.zenoPresionado, configuration.isPressed)
            .scaleEffect(configuration.isPressed ? escala : 1)
            .opacity(activo ? 1 : 0.4)
            .saturation(activo ? 1 : 0.3)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

private struct ClavePresionado: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var zenoPresionado: Bool {
        get { self[ClavePresionado.self] }
        set { self[ClavePresionado.self] = newValue }
    }
}

// MARK: - Botón secundario

/// La acción de al lado del principal: vidrio oscuro con borde de luz dorado y texto marfil.
struct ZenoSecondaryButton: View {
    let titulo: LocalizedStringKey
    var icono: IconoLujo? = nil
    var ancho: CGFloat? = nil
    var alto: CGFloat = 58
    let accion: () -> Void
    @State private var toques = 0

    init(_ titulo: LocalizedStringKey, icono: IconoLujo? = nil, ancho: CGFloat? = nil, alto: CGFloat = 58,
         accion: @escaping () -> Void) {
        self.titulo = titulo; self.icono = icono; self.ancho = ancho; self.alto = alto; self.accion = accion
    }

    var body: some View {
        Button { toques += 1; accion() } label: { Etiqueta(titulo: titulo, icono: icono, ancho: ancho, alto: alto) }
            .buttonStyle(PresionZeno())
            .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: toques)
    }

    private struct Etiqueta: View {
        let titulo: LocalizedStringKey
        let icono: IconoLujo?
        let ancho: CGFloat?
        let alto: CGFloat
        @Environment(\.zenoPresionado) private var presionado

        var body: some View {
            HStack(spacing: 10) {
                if let icono { IconoFino(icono: icono, color: Lujo.oro, tamano: 16, trazo: 1.3) }
                Text(titulo)
                    .font(.zenoTexto(.headline, .semibold))
                    .tracking(0.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Lujo.marfil.opacity(0.95))
            .padding(.horizontal, 18)
            .frame(maxWidth: ancho == nil ? .infinity : nil)
            .frame(width: ancho, height: alto)
            .background { VidrioZeno(forma: Capsule(style: .continuous), presionado: presionado, oro: true) }
            .contentShape(Capsule())
        }
    }
}

// MARK: - Botón de icono

/// Un icono fino en un círculo de vidrio. `fuerte`: relleno de oro, como el principal.
struct ZenoIconButton: View {
    let icono: IconoLujo
    var fuerte = false
    var lado: CGFloat = 52
    let etiqueta: LocalizedStringKey
    let accion: () -> Void
    @State private var toques = 0

    init(_ icono: IconoLujo, etiqueta: LocalizedStringKey, fuerte: Bool = false, lado: CGFloat = 52, accion: @escaping () -> Void) {
        self.icono = icono; self.etiqueta = etiqueta; self.fuerte = fuerte; self.lado = lado; self.accion = accion
    }

    var body: some View {
        Group {
            if fuerte {
                Button { toques += 1; accion() } label: {
                    IconoFino(icono: icono, color: Lujo.tinta.opacity(0.9), tamano: lado * 0.36, trazo: 1.6)
                        .frame(width: lado, height: lado)
                }
                .buttonStyle(ZenoPrimaryStyle())
            } else {
                Button { toques += 1; accion() } label: { Cara(icono: icono, lado: lado) }
                    .buttonStyle(PresionZeno(escala: 0.93))
            }
        }
        .accessibilityLabel(Text(etiqueta))
        .sensoryFeedback(.impact(weight: .light, intensity: 0.55), trigger: toques)
    }

    private struct Cara: View {
        let icono: IconoLujo
        let lado: CGFloat
        @Environment(\.zenoPresionado) private var presionado
        var body: some View {
            IconoFino(icono: icono, color: presionado ? Lujo.oroLuz : Lujo.oro, tamano: lado * 0.36, trazo: 1.3)
                .frame(width: lado, height: lado)
                .background { VidrioZeno(forma: Circle(), presionado: presionado) }
                .contentShape(Circle())
        }
    }
}

// MARK: - Tarjeta

/// La superficie de ZENO: vidrio oscuro con luz arriba, borde de luz y sombra profunda.
/// Con `accion`, se puede tocar (presión suave y háptico). `resplandor`: borde y halo dorados.
struct ZenoCard<Contenido: View>: View {
    var radio: CGFloat = 24
    var resplandor = false
    var accion: (() -> Void)? = nil
    @ViewBuilder let contenido: Contenido
    @State private var toques = 0

    init(radio: CGFloat = 24, resplandor: Bool = false, accion: (() -> Void)? = nil, @ViewBuilder contenido: () -> Contenido) {
        self.radio = radio; self.resplandor = resplandor; self.accion = accion; self.contenido = contenido()
    }

    var body: some View {
        if let accion {
            Button { toques += 1; accion() } label: { Cara(radio: radio, resplandor: resplandor) { contenido } }
                .buttonStyle(PresionZeno(escala: 0.985))
                .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: toques)
        } else {
            Cara(radio: radio, resplandor: resplandor) { contenido }
        }
    }

    private struct Cara<C: View>: View {
        let radio: CGFloat
        let resplandor: Bool
        @ViewBuilder let contenido: C
        @Environment(\.zenoPresionado) private var presionado
        var body: some View {
            contenido
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    VidrioZeno(forma: RoundedRectangle(cornerRadius: radio, style: .continuous), presionado: presionado, oro: resplandor)
                }
                .contentShape(RoundedRectangle(cornerRadius: radio, style: .continuous))
        }
    }
}

// MARK: - Chip

/// Una opción pequeña. Sin elegir: vidrio con borde fino. Elegida: oro champán con resplandor.
struct ZenoChip: View {
    let titulo: LocalizedStringKey
    var icono: IconoLujo? = nil
    let elegido: Bool
    let accion: () -> Void
    @State private var toques = 0

    init(_ titulo: LocalizedStringKey, icono: IconoLujo? = nil, elegido: Bool, accion: @escaping () -> Void) {
        self.titulo = titulo; self.icono = icono; self.elegido = elegido; self.accion = accion
    }

    var body: some View {
        Button { toques += 1; accion() } label: { Cara(titulo: titulo, icono: icono, elegido: elegido) }
            .buttonStyle(PresionZeno(escala: 0.94))
            .sensoryFeedback(.selection, trigger: toques)
            .accessibilityAddTraits(elegido ? .isSelected : [])
    }

    private struct Cara: View {
        let titulo: LocalizedStringKey
        let icono: IconoLujo?
        let elegido: Bool
        @Environment(\.zenoPresionado) private var presionado
        var body: some View {
            HStack(spacing: 6) {
                if let icono { IconoFino(icono: icono, color: elegido ? Lujo.tinta : Lujo.oro, tamano: 12, trazo: 1.3) }
                Text(titulo)
                    .font(.zenoTexto(.subheadline, elegido ? .semibold : .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(elegido ? Lujo.tinta.opacity(0.92) : Lujo.marfil.opacity(0.9))
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background {
                if elegido {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro, Lujo.oroHondo], startPoint: .top, endPoint: .bottom))
                        Capsule(style: .continuous).inset(by: 1.5)
                            .fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
                            .blendMode(.plusLighter)
                        Capsule(style: .continuous)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    }
                    .shadow(color: Lujo.oro.opacity(presionado ? 0.2 : 0.4), radius: presionado ? 5 : 10, y: presionado ? 2 : 4)
                } else {
                    VidrioZeno(forma: Capsule(style: .continuous), presionado: presionado)
                }
            }
            .contentShape(Capsule())
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: elegido)
        }
    }
}

// MARK: - Galería (solo en pruebas)

#if DEBUG
/// Los componentes sobre el cielo de verdad, para tocarlos y sentir la presión y el háptico.
struct GaleriaDeComponentes: View {
    var alCerrar: () -> Void
    @State private var chip = 1
    @State private var activo = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    Text("Componentes").font(.zenoTitulo(.largeTitle)).foregroundStyle(Lujo.marfil)
                    Spacer()
                    ZenoIconButton(.cerrar, etiqueta: "Cerrar", lado: 44) { alCerrar() }
                }
                seccion("Principal de vidrio (glass), el de la app") {
                    ZenoPrimaryButton("Empezar ahora") {}
                    ZenoPrimaryButton("Hecho", icono: .check) {}
                    ZenoPrimaryButton("Desactivado") {}.disabled(true)
                }
                seccion("Principal de oro, para comparar") {
                    ZenoPrimaryButton("Empezar ahora", acabado: .oro) {}
                    Text("Tu original, con la letra y el icono del sistema:")
                        .font(.zenoTexto(.caption)).foregroundStyle(Lujo.marfilSecundario)
                    ZenoPrimaryButton("Hecho", letraDelSistema: true, simboloDelSistema: "checkmark", acabado: .oro) {}
                }
                seccion("Secundario") {
                    ZenoSecondaryButton("Ahora no") {}
                    HStack(spacing: 12) {
                        ZenoSecondaryButton("Cancelar") {}
                        ZenoPrimaryButton("Guardar") {}
                    }
                    ZenoSecondaryButton("Día y hora", icono: .reloj) {}
                }
                seccion("Iconos") {
                    HStack(spacing: 16) {
                        ZenoIconButton(.microfono, etiqueta: "Dictar") {}
                        ZenoIconButton(.reloj, etiqueta: "Día y hora") {}
                        ZenoIconButton(.papelera, etiqueta: "Borrar") {}
                        ZenoIconButton(.mas, etiqueta: "Añadir", fuerte: true) {}
                    }
                }
                seccion("Tarjeta") {
                    ZenoCard {
                        VStack(alignment: .leading, spacing: 6) {
                            EtiquetaLujo("Hoy")
                            Text("Lo pequeño suma.").font(.zenoTitulo(.title3, .light)).foregroundStyle(Lujo.marfil)
                        }
                    }
                    ZenoCard(resplandor: true, accion: {}) {
                        VStack(alignment: .leading, spacing: 6) {
                            EtiquetaLujo("Se puede tocar")
                            Text("Escribir el cuento").font(.zenoTitulo(.title3, .regular)).foregroundStyle(Lujo.marfil)
                            Text("Con borde y halo dorados").font(.zenoTexto(.caption)).foregroundStyle(Lujo.marfilSecundario)
                        }
                    }
                }
                seccion("Chips") {
                    HStack(spacing: 8) {
                        ZenoChip("Pequeña", elegido: chip == 0) { chip = 0 }
                        ZenoChip("Media", elegido: chip == 1) { chip = 1 }
                        ZenoChip("Grande", elegido: chip == 2) { chip = 2 }
                    }
                    HStack(spacing: 8) {
                        ZenoChip("Mañana 17:00", icono: .reloj, elegido: activo) { activo.toggle() }
                        ZenoChip("Aviso", icono: .campana, elegido: !activo) { activo.toggle() }
                    }
                }
            }
            .padding(.horizontal, Lujo.margen)
            .padding(.top, 70)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
    }

    private func seccion<C: View>(_ titulo: String, @ViewBuilder _ contenido: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: titulo.uppercased())
                .font(.zenoTexto(.caption2, .semibold)).kerning(1.4).foregroundStyle(Lujo.oro)
            contenido()
        }
    }
}
#endif
