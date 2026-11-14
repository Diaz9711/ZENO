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
        case .bienvenida: bienvenida
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

    private var bienvenida: some View {
        VStack(spacing: 18) {
            Spacer()
            MarcaZeno(tamano: 46)
                .padding(.bottom, 26)
            // La promesa de ZENO, con la palabra que importa en oro.
            (Text("Una app que se adapta\na tu ").foregroundStyle(Color.marfil)
             + Text("energía").font(.zenoTitulo(.title, .regular, cursiva: true)).foregroundStyle(Color.oroZeno)
             + Text(",\nno al revés.").foregroundStyle(Color.marfil))
                .font(.zenoTitulo(.title, .light))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .shadow(color: .black.opacity(0.5), radius: 10, y: 2)
                .shadow(color: Color.oroZeno.opacity(0.22), radius: 20)
                .padding(.horizontal, 28)
            Spacer()
            Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento.")
                .font(.zenoTexto(.caption))
                .multilineTextAlignment(.center)
                .opacity(0.55)
                .padding(.horizontal, 44)
            BotonZeno("Crear mi estrella") { ir(a: .nombre) }
        }
    }

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
            BotonZeno("Continuar") { ir(a: .fecha) }
                .disabled(borrador.nombreLimpio.isEmpty)
                .opacity(borrador.nombreLimpio.isEmpty ? 0.4 : 1)
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
struct BotonZeno: View {
    let titulo: LocalizedStringKey
    /// 0 a 1. Con energía baja el botón brilla menos: invita, no grita.
    var intensidad: Double
    let accion: () -> Void

    init(_ titulo: LocalizedStringKey, intensidad: Double = 1, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.intensidad = intensidad
        self.accion = accion
    }

    static let tinta = Color(red: 0.09, green: 0.08, blue: 0.15)

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 12) {
                Text(titulo)
                    .font(.zenoTexto(.body, .bold))
                    .tracking(0.4)
                    .foregroundStyle(Self.tinta)
                    .padding(.leading, 26)
                Spacer(minLength: 8)
                ZStack {
                    Circle().fill(Self.tinta.opacity(0.92))
                    FlechaDibujada()
                        .stroke(Color.oroClaro, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                        .frame(width: 15, height: 12)
                }
                .frame(width: 42, height: 42)
                .padding(.trailing, 7)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                let forma = Capsule()
                ZStack {
                    forma.fill(LinearGradient(colors: [.oroClaro, .oroZeno, .oroHondo],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                    // Un reflejo arriba: el oro parece metal pulido, no un color plano.
                    forma.fill(LinearGradient(colors: [.white.opacity(0.35), .clear],
                                              startPoint: .top, endPoint: .center))
                        .padding(1.5)
                    forma.strokeBorder(Color.oroClaro.opacity(0.9), lineWidth: 0.8)
                }
                .saturation(0.75 + 0.25 * intensidad)
                .brightness(-0.10 * (1 - intensidad))
                .shadow(color: Color.oroZeno.opacity(0.18 + 0.27 * intensidad), radius: 18, y: 4)
            }
        }
        .buttonStyle(EstiloPresion())
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
    }
}
