import SwiftUI
import AuthenticationServices
import simd

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
    var cuentaApple: String?

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
        persona.cuentaApple = cuentaApple
        return persona
    }
}

/// El texto y los controles del registro. El cielo y Lumi viven detrás, en `UniversoView`,
/// para que todo sea un solo universo continuo.
///
/// Todos los pasos comparten la misma estructura: arriba volver y el progreso; luego el título
/// y una línea que dice para qué se pregunta; el contenido; y el botón siempre en el mismo lugar.
struct RegistroView: View {
    @Binding var paso: PasoDeRegistro
    @Binding var borrador: BorradorDeRegistro
    /// Lumi ya terminó de aparecer.
    var lumiNacida: Bool
    var alTerminar: () -> Void

    @FocusState private var escribiendo: Bool

    /// Medidas comunes: un margen, un radio, un espacio entre opciones.
    static let margen: CGFloat = 28
    static let radio: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            if muestraCabecera {
                cabecera
                    .transition(.opacity)
            }
            contenido
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(paso)
                .transition(.desenfoque)
        }
        .foregroundStyle(Color.marfil)
        .sensoryFeedback(.selection, trigger: paso)
    }

    private var muestraCabecera: Bool { paso > .bienvenida && paso != .nacimiento }

    /// Volver (un glifo dibujado, con área de toque de 44 pt) y una línea fina de progreso.
    private var cabecera: some View {
        HStack(spacing: 14) {
            Button { ir(a: paso == .forma ? .forma : paso.anterior) } label: {
                FlechaAtras()
                    .stroke(Color.marfil.opacity(0.85), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: 9, height: 16)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .opacity(paso == .forma ? 0 : 1)
            .disabled(paso == .forma)
            .accessibilityLabel(Text("Atrás"))

            ProgresoDeRegistro(actual: numeroDePaso, total: 6)
                .frame(height: 3)
                .accessibilityLabel(Text("Paso \(numeroDePaso) de 6"))

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
    }

    private var numeroDePaso: Int {
        switch paso {
        case .bienvenida: 0
        case .nombre: 1
        case .fecha: 2
        case .despertar: 3
        case .pico: 4
        case .apagado: 5
        case .nacimiento, .forma: 6
        }
    }

    private func ir(a nuevo: PasoDeRegistro) {
        escribiendo = false
        withAnimation(Ritmo.contenido) { paso = nuevo }
    }

    @ViewBuilder
    private var contenido: some View {
        switch paso {
        case .bienvenida:
            BienvenidaView(alEmpezar: { ir(a: .nombre) },
                           alEntrarConApple: { cuenta, nombreDeApple in
                               borrador.cuentaApple = cuenta
                               if let nombreDeApple, borrador.nombreLimpio.isEmpty { borrador.nombre = nombreDeApple }
                               ir(a: .nombre)
                           })
        case .nombre: nombre
        case .fecha: fecha
        case .despertar:
            pregunta("¿A qué hora sueles despertar?",
                     razon: "Con esto ZENO empieza a entender tu ritmo de energía.",
                     opciones: [("Antes de las 6", 5.5), ("Entre las 6 y las 8", 7), ("Entre las 8 y las 10", 9), ("Después de las 10", 11)]) {
                borrador.horaDespertar = $0
            }
        case .pico:
            pregunta("¿En qué momento tienes más energía?",
                     razon: "Ahí te propondrá lo que pide más de ti.",
                     opciones: [("Por la mañana", 10), ("Al mediodía", 13), ("Por la tarde", 17), ("Por la noche", 21)]) {
                borrador.horaPico = $0
            }
        case .apagado:
            pregunta("¿A qué hora se te acaba la energía?",
                     razon: "Después de esa hora, ZENO te pedirá menos.",
                     opciones: [("Antes de las 9 de la noche", 20.5), ("Entre las 9 y las 11", 22), ("Entre las 11 y la 1", 0), ("Después de la 1", 2)]) {
                borrador.horaApagado = $0
            }
        case .nacimiento: nacimiento
        case .forma: forma
        }
    }

    // MARK: Estructura común

    /// Título, razón, contenido y el botón abajo, siempre en el mismo sitio.
    private func pantalla<Contenido: View>(_ titulo: LocalizedStringKey,
                                           razon: LocalizedStringKey?,
                                           @ViewBuilder contenido: () -> Contenido,
                                           @ViewBuilder pie: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo)
                .font(.zenoTitulo(.title, .regular))
                .luminoso()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)
            if let razon {
                Text(razon)
                    .font(.zenoTexto(.callout))
                    .foregroundStyle(Color.marfil.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            contenido()
                .padding(.top, 32)
            Spacer(minLength: 16)
            pie()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, Self.margen)
    }

    // MARK: Pasos

    private var nombre: some View {
        pantalla("¿Cómo te llamas?", razon: "Así te saludará ZENO cada día.") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("", text: $borrador.nombre,
                          prompt: Text("Tu nombre").foregroundStyle(Color.marfil.opacity(0.3)))
                    .font(.zenoTitulo(.largeTitle, .regular))
                    .foregroundStyle(Color.marfil)
                    .tint(Color.oroZeno)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .focused($escribiendo)
                    .onSubmit { if !borrador.nombreLimpio.isEmpty { ir(a: .fecha) } }
                // Una línea fina que se enciende cuando hay nombre.
                Rectangle()
                    .fill(LinearGradient(colors: [Color.oroZeno.opacity(borrador.nombreLimpio.isEmpty ? 0.3 : 0.9),
                                                  Color.oroZeno.opacity(0.05)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .animation(.easeInOut(duration: 0.3), value: borrador.nombreLimpio.isEmpty)
            }
        } pie: {
            VStack(spacing: 16) {
                Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento.")
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Color.marfil.opacity(0.45))
                    .multilineTextAlignment(.center)
                BotonZeno("Continuar") { ir(a: .fecha) }
                    .disabled(borrador.nombreLimpio.isEmpty)
            }
        }
        .onAppear { escribiendo = true }
    }

    private var fecha: some View {
        pantalla("¿Cuándo naciste?", razon: "Tu estrella nace de tu nombre y tu fecha. Nadie más tiene una igual.") {
            // Ruedas propias de día, mes y año (sin la rueda del sistema).
            FechaDeNacimiento(fecha: $borrador.fecha)
                .padding(.vertical, 8)
                .tarjetaLujo()
        } pie: {
            BotonZeno("Continuar") { ir(a: .despertar) }
        }
    }

    private func pregunta(_ titulo: LocalizedStringKey,
                          razon: LocalizedStringKey,
                          opciones: [(LocalizedStringKey, Double)],
                          elegir: @escaping (Double) -> Void) -> some View {
        pantalla(titulo, razon: razon) {
            VStack(spacing: 10) {
                ForEach(Array(opciones.enumerated()), id: \.offset) { _, opcion in
                    // Tocar una respuesta ya es avanzar: una sola acción por pantalla.
                    Button {
                        elegir(opcion.1)
                        ir(a: paso.siguiente)
                    } label: {
                        FilaDeOpcion(titulo: opcion.0, elegida: false)
                    }
                    .buttonStyle(EstiloLujo(conReflejo: false))
                }
            }
        } pie: {
            Color.clear.frame(height: 50)   // el botón no hace falta: elegir ya avanza
        }
    }

    private var nacimiento: some View {
        VStack(spacing: 10) {
            Spacer()
            if lumiNacida {
                Group {
                    Text("Ella es Lumi.")
                        .font(.zenoTitulo(.title, .regular))
                        .luminoso()
                    Text("Nació contigo, \(borrador.nombreLimpio). Nadie más tiene una igual.")
                        .font(.zenoTexto(.callout))
                        .foregroundStyle(Color.marfil.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Self.margen)
                }
                .transition(.opacity)
                Spacer().frame(height: 30)
                BotonZeno("Continuar") { ir(a: .forma) }
                    .transition(.opacity)
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 1.4).delay(1.0), value: lumiNacida)
    }

    private var forma: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("¿Cómo quieres verla?")
                    .font(.zenoTitulo(.title, .regular))
                    .luminoso()
                Text("Puedes cambiarla cuando quieras en Ajustes.")
                    .font(.zenoTexto(.callout))
                    .foregroundStyle(Color.marfil.opacity(0.62))
                    .padding(.top, 10)
                VStack(spacing: 10) {
                    opcionDeForma("Estrella", .estrella)
                    opcionDeForma("Esfera", .esfera)
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, Self.margen)
            BotonZeno("Listo", accion: alTerminar)
                .padding(.top, 28)
                .padding(.bottom, 20)
        }
    }

    private func opcionDeForma(_ titulo: LocalizedStringKey, _ valor: FormaDeLumi) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { borrador.forma = valor }
        } label: {
            FilaDeOpcion(titulo: titulo, elegida: borrador.forma == valor)
        }
        .buttonStyle(EstiloLujo(conReflejo: false))
        .sensoryFeedback(.selection, trigger: borrador.forma)
    }
}

