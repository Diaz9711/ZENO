import SwiftUI
import SwiftData

/// Ajustes: lo poco que la persona decide. Aquí puede cambiar la forma de su Lumi cuando quiera.
struct AjustesView: View {
    @Bindable var persona: Persona
    /// Dónde empieza el contenido, debajo de Lumi. Lo de encima se funde con el cielo.
    var arriba: CGFloat = 0

    @Environment(\.modelContext) private var contexto
    @State private var confirmarBorrado = false
    @State private var confirmarSalida = false
    @AppStorage(Sesion.clave) private var sesionAbierta = true
    @AppStorage(Idioma.clave) private var idioma = Idioma.actual.rawValue
    @State private var permisoDenegado = false
    @State private var pendientes: [(id: String, fecha: Date?)] = []
    @Query(sort: \EventoDeEnergia.fecha) private var eventos: [EventoDeEnergia]
    @AppStorage("modoPrueba") private var modoPrueba = false

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

                // — Idioma —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Idioma")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(Idioma.allCases) { opcion in
                            let elegido = idioma == opcion.rawValue
                            Button {
                                cambiarIdioma(a: opcion)
                            } label: {
                                HStack {
                                    Text(verbatim: opcion.nombre)
                                        .font(.zenoTexto(.body, elegido ? .semibold : .medium))
                                    Spacer()
                                    ZStack {
                                        Circle().strokeBorder(Color.oroZeno.opacity(elegido ? 1 : 0.45), lineWidth: 1.2)
                                        if elegido { Circle().fill(Color.oroZeno).padding(5) }
                                    }
                                    .frame(width: 20, height: 20)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .cristal(radio: 16, activo: elegido)
                            }
                            .buttonStyle(EstiloPresion())
                            .accessibilityAddTraits(elegido ? .isSelected : [])
                        }
                    }
                    .sensoryFeedback(.selection, trigger: idioma)
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

                // — Lo aprendido —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Tu ritmo")
                    let aprendido = Aprendizaje.resumen(eventos: eventos)
                    VStack(alignment: .leading, spacing: 12) {
                        if aprendido.isEmpty {
                            Text("Mientras más uses ZENO, más te conoceré: a qué horas rindes, cuánto te toman las cosas y qué prefieres dejar para después.")
                                .font(.zenoTexto(.footnote))
                                .opacity(0.75)
                        } else {
                            ForEach(aprendido, id: \.self) { frase in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Circle().fill(Color.oroZeno).frame(width: 5, height: 5)
                                    Text(verbatim: frase)
                                        .font(.zenoTexto(.subheadline))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cristal(radio: 20)
                }

                // — Sesión —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Sesión")
                    Text(persona.cuentaApple == nil ? "Entraste como invitado." : "Entraste con tu cuenta de Apple.")
                        .font(.zenoTexto(.footnote))
                        .opacity(0.6)
                    Button {
                        confirmarSalida = true
                    } label: {
                        Text("Cerrar sesión")
                            .font(.zenoTexto(.body, .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .cristal(radio: 20)
                    }
                    .buttonStyle(EstiloPresion())
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
            .padding(.top, arriba + 4)
            .padding(.bottom, 130)      // deja sitio a la barra
            .informaDesplazamiento()
        }
        .coordinateSpace(name: "pagina")
        .bordesFundidos(arriba: arriba)
        .foregroundStyle(Color.marfil)
        .scrollIndicators(.hidden)
        .onAppear { Desplazamiento.compartido.valor = 0 }
        .confirmationDialog("¿Cerrar sesión?", isPresented: $confirmarSalida, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive, action: cerrarSesion)
        } message: {
            Text("Tu estrella, tus tareas y tu historial se quedan guardados en este teléfono. Para volver, entra de nuevo.")
        }
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
                LumiView(apariencia: apariencia, energia: 0.75, forma: forma, cuadros: 30)
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

    /// Cambia el idioma de toda la app al momento y reescribe los avisos ya programados en el nuevo idioma.
    private func cambiarIdioma(a nuevo: Idioma) {
        guard idioma != nuevo.rawValue else { return }
        withAnimation(Ritmo.contenido) { idioma = nuevo.rawValue }
        Task {
            if persona.notificacionesActivas { await Avisos.programar(persona, eventos: eventos) }
            await AvisosDeTareas.sincronizar(contexto)
        }
    }

    /// Cierra la sesión sin borrar nada. Mientras esté cerrada no llega ningún aviso.
    private func cerrarSesion() {
        Avisos.cancelarTodo()
        withAnimation(.spring(response: 0.75, dampingFraction: 0.74)) { sesionAbierta = false }
    }

    private func borrarTodo() {
        Avisos.cancelarTodo()
        try? contexto.delete(model: EventoDeEnergia.self)
        try? contexto.delete(model: Tarea.self)
        try? contexto.delete(model: Persona.self)
        UserDefaults.standard.removeObject(forKey: "diaCalido")
    }
}
