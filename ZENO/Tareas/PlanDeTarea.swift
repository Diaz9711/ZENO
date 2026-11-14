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


/// El día, la hora y el aviso de una tarea, en una tarjeta de lujo.
/// Día y hora son campos propios que abren un selector en una hoja que sube desde abajo.
struct PlanDeTareaView: View {
    @Binding var plan: BorradorDePlan
    @State private var permisoDenegado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $plan.conFecha.animation(Lujo.curva())) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Día y hora")
                        .font(.zenoTexto(.body))
                        .foregroundStyle(Lujo.marfil)
                    Text("Opcional. Si la hora pasa, no pasa nada.")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                }
            }
            .toggleStyle(InterruptorLujo())

            if plan.conFecha {
                VStack(alignment: .leading, spacing: 0) {
                    SeparadorLujo().padding(.vertical, 16)
                    HStack(spacing: 10) {
                        CampoDeValor(icono: .calendario, accion: { elegir(\.fecha, titulo: "El día") }) {
                            Text(plan.fecha, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        }
                        CampoDeValor(icono: .reloj, accion: { elegir(\.fecha, titulo: "La hora") }) {
                            Text(plan.fecha, format: .dateTime.hour().minute())
                        }
                        .frame(width: 118)
                    }

                    EtiquetaLujo("Avisarme")
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    ChipsDeAviso(seleccion: $plan.aviso, alElegir: pedirPermiso)

                    if plan.aviso == .personalizado {
                        CampoDeValor(icono: .campana, activo: true,
                                     accion: { elegir(\.personalizado, titulo: "La hora del aviso") }) {
                            Text(plan.personalizado, format: .dateTime.weekday(.abbreviated).day().hour().minute())
                        }
                        .padding(.top, 10)
                        .transition(.opacity.combined(with: .offset(y: -6)))
                    }

                    Group {
                        if permisoDenegado {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Para avisarte, permite las notificaciones de ZENO en los Ajustes del iPhone.")
                                    .font(.zenoTexto(.caption))
                                    .foregroundStyle(Lujo.marfilSecundario)
                                BotonTerciarioLujo(titulo: "Abrir Ajustes del iPhone") {
                                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .padding(.leading, -12)
                            }
                        } else if plan.aviso != .ninguno {
                            Text("Solo te avisaré de lo que tú programes, sin sonido.")
                                .font(.zenoTexto(.caption))
                                .foregroundStyle(Lujo.marfil.opacity(0.42))
                        }
                    }
                    .padding(.top, 12)
                    .transition(.opacity)
                }
                .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .tarjetaLujo()
    }

    /// Abre el selector propio sobre una copia; al cambiar, la devuelve al plan.
    private func elegir(_ campo: WritableKeyPath<BorradorDePlan, Date>, titulo: LocalizedStringKey) {
        let enlace = $plan
        Hojas.compartidas.mostrar {
            SelectorDeFecha(titulo: titulo,
                            fecha: Binding(get: { enlace.wrappedValue[keyPath: campo] },
                                           set: { enlace.wrappedValue[keyPath: campo] = $0 }))
        }
    }

    /// El permiso se pide aquí, cuando se entiende para qué sirve.
    private func pedirPermiso(_ opcion: OpcionDeAviso) {
        guard opcion != .ninguno else { permisoDenegado = false; return }
        Task {
            let permiso = await AvisosDeTareas.pedirPermiso()
            withAnimation(Lujo.curva()) { permisoDenegado = permiso == .denegado }
        }
    }
}

/// Para Hoy: el día, la hora y el aviso en una hoja (Lumi no se mueve). Trabaja sobre una copia
/// propia y la devuelve al cambiar, para que la hoja siempre se vea al día.
struct HojaDePlan: View {
    @Binding var plan: BorradorDePlan
    @State private var local = BorradorDePlan()
    @State private var listo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                EtiquetaLujo("Tu tarea")
                Text("Cuándo")
                    .font(.zenoTitulo(.title2, .regular))
                    .foregroundStyle(Lujo.marfil)
            }
            PlanDeTareaView(plan: $local)
            BotonPrimarioLujo("Listo") { Hojas.compartidas.cerrar() }
        }
        .onAppear {
            local = plan
            if !local.conFecha { local.conFecha = true }
            listo = true
        }
        .onChange(of: local) { _, nuevo in if listo { plan = nuevo } }
    }
}

/// Editar una tarea: una página dentro del universo (no una hoja de sistema), con los controles de lujo.
struct EditorDeTarea: View {
    @Bindable var tarea: Tarea
    var alCerrar: () -> Void