/// Una opción del registro: texto a la izquierda y un círculo a la derecha que se llena al elegir.
private struct FilaDeOpcion: View {
    let titulo: LocalizedStringKey
    let elegida: Bool

    var body: some View {
        HStack {
            Text(titulo)
                .font(.zenoTexto(.body))
                .foregroundStyle(elegida ? Lujo.oro : Lujo.marfil)
            Spacer()
            ZStack {
                Circle().strokeBorder(Lujo.oro.opacity(elegida ? 0.9 : 0.4), lineWidth: 0.9)
                if elegida { Circle().fill(Lujo.oro).padding(6) }
            }
            .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        .background(RoundedRectangle(cornerRadius: RegistroView.radio, style: .continuous).fill(Lujo.marfil.opacity(0.035)))
        .cantoPulido(radio: RegistroView.radio, oro: elegida)
        .contentShape(Rectangle())
        .accessibilityAddTraits(elegida ? .isSelected : [])
    }
}

/// El progreso del registro: una línea fina, la parte hecha en oro.
private struct ProgresoDeRegistro: View {
    let actual: Int
    let total: Int
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Lujo.marfil.opacity(0.12))
                Capsule()
                    .fill(LinearGradient(colors: [Lujo.oroLuz, Lujo.oro], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(actual) / CGFloat(max(total, 1)))
                    .animation(Lujo.curva(0.6), value: actual)
            }
        }
    }
}

