import SwiftUI

/// Los pasos del registro, en orden. Una sola cosa por pantalla.
enum PasoDeRegistro: Int, Comparable {
    case bienvenida, nombre, fecha, despertar, pico, apagado, nacimiento, forma

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    var siguiente: PasoDeRegistro { PasoDeRegistro(rawValue: rawValue + 1) ?? .forma }
    var anterior: PasoDeRegistro { PasoDeRegistro(rawValue: rawValue - 1) ?? .bienvenida }

    /// A partir de aquí ya existe la estrella de la persona.
    var yaNacio: Bool { self >= .nacimiento }
}

/// Lo que la persona va respondiendo antes de guardarse.
struct BorradorDeRegistro: Equatable {
    var nombre = ""
    var fecha = Calendar(identifier: .gregorian)
        .date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? .now
    var horaDespertar = 7.0
    var horaPico = 10.0
    var horaApagado = 22.0
    var forma = FormaDeLumi.estrella

    var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }

    var nacimiento: (anio: Int, mes: Int, dia: Int) {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: fecha)
        return (c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    var semilla: Semilla {
        let n = nacimiento
        return Semilla(nombre: nombreLimpio, anio: n.anio, mes: n.mes, dia: n.dia)
    }

    func comoPersona() -> Persona {
        let n = nacimiento
        let persona = Persona(nombre: nombreLimpio,
                              nacimientoAnio: n.anio, nacimientoMes: n.mes, nacimientoDia: n.dia,
                              horaDespertar: horaDespertar, horaPico: horaPico, horaApagado: horaApagado)
        persona.formaDeLumi = forma
        return persona
    }
}

/// El texto y los controles del registro. El cielo y Lumi viven detrás, en `UniversoView`,
/// para que todo sea un solo universo continuo.
struct RegistroView: View {
    @Binding var paso: PasoDeRegistro
    @Binding var borrador: BorradorDeRegistro
    /// Lumi ya terminó de aparecer.
    var lumiNacida: Bool
    var alTerminar: () -> Void

    @FocusState private var escribiendo: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if paso > .bienvenida && paso < .nacimiento {
                    Button("Atrás") { ir(a: paso.anterior) }
                        .font(.zenoTexto(.subheadline))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }
            .frame(height: 44)
            .padding(.horizontal, 24)