    @Environment(\.modelContext) private var contexto
    @State private var titulo = ""
    @State private var paso = ""
    @State private var plan = BorradorDePlan()
    @State private var guardados = 0
    @FocusState private var enTitulo: Bool
    @FocusState private var enPaso: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 8) {
                EtiquetaLujo("Editar")
                Text("Tu tarea")
                    .font(.zenoTitulo(.largeTitle))
                    .foregroundStyle(Lujo.marfil)
                    .shadow(color: .black.opacity(0.45), radius: 12, y: 2)
            }
            .aparece(0)

            VStack(alignment: .leading, spacing: 10) {
                EtiquetaLujo("Qué quieres hacer")
                CampoTextoLujo(texto: $titulo, sugerencia: "Una sola frase", enfocado: $enTitulo)
            }
            .aparece(1)

            if tarea.tamano == .grande || tarea.primerPaso != nil {
                VStack(alignment: .leading, spacing: 10) {
                    EtiquetaLujo("Primer paso de dos minutos")
                    CampoTextoLujo(texto: $paso, sugerencia: "Algo muy pequeño (opcional)", enfocado: $enPaso)
                }
                .aparece(2)
            }

            PlanDeTareaView(plan: $plan)
                .aparece(3)

            HStack(spacing: 12) {
                BotonSecundarioLujo("Cancelar") { alCerrar() }
                BotonPrimarioLujo("Guardar", accion: guardar)
                    .disabled(limpio(titulo).isEmpty)
            }
            .padding(.top, 4)
            .aparece(4)

            BotonTerciarioLujo(titulo: "Borrar esta tarea", icono: .papelera, destructivo: true) {
                enTitulo = false; enPaso = false
                Hojas.compartidas.mostrar { ConfirmarBorrado(alBorrar: borrar) }
            }
            .frame(maxWidth: .infinity)
            .aparece(5)
        }
        .padding(.horizontal, Lujo.margen - 20)    // la página ya trae 20 de margen: en total 28
        .foregroundStyle(Lujo.marfil)
        .sensoryFeedback(.success, trigger: guardados)
        .onAppear {
            titulo = tarea.titulo
            paso = tarea.primerPaso ?? ""
            plan = BorradorDePlan(de: tarea)
        }
    }

    private func limpio(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func guardar() {
        let nuevo = limpio(titulo)
        guard !nuevo.isEmpty else { return }
        enTitulo = false; enPaso = false
        if nuevo != tarea.titulo {
            tarea.titulo = nuevo
            tarea.tamano = ClasificadorDeTamano.tamano(de: nuevo)
        }
        let p = limpio(paso)
        tarea.primerPaso = p.isEmpty ? nil : p
        plan.aplicar(a: tarea)
        guardados += 1
        Task { await AvisosDeTareas.sincronizar(contexto) }
        alCerrar()
    }

    /// Primero se cierra el editor; la tarea se borra cuando ya no está en pantalla.
    private func borrar() {
        let tarea = tarea
        alCerrar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            contexto.delete(tarea)
            Task { await AvisosDeTareas.sincronizar(contexto) }
        }
    }
}

/// Confirmación de borrado en una hoja de ZENO (no un diálogo gris de sistema).
private struct ConfirmarBorrado: View {
    let alBorrar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Borrar esta tarea?")
                    .font(.zenoTitulo(.title2, .regular))
                    .foregroundStyle(Lujo.marfil)
                Text("Se borra con su día, su hora y su aviso. No se puede deshacer.")
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
            }
            HStack(spacing: 12) {
                BotonSecundarioLujo("Cancelar") { Hojas.compartidas.cerrar() }
                Button {
                    Hojas.compartidas.cerrar()
                    alBorrar()
                } label: {
                    Text("Borrar")
                        .font(.lujoEtiqueta(.footnote, .medium))
                        .versalitas(1.8)
                        .foregroundStyle(Lujo.rojizo)
                        .frame(maxWidth: .infinity)
                        .frame(height: Lujo.altoBoton)
                        .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
                            .strokeBorder(Lujo.rojizo.opacity(0.55), lineWidth: 0.75))
                        .contentShape(Rectangle())
                }
                .buttonStyle(EstiloLujo())
            }
        }
    }
}

/// Un reloj dibujado a mano (sin símbolos de sistema): abre el día y la hora de una tarea.
struct IconoReloj: View {
    var activo = false

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) * 0.22
            let color = activo ? Color.oroClaro : Color.marfil.opacity(0.85)
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                       with: .color(color), lineWidth: 1.5)
            var agujas = Path()
            agujas.move(to: CGPoint(x: c.x, y: c.y - r * 0.6))
            agujas.addLine(to: c)
            agujas.addLine(to: CGPoint(x: c.x + r * 0.45, y: c.y + r * 0.25))
            ctx.stroke(agujas, with: .color(activo ? .oroZeno : color),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
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

/// Bajo los botones de Hoy: el día y la hora ya elegidos, en voz baja.
struct EtiquetaDePlanBorrador: View {
    let plan: BorradorDePlan

    var body: some View {
        HStack(spacing: 6) {
            IconoFino(icono: .reloj, color: Lujo.oro, tamano: 13)
            Text(plan.fecha, format: .dateTime.weekday(.wide).day().hour().minute())
            if plan.aviso != .ninguno { Text("· con aviso") }
        }
        .font(.zenoTexto(.caption, .medium))
        .foregroundStyle(Lujo.oro.opacity(0.9))
    }
}