/// Flecha de volver, dibujada.
struct FlechaAtras: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        return p
    }
}

/// El botón principal de ZENO: uno solo por pantalla. Una píldora de oro con la palabra,
/// del mismo tamaño que los botones de la bienvenida (280 × 50). Sin adornos: al tocarlo
/// se hunde y se enciende (`EstiloPresion`).
struct BotonZeno: View {
    let titulo: LocalizedStringKey
    var compacto = false
    let accion: () -> Void

    init(_ titulo: LocalizedStringKey, compacto: Bool = false, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.compacto = compacto
        self.accion = accion
    }

    static let tinta = Color(red: 0.09, green: 0.08, blue: 0.15)

    var body: some View {
        Button(action: accion) {
            EtiquetaDeBoton(titulo: titulo, compacto: compacto)
        }
        .buttonStyle(EstiloLujo(conReflejo: false))
    }
}

private struct EtiquetaDeBoton: View {
    let titulo: LocalizedStringKey
    let compacto: Bool
    @Environment(\.isEnabled) private var activo

    var body: some View {
        // El primario de lujo: oro champán cepillado, esquinas de 16 y mayúsculas espaciadas.
        EtiquetaPrimaria(titulo: titulo, ancho: compacto ? nil : 256)
    }
}

// MARK: - Bienvenida

/// La entrada a ZENO: se llega desde el espacio. Primero el cielo, luego una luz que se enciende,
/// y el nombre letra por letra. Nada más: el universo habla solo. Tocar en cualquier parte lo muestra todo de una vez.
struct BienvenidaView: View {
    /// Con botón: la primera vez, antes del registro. Sin botón: cada vez que se abre, y sigue sola.
    var conBoton = true
    /// Entrar como invitado (o, sin botones, seguir sola).
    let alEmpezar: () -> Void
    /// Entrar con Apple: identificador de la cuenta y, si Apple lo da, el nombre.
    var alEntrarConApple: ((String, String?) -> Void)? = nil
    /// La persona ya existe y vuelve tras cerrar sesión (si tiene clave, se le pide).
    var vuelve = false
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