            contenido
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(paso)
                .transition(.desenfoque)
        }
        .foregroundStyle(Color.marfil)
        .sensoryFeedback(.selection, trigger: paso)
    }

    private func ir(a nuevo: PasoDeRegistro) {
        escribiendo = false
        withAnimation(.easeInOut(duration: 0.55)) { paso = nuevo }
    }

    @ViewBuilder
    private var contenido: some View {
        switch paso {
        case .bienvenida: BienvenidaView { ir(a: .nombre) }
        case .nombre: nombre
        case .fecha: fecha
        case .despertar:
            pregunta("¿A qué hora te despiertas?",
                     opciones: [("Antes de las 6", 5.5), ("Entre 6 y 8", 7), ("Entre 8 y 10", 9), ("Después de las 10", 11)]) {
                borrador.horaDespertar = $0
            }
        case .pico:
            pregunta("¿Cuándo te sientes más despierto?",
                     opciones: [("Por la mañana", 10), ("Al mediodía", 13), ("Por la tarde", 17), ("Por la noche", 21)]) {
                borrador.horaPico = $0
            }
        case .apagado:
            pregunta("¿Cuándo te apagas?",
                     opciones: [("Antes de las 9 de la noche", 20.5), ("Entre 9 y 11", 22), ("Entre 11 y 1", 0), ("Después de la 1", 2)]) {
                borrador.horaApagado = $0
            }
        case .nacimiento: nacimiento
        case .forma: forma
        }
    }

    // MARK: Pasos

    private var nombre: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 60)
            Text("¿Cómo te llamas?")
                .font(.zenoTitulo(.title))
                .luminoso()
            TextField("", text: $borrador.nombre, prompt: Text("Tu nombre").foregroundStyle(.white.opacity(0.35)))
                .font(.zenoTitulo(.largeTitle))
                .luminoso()
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .focused($escribiendo)
                .onSubmit { if !borrador.nombreLimpio.isEmpty { ir(a: .fecha) } }
                .padding(.horizontal, 32)
            Spacer()
            Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento.")
                .font(.zenoTexto(.caption))
                .multilineTextAlignment(.center)
                .opacity(0.5)
                .padding(.horizontal, 44)
            BotonZeno("Continuar") { ir(a: .fecha) }
                .disabled(borrador.nombreLimpio.isEmpty)
        }
        .onAppear { escribiendo = true }
    }

    private var fecha: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Text("¿Cuándo naciste?")
                .font(.zenoTitulo(.title))
                .luminoso()
            Text("De tu nombre y tu fecha nace tu estrella.")
                .font(.zenoTexto(.footnote))
                .opacity(0.65)
            DatePicker("Fecha de nacimiento", selection: $borrador.fecha, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .padding(.horizontal, 20)
            Spacer()
            BotonZeno("Continuar") { ir(a: .despertar) }
        }
    }

    private func pregunta(_ titulo: LocalizedStringKey,
                          opciones: [(LocalizedStringKey, Double)],
                          elegir: @escaping (Double) -> Void) -> some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 60)
            Text(titulo)
                .font(.zenoTitulo(.title))
                .luminoso()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 18)
            ForEach(Array(opciones.enumerated()), id: \.offset) { _, opcion in
                // Tocar una respuesta ya es avanzar: una sola acción por pantalla.
                Button {
                    elegir(opcion.1)
                    ir(a: paso.siguiente)
                } label: {
                    Text(opcion.0)
                        .font(.zenoTitulo(.title3, .regular))
                        .luminoso()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .cristal(radio: 22)
                }
                .buttonStyle(EstiloPresion())
                .padding(.horizontal, 28)
            }
            Spacer()
        }
    }

    private var nacimiento: some View {
        VStack(spacing: 10) {
            Spacer()
            if lumiNacida {
                Group {
                    Text("Ella es Lumi.")
                        .font(.zenoTitulo(.title))
                        .luminoso()
                    Text("Nació contigo, \(borrador.nombreLimpio). Nadie más tiene una igual.")
                        .font(.zenoTitulo(.body))
                        .luminoso()
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                        .padding(.horizontal, 36)
                }
                .transition(.opacity)
                Spacer().frame(height: 26)
                BotonZeno("Continuar") { ir(a: .forma) }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.4).delay(1.0), value: lumiNacida)
    }

    private var forma: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("¿Cómo quieres verla?")
                .font(.zenoTitulo(.title2))
                .luminoso()
            HStack(spacing: 12) {
                opcionDeForma("Estrella", .estrella)
                opcionDeForma("Esfera", .esfera)
            }
            .padding(.horizontal, 28)
            Text("Puedes cambiarla cuando quieras en Ajustes.")
                .font(.zenoTexto(.footnote))
                .opacity(0.6)
            BotonZeno("Esta es la mía", accion: alTerminar)
        }
    }

    private func opcionDeForma(_ titulo: LocalizedStringKey, _ valor: FormaDeLumi) -> some View {
        Button {
            borrador.forma = valor
        } label: {
            Text(titulo)
                .font(.zenoTexto(.body, .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .cristal(radio: 18, activo: borrador.forma == valor)
        }
        .buttonStyle(EstiloPresion())
        .sensoryFeedback(.selection, trigger: borrador.forma)
    }
}

/// El botón principal de ZENO: uno solo por pantalla, y es lo único hecho de luz.
/// Oro de estrella con tinta oscura y una flecha en su propio círculo: se ve que se toca.
/// Quieto mientras nadie lo toca; al tocarlo, la flecha avanza y suelta una onda de luz.
struct BotonZeno: View {
    let titulo: LocalizedStringKey
    /// 0 a 1. Con energía baja el botón brilla menos: invita, no grita.
    var intensidad: Double
    var compacto = false
    let accion: () -> Void

    init(_ titulo: LocalizedStringKey, intensidad: Double = 1, compacto: Bool = false, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.intensidad = intensidad
        self.compacto = compacto
        self.accion = accion
    }

    static let tinta = Color(red: 0.09, green: 0.08, blue: 0.15)

    var body: some View {
        Button(action: accion) {
            Text(titulo)
        }
        .buttonStyle(EstiloLuz(intensidad: intensidad, compacto: compacto))
        .padding(.bottom, compacto ? 0 : 16)
    }
}

/// El estilo del botón de luz. Vive en una vista propia para poder guardar sus ondas.
struct EstiloLuz: ButtonStyle {
    var intensidad: Double = 1
    var compacto = false
    func makeBody(configuration: Configuration) -> some View {
        CuerpoDeLuz(configuration: configuration, intensidad: intensidad, compacto: compacto)
    }
}

private struct CuerpoDeLuz: View {
    let configuration: ButtonStyleConfiguration
    let intensidad: Double
    let compacto: Bool
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Environment(\.isEnabled) private var activo
    @State private var ondas = 0

    var body: some View {
        let presionado = configuration.isPressed
        let alto: CGFloat = compacto ? 40 : 50
        HStack(spacing: compacto ? 8 : 12) {
            configuration.label
                .font(.zenoTexto(compacto ? .subheadline : .body, .bold))
                .tracking(0.4)
                .foregroundStyle(BotonZeno.tinta)
                .padding(.leading, compacto ? 26 : 38)     // la cola del cometa
            // La cabeza del cometa: el punto más brillante, con la flecha.
            ZStack {
                // La onda: un anillo de luz que sale de la cabeza, como cuando Lumi celebra.
                Circle()
                    .stroke(Color.oroClaro, lineWidth: 1.5)
                    .keyframeAnimator(initialValue: OndaDeBoton(), trigger: ondas) { vista, v in
                        vista.scaleEffect(v.escala).opacity(v.opacidad)
                    } keyframes: { _ in
                        KeyframeTrack(\.escala) {
                            CubicKeyframe(1.0, duration: 0.01)
                            CubicKeyframe(2.4, duration: 0.75)
                        }
                        KeyframeTrack(\.opacidad) {
                            CubicKeyframe(0.9, duration: 0.01)
                            CubicKeyframe(0, duration: 0.75)
                        }
                    }
                Circle()
                    .fill(RadialGradient(colors: [.white, .oroClaro, .oroZeno],
                                         center: UnitPoint(x: 0.4, y: 0.38), startRadius: 0, endRadius: alto * 0.62))
                    .shadow(color: Color.oroClaro.opacity(presionado ? 0.95 : 0.6), radius: presionado ? 16 : 10)
                FlechaDibujada()
                    .stroke(BotonZeno.tinta, style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
                    .frame(width: alto * 0.32, height: alto * 0.26)
                    .offset(x: presionado && !reducirMovimiento ? 3 : 0)
            }
            .frame(width: alto, height: alto)
        }
        .frame(height: alto)
        .background {
            let forma = FormaDeCometa()
            ZStack {
                // La cola: oro viejo en la punta que se enciende hacia la cabeza.
                forma.fill(LinearGradient(colors: [Color.oroHondo.opacity(0.85), .oroZeno, .oroClaro],
                                          startPoint: .leading, endPoint: .trailing))
                // Estelas finas a lo largo de la cola.
                forma.fill(LinearGradient(colors: [.white.opacity(presionado ? 0.42 : 0.28), .clear],
                                          startPoint: .top, endPoint: .center))
                    .padding(1.5)
                forma.stroke(LinearGradient(colors: [Color.oroClaro.opacity(0.1), Color.oroClaro.opacity(0.9)],
                                            startPoint: .leading, endPoint: .trailing), lineWidth: 0.8)
            }
            .saturation(0.75 + 0.25 * intensidad)
            .brightness(-0.10 * (1 - intensidad) + (presionado ? 0.05 : 0))
            .shadow(color: Color.oroZeno.opacity((0.16 + 0.24 * intensidad) * (presionado ? 1.6 : 1)),
                    radius: presionado ? 22 : 16, y: 3)
        }
        .scaleEffect(presionado ? 0.975 : 1)
        .opacity(activo ? 1 : 0.4)
        .animation(.spring(response: 0.3, dampingFraction: 0.62), value: presionado)
        .onChange(of: presionado) { _, ahora in
            if ahora && !reducirMovimiento { ondas += 1 }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.55), trigger: presionado) { _, ahora in ahora }
    }
}

/// La silueta del botón principal: un cometa. Cabeza redonda a la derecha
/// y una cola que se afina hacia la izquierda, con la punta apenas redondeada.
struct FormaDeCometa: Shape {
    func path(in r: CGRect) -> Path {
        let h = r.height
        let radio = h / 2
        let centro = CGPoint(x: r.maxX - radio, y: r.midY)
        let punta = h * 0.17                       // medio grosor de la cola en su extremo
        var p = Path()
        p.move(to: CGPoint(x: r.minX + punta, y: r.midY - punta))
        // Borde de arriba: la cola se ensancha suave hasta la cabeza.
        p.addCurve(to: CGPoint(x: centro.x, y: r.minY),
                   control1: CGPoint(x: r.minX + r.width * 0.42, y: r.midY - punta * 1.25),
                   control2: CGPoint(x: centro.x - r.width * 0.22, y: r.minY))
        // La cabeza.
        p.addArc(center: centro, radius: radio, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        // Borde de abajo, de vuelta a la punta.
        p.addCurve(to: CGPoint(x: r.minX + punta, y: r.midY + punta),
                   control1: CGPoint(x: centro.x - r.width * 0.22, y: r.maxY),
                   control2: CGPoint(x: r.minX + r.width * 0.42, y: r.midY + punta * 1.25))
        // La punta, redondeada.
        p.addArc(center: CGPoint(x: r.minX + punta, y: r.midY), radius: punta,
                 startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

private struct OndaDeBoton {
    var escala: CGFloat = 1
    var opacidad: Double = 0
}

// MARK: - Bienvenida

/// La entrada a ZENO: se llega desde el espacio. Primero el cielo, luego una luz que se enciende,
/// y el nombre letra por letra. Nada más: el universo habla solo. Tocar en cualquier parte lo muestra todo de una vez.
struct BienvenidaView: View {
    /// Con botón: la primera vez, antes del registro. Sin botón: cada vez que se abre, y sigue sola.
    var conBoton = true
    let alEmpezar: () -> Void
    @State private var terminada = false

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    /// 0 nada · 1 se enciende el sol · 2 llegan las letras · 4 el botón
    @State private var fase = 0
    @State private var destello = false

    private static let letras = ["Z", "E", "N", "O"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // El sol: nace como un punto, se enciende con un destello suave y deja su órbita dibujada.
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.oroClaro.opacity(0.55), Color.oroZeno.opacity(0.18), .clear],
                                         center: .center, startRadius: 0, endRadius: 120))
                    .frame(width: 240, height: 240)
                    .scaleEffect(destello ? 1.0 : 0.2)
                    .opacity(destello ? 0 : (fase >= 1 ? 1 : 0))
                OrbitaDeBienvenida(progreso: fase >= 2 ? 1 : 0)
                    .frame(width: 118, height: 54)
                SolZeno()
                    .frame(width: 30, height: 30)
                    .scaleEffect(fase >= 1 ? 1 : 0.05)
                    .opacity(fase >= 1 ? 1 : 0)
            }
            .frame(height: 80)
            .padding(.bottom, 30)

            // ZENO, letra por letra: cada una llega desenfocada y se asienta en su sitio.
            HStack(spacing: fase >= 2 ? 22 : 48) {
                ForEach(Array(Self.letras.enumerated()), id: \.offset) { i, letra in
                    Text(verbatim: letra)
                        .font(.zenoMarca(64))
                        .foregroundStyle(LinearGradient(colors: [.marfil, Color.oroZeno.opacity(0.9)],
                                                        startPoint: .top, endPoint: .bottom))
                        .blur(radius: fase >= 2 ? 0 : 10)
                        .opacity(fase >= 2 ? 1 : 0)
                        .offset(y: fase >= 2 ? 0 : 14)
                        .animation(.easeOut(duration: 1.1).delay(Double(i) * 0.16), value: fase)
                }
            }
            .shadow(color: Color.oroZeno.opacity(0.35), radius: 18)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: "ZENO"))

            Spacer()

            BotonZeno("Crear mi estrella", accion: alEmpezar)
            .opacity(conBoton && fase >= 4 ? 1 : 0)
            .offset(y: fase >= 4 ? 0 : 26)
            .allowsHitTesting(conBoton && fase >= 4)
        }
        .contentShape(Rectangle())
        .onTapGesture { mostrarTodo() }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.45), trigger: fase == 1)
        .task { await contar() }
    }

    /// La secuencia completa dura unos cinco segundos.
    private func contar() async {
        if reducirMovimiento { fase = 4; destello = true; if !conBoton { terminar() }; return }
        let pasos: [(Int, Double)] = conBoton ? [(1, 1.3), (2, 0.9), (4, 2.4)] : [(1, 1.2), (2, 1.0)]
        for (f, espera) in pasos {
            try? await Task.sleep(for: .seconds(espera))
            guard fase < f else { continue }
            withAnimation(.spring(response: 1.1, dampingFraction: 0.8)) { fase = f }
            if f == 1 { withAnimation(.easeOut(duration: 1.6)) { destello = true } }
        }
        if !conBoton {
            // ZENO se queda completo unos segundos para leerlo con calma (en total, unos 5,5 s).
            try? await Task.sleep(for: .seconds(3.3))
            terminar()
        }
    }

    /// Solo una vez: pasa a la pantalla principal.
    private func terminar() {
        guard !terminada else { return }
        terminada = true
        alEmpezar()
    }

    private func mostrarTodo() {
        if !conBoton { terminar(); return }
        guard fase < 4 else { return }
        withAnimation(.easeOut(duration: 0.6)) { fase = 4; destello = true }
    }
}

