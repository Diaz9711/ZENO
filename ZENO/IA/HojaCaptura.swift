import SwiftUI
import SwiftData

/// Captura por voz (fase IA): la vista previa de las tareas que Chispa encontró en lo dicho.
/// La persona quita las que no quiere, cambia el texto o el tamaño, y confirma con un toque.
struct HojaCaptura: View {
    @State var tareas: [TareaCapturada]
    let conIA: Bool
    var alGuardar: () -> Void = {}

    @Environment(\.modelContext) private var contexto
    @Environment(\.locale) private var idioma

    private var elegidas: [TareaCapturada] {
        tareas.filter { $0.incluida && !$0.titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                DibujoDeCohete(diseno: .clasico).frame(width: 34, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: Cohete.nombre.uppercased())
                        .font(.zenoTexto(.caption2, .semibold)).kerning(1.6).foregroundStyle(Lujo.oro)
                    Text("Esto es lo que te oí")
                        .font(.zenoTitulo(.title2, .regular)).foregroundStyle(Lujo.marfil)
                }
            }
            VStack(spacing: 0) {
                ForEach($tareas) { $t in
                    if t.id != tareas.first?.id { SeparadorLujo() }
                    fila($t)
                }
            }
            .padding(.horizontal, 16)
            .tarjetaLujo()
            Text(conIA ? "Separadas por la IA de tu iPhone. Nada sale del teléfono."
                       : "Una tarea por frase, sin IA. Cámbialas como quieras.")
                .font(.zenoTexto(.caption))
                .foregroundStyle(Lujo.marfilSecundario)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                BotonSecundarioLujo("Cancelar") { Hojas.compartidas.cerrar() }
                BotonPrimarioLujo(elegidas.count == 1 ? "Guardar 1 tarea" : "Guardar \(elegidas.count) tareas") { guardar() }
                    .disabled(elegidas.isEmpty)
            }
        }
        .animation(Lujo.curva(), value: tareas)
    }

    private func fila(_ t: Binding<TareaCapturada>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button { t.wrappedValue.incluida.toggle() } label: {
                CheckDibujado(hecho: t.wrappedValue.incluida).frame(width: 24, height: 24)
                    .frame(width: 32, height: 40).contentShape(Rectangle())
            }
            .buttonStyle(EstiloLujo(conReflejo: false))
            .accessibilityLabel(t.wrappedValue.incluida ? Text("Quitar esta tarea") : Text("Incluir esta tarea"))
            VStack(alignment: .leading, spacing: 8) {
                TextField("", text: t.titulo, axis: .vertical)
                    .font(.zenoTexto(.callout))
                    .foregroundStyle(Lujo.marfil.opacity(t.wrappedValue.incluida ? 1 : 0.4))
                    .tint(Lujo.oro)
                    .lineLimit(1...3)
                HStack(spacing: 6) {
                    ForEach(TamanoDeTarea.allCases, id: \.self) { tam in
                        let elegido = t.wrappedValue.tamano == tam
                        Button { t.wrappedValue.tamano = tam } label: {
                            Text(nombre(tam))
                                .font(.zenoTexto(.caption2, elegido ? .semibold : .regular))
                                .foregroundStyle(elegido ? Lujo.oro : Lujo.marfilSecundario)
                                .padding(.horizontal, 10).frame(height: 26)
                                .background(Capsule().strokeBorder(elegido ? Lujo.oro.opacity(0.8) : Lujo.marfil.opacity(0.12), lineWidth: 0.75))
                        }
                        .buttonStyle(EstiloLujo(conReflejo: false))
                    }
                    if !t.wrappedValue.conPorque {
                        Button { withAnimation(Lujo.curva()) { t.wrappedValue.conPorque = true } } label: {
                            EstrellitaDeCuatro().fill(Lujo.oro.opacity(0.85)).frame(width: 11, height: 11)
                                .frame(width: 30, height: 26).contentShape(Rectangle())
                        }
                        .buttonStyle(EstiloLujo(conReflejo: false))
                        .accessibilityLabel(Text("¿Para qué te importa?"))
                    }
                    if let fecha = t.wrappedValue.fecha {
                        Button { t.wrappedValue.fecha = nil } label: {
                            HStack(spacing: 4) {
                                IconoFino(icono: .reloj, color: Lujo.oro, tamano: 11)
                                Text(fecha.formatted(.dateTime.weekday(.abbreviated).hour().minute().locale(idioma)))
                                    .font(.zenoTexto(.caption2, .medium)).foregroundStyle(Lujo.oro)
                                IconoFino(icono: .cerrar, color: Lujo.marfilSecundario, tamano: 8)
                            }
                            .padding(.horizontal, 8).frame(height: 26)
                        }
                        .buttonStyle(EstiloLujo(conReflejo: false))
                        .accessibilityLabel(Text("Quitar la hora"))
                    }
                }
                // El porqué de esta tarea (opcional), una línea.
                if t.wrappedValue.conPorque {
                    TextField("", text: t.porque, prompt: Text("¿Para qué te importa? (opcional)").foregroundStyle(Lujo.marfil.opacity(0.3)))
                        .font(.zenoTitulo(.callout, .light, cursiva: true))
                        .foregroundStyle(Lujo.oro)
                        .tint(Lujo.oro)
                        .transition(.opacity)
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func nombre(_ t: TamanoDeTarea) -> LocalizedStringKey {
        switch t { case .chica: "Pequeña"; case .mediana: "Media"; case .grande: "Grande" }
    }

    private func guardar() {
        var crisis = false
        for t in elegidas {
            let tarea = Tarea(titulo: t.titulo.trimmingCharacters(in: .whitespacesAndNewlines), tamano: t.tamano)
            let anzuelo = String(t.porque.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
            tarea.porque = anzuelo.isEmpty ? nil : anzuelo
            if Cuidado.suenaACrisis(anzuelo) { crisis = true }
            contexto.insert(tarea)
            if let fecha = t.fecha { tarea.aplicarPlan(fecha: fecha, aviso: .ninguno, personalizado: fecha) }
        }
        Task { await AvisosDeTareas.sincronizar(contexto) }
        Hojas.compartidas.cerrar()
        alGuardar()
        if crisis {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                Hojas.compartidas.mostrar { VistaDeCuidado() }
            }
        }
    }
}
