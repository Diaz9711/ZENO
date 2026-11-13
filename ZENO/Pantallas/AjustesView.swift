import SwiftUI
import SwiftData

/// Ajustes: lo poco que la persona decide. Aquí puede cambiar la forma de su Lumi cuando quiera.
struct AjustesView: View {
    @Bindable var persona: Persona

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @State private var confirmarBorrado = false
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
                    Button("Listo") { cerrar() }
                        .font(.zenoTexto(.body, .medium))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .cristal()
                        .buttonStyle(EstiloPresion())
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

                // — Presencia —
                VStack(alignment: .leading, spacing: 12) {
                    titulo("Al abrir")
                    Toggle(isOn: $persona.mostrarEdad.animation()) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Mostrar mi edad")
                                .font(.zenoTexto(.body))
                            Text("Es una de las tres líneas que te traen al hoy.")
                                .font(.zenoTexto(.footnote))
                                .opacity(0.6)
                        }
                    }
                    .toggleStyle(InterruptorZeno())
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
                #endif

                Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento.")
                    .font(.zenoTitulo(.footnote, .regular).italic())
                    .opacity(0.55)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(24)
        }
        .foregroundStyle(Color.marfil)
        .presentationBackground(Color("FondoArranque").opacity(0.96))
        .presentationDragIndicator(.visible)
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

    private func borrarTodo() {
        try? contexto.delete(model: EventoDeEnergia.self)
        try? contexto.delete(model: Tarea.self)
        try? contexto.delete(model: Persona.self)
        UserDefaults.standard.removeObject(forKey: "diaCalido")
        cerrar()
    }
}