/// Una órbita ladeada que se dibuja sola alrededor del sol, con una luna pequeña al final del trazo.
struct OrbitaDeBienvenida: View, Animatable {
    var progreso: Double
    var animatableData: Double {
        get { progreso }
        set { progreso = newValue }
    }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let angulo = -Double.pi / 2 + 2 * Double.pi * progreso
            let luna = CGPoint(x: rect.midX + rect.width / 2 * cos(angulo),
                               y: rect.midY + rect.height / 2 * sin(angulo))
            ZStack {
                ElipseDesdeArriba()
                    .trim(from: 0, to: progreso)
                    .stroke(LinearGradient(colors: [Color.oroZeno.opacity(0.15), Color.oroZeno.opacity(0.75)],
                                           startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                Circle()
                    .fill(Color.oroClaro)
                    .frame(width: 5, height: 5)
                    .shadow(color: Color.oroZeno, radius: 4)
                    .position(luna)
                    .opacity(progreso > 0.02 ? 1 : 0)
            }
        }
        .rotationEffect(.degrees(-14))
        .animation(.easeInOut(duration: 2.2), value: progreso)
    }
}

/// Una elipse que empieza arriba y avanza en el sentido del reloj, como la luna de la órbita.
struct ElipseDesdeArriba: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 0...96 {
            let a = -Double.pi / 2 + 2 * Double.pi * Double(i) / 96
            let punto = CGPoint(x: r.midX + r.width / 2 * cos(a), y: r.midY + r.height / 2 * sin(a))
            if i == 0 { p.move(to: punto) } else { p.addLine(to: punto) }
        }
        return p
    }
}
