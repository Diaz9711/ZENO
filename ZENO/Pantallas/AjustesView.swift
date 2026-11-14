import SwiftUI
import SwiftData

/// Ajustes: lo poco que la persona decide. Aquí puede cambiar la forma de su Lumi cuando quiera.
struct AjustesView: View {
    @Bindable var persona: Persona
    /// Dónde empieza el contenido, debajo de Lumi. El cielo queda libre por encima.
    var margenSuperior: CGFloat = 0

    @Environment(\.modelContext) private var contexto
    @State private var confirmarBorrado = false
    @State private var permisoDenegado = false
    @State private var pendientes: [(id: String, fecha: Date?)] = []
    @Query(sort: \EventoDeEnergia.fecha) private var eventos: [EventoDeEnergia]
    @AppStorage("modoPrueba") private var modoPrueba = false
    @Environment(\.desplazamientoDePagina) private var desplazamiento

    var body: some View {
        let apariencia = AparienciaLumi(semilla: persona.semilla)

        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Etiqueta("ZENO")
                        Text("Ajustes")
                            .font(.zenoTitulo(.largeTitle))
                            .luminoso()
                    }
                    Spacer()
                }

                // — Forma de Lumi —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Tu Lumi")
                    HStack(spacing: 14) {
                        ForEach(FormaDeLumi.allCases) { forma in
                            tarjeta(forma, apariencia: apariencia)
                        }
                    }
                    Text("Los colores y el movimiento son solo tuyos; la forma la eliges tú.")
                        .font(.zenoTexto(.footnote))
                        .opacity(0.6)
                }

                // — Avisos —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Avisos")
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: interruptorDeAvisos) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Un aviso amable al día")
                                    .font(.zenoTexto(.body))
                                Text("Como mucho uno, a las \(mejorHora):00, tu mejor hora. Nunca un día en que ya abriste ZENO.")
                                    .font(.zenoTexto(.footnote))
                                    .opacity(0.6)
                            }
                        }
                        .toggleStyle(InterruptorZeno())

                        if persona.notificacionesActivas && persona.avisosEnPausa {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Los dejé en pausa porque parecía que no hacían falta.")
                                    .font(.zenoTexto(.footnote))
                                    .opacity(0.75)
                                Button("Volver a recibirlos") {
                                    Task { await Avisos.reanudar(persona, eventos: eventos) }
                                }
                                .font(.zenoTexto(.subheadline, .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .cristal()
                                .buttonStyle(EstiloPresion())
                            }
                        }

                        if permisoDenegado {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Para recibirlos, permite las notificaciones de ZENO en los Ajustes del iPhone.")
                                    .font(.zenoTexto(.footnote))
                                    .opacity(0.75)
                                Button("Abrir Ajustes del iPhone") {
                                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.zenoTexto(.subheadline, .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .cristal()
                                .buttonStyle(EstiloPresion())
                            }
                        }
                    }
                    .padding(16)
                    .cristal(radio: 20)
                }

                // — Datos —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Tus datos")
                    Text("Todo vive solo en este teléfono. Sin cuentas, sin servidores.")
                        .font(.zenoTexto(.footnote))
                        .opacity(0.6)
                    Button {
                        confirmarBorrado = true
                    } label: {
                        Text("Borrar mis datos")
                            .font(.zenoTexto(.body, .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .cristal(radio: 20)
                    }
                    .buttonStyle(EstiloPresion())
                }

                #if DEBUG
                // Solo en desarrollo: los controles de prueba ya no ensucian la pantalla principal.
                Toggle(isOn: $modoPrueba) {
                    Text("Modo de prueba")
                        .font(.zenoTexto(.body))
                }
                .toggleStyle(InterruptorZeno())
                .padding(16)
                .cristal(radio: 20)

                if modoPrueba {
                    VStack(alignment: .leading, spacing: 10) {
                        Button("Cargar datos de ejemplo") {
                            DatosDeEjemplo.cargar(en: contexto)
                        }
                        .font(.zenoTexto(.subheadline, .medium))
                        Button("Enviar un aviso de prueba en 10 segundos") {
                            Task { await Avisos.enviarPrueba() ; pendientes = await Avisos.pendientes() }
                        }
                        .font(.zenoTexto(.subheadline, .medium))
                        Text("Avisos programados:")
                            .font(.zenoTexto(.footnote, .semibold))
                        if pendientes.isEmpty {
                            Text("Ninguno").font(.zenoTexto(.footnote)).opacity(0.6)
                        }
                        ForEach(pendientes, id: \.id) { p in
                            Text("\(p.id) · \(p.fecha?.formatted(date: .abbreviated, time: .shortened) ?? "—")")
                                .font(.zenoTexto(.caption))
                                .opacity(0.75)
                        }
                        Text("Ignorados seguidos: \(persona.avisosIgnorados) · En pausa: \(persona.avisosEnPausa ? "sí" : "no")")
                            .font(.zenoTexto(.caption))
                            .opacity(0.75)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cristal(radio: 20)
                    .task { pendientes = await Avisos.pendientes() }
                }
                #endif

                Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento.")
                    .font(.zenoTitulo(.footnote, .regular, cursiva: true))
                    .opacity(0.55)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .padding(.top, margenSuperior + 4)
            .padding(.bottom, 130)      // deja sitio a la barra
            .medirDesplazamiento(en: "ajustes")
        }
        .coordinateSpace(name: "ajustes")
        .alDesplazar(desplazamiento)
        // Al subir, los ajustes se funden con el cielo bajo Lumi: una sola pieza, sin corte.
        .fundidoSuperior(inicio: margenSuperior + 6)
        .foregroundStyle(Color.marfil)
        .scrollIndicators(.hidden)
        .confirmationDialog("¿Borrar todo?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Borrar mis datos", role: .destructive, action: borrarTodo)
        } message: {
            Text("Se borran tu estrella, tus tareas y tu historial de energía. No se puede deshacer.")
        }
    }

    private func titulo(_ texto: LocalizedStringKey) -> some View {
        Text(texto)
            .font(.zenoTitulo(.title3, .regular))
            .opacity(0.9)
    }

    /// Una vista previa viva de cada forma, con la semilla de la persona.
    private func tarjeta(_ forma: FormaDeLumi, apariencia: AparienciaLumi) -> some View {
        let elegida = persona.formaDeLumi == forma
        return Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { persona.formaDeLumi = forma }
        } label: {
            VStack(spacing: 6) {
                LumiView(apariencia: apariencia, energia: 0.75, forma: forma)
                    .frame(height: 130)
                    .clipped()
                Text(forma == .estrella ? "Estrella" : "Esfera")
                    .font(.zenoTitulo(.body, elegida ? .regular : .light))
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .cristal(radio: 24, activo: elegida)
        }
        .buttonStyle(EstiloPresion())
        .sensoryFeedback(.selection, trigger: elegida)
        .accessibilityAddTraits(elegida ? .isSelected : [])
    }

    private var mejorHora: Int {
        MotorDeEnergia.mejorHora(persona: persona, eventos: eventos)
    }

    /// Encender pide permiso (solo entonces); apagar borra todo lo pendiente.
    private var interruptorDeAvisos: Binding<Bool> {
        Binding(
            get: { persona.notificacionesActivas },
            set: { quiere in
                if quiere {
                    Task {
                        let resultado = await Avisos.activar(persona, eventos: eventos)
                        withAnimation { permisoDenegado = resultado == .denegados }
                        pendientes = await Avisos.pendientes()
                    }
                } else {
                    Avisos.desactivar(persona)
                    permisoDenegado = false
                    pendientes = []
                }
            })
    }

    private func borrarTodo() {
        Avisos.cancelarTodo()
        try? contexto.delete(model: EventoDeEnergia.self)
        try? contexto.delete(model: Tarea.self)
        try? contexto.delete(model: Persona.self)
        UserDefaults.standard.removeObject(forKey: "diaCalido")
    }
}
