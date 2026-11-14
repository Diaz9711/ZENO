import SwiftUI
import SwiftData
import UIKit

/// Lo que se está eligiendo para una tarea: su día y hora (opcional) y cuándo avisar.
struct BorradorDePlan: Equatable {
    var conFecha = false
    var fecha = BorradorDePlan.proximaHora()
    var aviso = OpcionDeAviso.ninguno
    var personalizado = BorradorDePlan.proximaHora().addingTimeInterval(-30 * 60)

    init() {}

    init(de tarea: Tarea) {
        conFecha = tarea.fechaPlaneada != nil
        fecha = tarea.fechaPlaneada ?? Self.proximaHora()
        aviso = tarea.opcionDeAviso
        personalizado = tarea.avisoPersonalizado ?? fecha.addingTimeInterval(-30 * 60)
    }

    /// La próxima hora en punto: un valor amable para empezar.
    static func proximaHora(_ ahora: Date = .now) -> Date {
        let cal = Calendar.current
        let base = cal.date(bySetting: .minute, value: 0, of: ahora) ?? ahora
        return cal.date(byAdding: .hour, value: base > ahora ? 0 : 1, to: base) ?? ahora
    }

    func aplicar(a tarea: Tarea) {
        tarea.aplicarPlan(fecha: conFecha ? fecha : nil, aviso: aviso, personalizado: personalizado)
    }
}