            if conBoton {
                MenuDeEntrada(vuelve: vuelve, alEntrar: alEmpezar, alApple: alEntrarConApple)
                    .opacity(fase >= 4 ? 1 : 0)
                    .offset(y: fase >= 4 ? 0 : 26)
                    .allowsHitTesting(fase >= 4)
            } else {
                // La presentación de cada día: el mismo hueco que tenía el menú oculto (intocable).
                Color.clear.frame(height: 138)
            }
        }
        .contentShape(Rectangle())
        // Tocar salta la presentación; cuando ya terminó, el toque es solo de los botones
        // (si no, se comía el toque de "Continuar con Apple", que es una vista de UIKit).
        .gesture(TapGesture().onEnded { mostrarTodo() }, including: fase < 4 ? .all : .subviews)
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

/// Un punto de oro que respira: el "cargando" de ZENO, sin ruedas de sistema.
struct PuntoQueRespira: View {
    @State private var arriba = false
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    var body: some View {
        Circle()
            .fill(Color.oroZeno)
            .frame(width: 7, height: 7)
            .shadow(color: Color.oroZeno.opacity(0.9), radius: 5)
            .scaleEffect(arriba ? 1.25 : 0.75)
            .opacity(arriba ? 1 : 0.5)
            .onAppear {
                guard !reducirMovimiento else { arriba = true; return }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { arriba = true }
            }
            .accessibilityHidden(true)
    }
}

/// La fecha de nacimiento con tres ruedas propias: día, mes y año. El día se ajusta solo
/// si el mes tiene menos días.
struct FechaDeNacimiento: View {
    @Binding var fecha: Date
    @State private var dia = 1
    @State private var mes = 1
    @State private var anio = 2000
    @State private var listo = false
    private let calendario = Calendar(identifier: .gregorian)

    var body: some View {
        let hoy = calendario.dateComponents([.year], from: .now).year ?? 2026
        HStack(spacing: 0) {
            RuedaDeValores(valores: Array(1...diasDelMes), seleccion: $dia)
            RuedaDeValores(valores: Array(1...12), seleccion: $mes, texto: nombreDelMes)
            RuedaDeValores(valores: Array((hoy - 100)...hoy).reversed(), seleccion: $anio)
                .frame(width: 120)
        }
        .frame(height: 176)
        .background {
            VStack(spacing: 0) {
                Rectangle().fill(Lujo.oro.opacity(0.35)).frame(height: 0.5)
                Spacer().frame(height: 44)
                Rectangle().fill(Lujo.oro.opacity(0.35)).frame(height: 0.5)
            }
            .padding(.horizontal, 20)
        }
        .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.3),
                                     .init(color: .black, location: 0.7), .init(color: .clear, location: 1)],
                             startPoint: .top, endPoint: .bottom))
        .onAppear {
            let c = calendario.dateComponents([.year, .month, .day], from: fecha)
            dia = c.day ?? 1; mes = c.month ?? 1; anio = c.year ?? 2000
            listo = true
        }
        .onChange(of: [dia, mes, anio]) { _, _ in componer() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Fecha de nacimiento"))
    }

    @Environment(\.locale) private var idioma

    /// "ene", "feb"… en el idioma elegido.
    private func nombreDelMes(_ m: Int) -> String {
        let f = DateFormatter()
        f.locale = idioma
        return f.shortStandaloneMonthSymbols[m - 1].replacingOccurrences(of: ".", with: "").capitalized
    }

    private var diasDelMes: Int {
        let base = calendario.date(from: DateComponents(year: anio, month: mes, day: 1)) ?? .now
        return calendario.range(of: .day, in: .month, for: base)?.count ?? 31
    }

    private func componer() {
        guard listo else { return }
        if dia > diasDelMes { dia = diasDelMes; return }
        if let nueva = calendario.date(from: DateComponents(year: anio, month: mes, day: dia)), nueva <= .now {
            fecha = nueva
        }
    }
}