/// El día, la hora y el aviso de una tarea, en una tarjeta de cristal.
/// Plegada por defecto: escribir una tarea sigue siendo una sola acción.
struct PlanDeTareaView: View {
    @Binding var plan: BorradorDePlan
    @State private var permisoDenegado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $plan.conFecha.animation(Ritmo.contenido)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Día y hora")
                        .font(.zenoTexto(.body))
                    Text("Opcional. Si la hora pasa, no pasa nada.")
                        .font(.zenoTexto(.caption))
                        .opacity(0.6)
                }
            }
            .toggleStyle(InterruptorZeno())

            if plan.conFecha {
                DatePicker("Cuándo", selection: $plan.fecha, in: Date.now...,
                           displayedComponents: [.date, .hourAndMinute])
                    .font(.zenoTexto(.body))
                    .tint(Color.oroZeno)
                    .colorScheme(.dark)
                    .transition(.desenfoque)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Avisarme")
                        .font(.zenoTexto(.caption, .semibold))
                        .textCase(.uppercase)
                        .tracking(1.6)
                        .foregroundStyle(Color.oroZeno)
                    // Una rejilla y no una fila deslizable: así el brillo de lo elegido no se corta.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(OpcionDeAviso.allCases) { opcion in chip(opcion) }
                    }

                    if plan.aviso == .personalizado {
                        DatePicker("Aviso a las", selection: $plan.personalizado, in: Date.now...,
                                   displayedComponents: [.date, .hourAndMinute])
                            .font(.zenoTexto(.body))
                            .tint(Color.oroZeno)
                            .colorScheme(.dark)
                            .transition(.desenfoque)
                    }
                    if permisoDenegado {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Para avisarte, permite las notificaciones de ZENO en los Ajustes del iPhone.")
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
                        .transition(.opacity)
                    } else if plan.aviso != .ninguno {
                        Text("Solo te avisaré de lo que tú programes, sin sonido.")
                            .font(.zenoTexto(.caption))
                            .opacity(0.55)
                    }
                }
                .transition(.desenfoque)
            }
        }
        .padding(16)
        .cristal(radio: 20)
        .foregroundStyle(Color.marfil)
    }

    private func chip(_ opcion: OpcionDeAviso) -> some View {
        let elegida = plan.aviso == opcion
        return Button {
            withAnimation(Ritmo.contenido) { plan.aviso = opcion }
            guard opcion != .ninguno else { permisoDenegado = false; return }
            // El permiso se pide aquí, cuando se entiende para qué sirve.
            Task {
                let permiso = await AvisosDeTareas.pedirPermiso()
                withAnimation(Ritmo.contenido) { permisoDenegado = permiso == .denegado }
            }
        } label: {
            Text(titulo(opcion))
                .font(.zenoTexto(.subheadline, elegida ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .cristal(activo: elegida)
        }
        .buttonStyle(EstiloPresion())
        .sensoryFeedback(.selection, trigger: elegida)
        .accessibilityAddTraits(elegida ? .isSelected : [])
    }

    private func titulo(_ opcion: OpcionDeAviso) -> LocalizedStringKey {
        switch opcion {
        case .ninguno: "Sin aviso"
        case .aLaHora: "A la hora"
        case .diezAntes: "10 min antes"
        case .unaHoraAntes: "1 hora antes"
        case .personalizado: "Otra hora"
        }
    }
}

/// Editar una tarea: una página dentro del universo (no una hoja de sistema).
struct EditorDeTarea: View {
    @Bindable var tarea: Tarea
    var alCerrar: () -> Void

    @Environment(\.modelContext) private var contexto
    @State private var titulo = ""
    @State private var paso = ""
    @State private var plan = BorradorDePlan()
    @State private var confirmarBorrado = false
    @FocusState private var escribiendo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Etiqueta("Editar")
                Text("Tu tarea")
                    .font(.zenoTitulo(.largeTitle))
                    .luminoso()
            }

            campo($titulo, "Qué quieres hacer")
            if tarea.tamano == .grande || tarea.primerPaso != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primer paso de dos minutos")
                        .font(.zenoTexto(.caption, .semibold))
                        .textCase(.uppercase)
                        .tracking(1.6)
                        .foregroundStyle(Color.oroZeno)
                    campo($paso, "Algo muy pequeño (opcional)")
                }
            }

            PlanDeTareaView(plan: $plan)

            HStack(spacing: 12) {
                Button { alCerrar() } label: {
                    Text("Cancelar")
                        .font(.zenoTexto(.body, .medium))
                        .padding(.vertical, 11)
                        .padding(.horizontal, 26)
                        .cristal()
                }
                .buttonStyle(EstiloPresion())
                Spacer()
                BotonZeno("Guardar", compacto: true, accion: guardar)
                    .disabled(limpio(titulo).isEmpty)
            }

            Button { confirmarBorrado = true } label: {
                Text("Borrar esta tarea")
                    .font(.zenoTexto(.subheadline))
                    .opacity(0.6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.marfil)
        .onAppear {
            titulo = tarea.titulo
            paso = tarea.primerPaso ?? ""
            plan = BorradorDePlan(de: tarea)
        }
        .confirmationDialog("¿Borrar esta tarea?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Borrar", role: .destructive) {
                contexto.delete(tarea)
                Task { await AvisosDeTareas.sincronizar(contexto) }
                alCerrar()
            }
        }
    }

    private func campo(_ texto: Binding<String>, _ sugerencia: LocalizedStringKey) -> some View {
        TextField("", text: texto, prompt: Text(sugerencia).foregroundStyle(Color.marfil.opacity(0.35)), axis: .vertical)
            .font(.zenoTitulo(.title3, .regular))
            .lineLimit(1...3)
            .focused($escribiendo)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .cristal(radio: 20)
    }

    private func limpio(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func guardar() {
        let nuevo = limpio(titulo)
        guard !nuevo.isEmpty else { return }
        escribiendo = false
        if nuevo != tarea.titulo {
            tarea.titulo = nuevo
            tarea.tamano = ClasificadorDeTamano.tamano(de: nuevo)
        }
        let p = limpio(paso)
        tarea.primerPaso = p.isEmpty ? nil : p
        plan.aplicar(a: tarea)
        Task { await AvisosDeTareas.sincronizar(contexto) }
        alCerrar()
    }
}

/// "jueves 10:00 · con aviso": el plan de una tarea, en voz baja. Solo si la hora aún no pasó.
struct EtiquetaDePlan: View {
    let tarea: Tarea

    var body: some View {
        if let fecha = tarea.fechaPlaneada, fecha > .now {
            HStack(spacing: 6) {
                Circle().fill(Color.oroZeno).frame(width: 4, height: 4)
                Text(fecha, format: .dateTime.weekday(.wide).day().hour().minute())
                if tarea.momentoDelAviso != nil {
                    Text("· con aviso")
                }
            }
            .font(.zenoTexto(.caption, .medium))
            .foregroundStyle(Color.oroZeno.opacity(0.85))
        }
    }
}
