import SwiftUI

/// "Divídemela" (fase IA): Chispa divide la tarea en pasos de unos 5 minutos. La persona puede editar,
/// borrar, mover o añadir pasos antes de guardar. Nada se guarda sin su toque.
struct HojaDividir: View {
    let tarea: Tarea
    let energia: NivelDeEnergia
    /// Lo aprendido: este tipo de tarea le cuesta, así que se piden pasos más pequeños.
    var masPequenos = false
    var alGuardar: () -> Void = {}

    @Environment(\.locale) private var idiomaElegido
    @State private var pasos: [String] = []
    @State private var cargando = true
    @State private var motor = ""
    @State private var deRespaldo = false
    @State private var crisis = false
    @FocusState private var editando: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            cabecera
            if crisis {
                cuidado
            } else if cargando {
                HStack(spacing: 12) {
                    PuntoQueRespira()
                    Text("Chispa la está dividiendo…")
                        .font(.zenoTexto(.callout))
                        .foregroundStyle(Lujo.marfilSecundario)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .transition(.opacity)
            } else {
                lista
                pie
            }
        }
        .animation(Lujo.curva(), value: cargando)
        .animation(Lujo.curva(), value: pasos)
        .task { await dividir() }
    }

    private var cabecera: some View {
        HStack(spacing: 14) {
            DibujoDeCohete(diseno: .clasico)
                .frame(width: 34, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: Cohete.nombre.uppercased())
                    .font(.zenoTexto(.caption2, .semibold))
                    .kerning(1.6)
                    .foregroundStyle(Lujo.oro)
                Text("Divídemela")
                    .font(.zenoTitulo(.title2, .regular))
                    .foregroundStyle(Lujo.marfil)
                Text(verbatim: tarea.titulo)
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .lineLimit(2)
            }
        }
    }

    private var lista: some View {
        VStack(spacing: 0) {
            ForEach(Array(pasos.enumerated()), id: \.offset) { i, _ in
                if i > 0 { SeparadorLujo() }
                HStack(spacing: 10) {
                    Text(verbatim: "\(i + 1)")
                        .font(.zenoTitulo(.callout, .regular))
                        .foregroundStyle(Lujo.oro)
                        .frame(width: 18)
                    TextField("", text: Binding(get: { pasos.indices.contains(i) ? pasos[i] : "" },
                                                set: { if pasos.indices.contains(i) { pasos[i] = $0 } }),
                              axis: .vertical)
                        .font(.zenoTexto(.callout))
                        .foregroundStyle(Lujo.marfil)
                        .tint(Lujo.oro)
                        .lineLimit(1...3)
                        .focused($editando, equals: i)
                    // Mover (arriba / abajo) y borrar: controles finos propios, nada de listas del sistema.
                    VStack(spacing: 2) {
                        flecha(arriba: true, i)
                        flecha(arriba: false, i)
                    }
                    Button { _ = withAnimation(Lujo.curva()) { pasos.remove(at: i) } } label: {
                        IconoFino(icono: .papelera, color: Lujo.marfilSecundario, tamano: 14)
                            .frame(width: 32, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(EstiloLujo())
                    .accessibilityLabel(Text("Borrar este paso"))
                }
                .padding(.vertical, 6)
            }
            if pasos.count < 7 {
                SeparadorLujo()
                Button {
                    withAnimation(Lujo.curva()) { pasos.append("") }
                    editando = pasos.count - 1
                } label: {
                    HStack(spacing: 10) {
                        IconoFino(icono: .mas, color: Lujo.oro, tamano: 14)
                        Text("Añadir un paso").font(.zenoTexto(.callout)).foregroundStyle(Lujo.oro)
                        Spacer()
                    }
                    .frame(minHeight: 46)
                    .contentShape(Rectangle())
                }
                .buttonStyle(EstiloLujo())
            }
        }
        .padding(.horizontal, 16)
        .tarjetaLujo()
    }

    private func flecha(arriba: Bool, _ i: Int) -> some View {
        let destino = arriba ? i - 1 : i + 1
        let puede = pasos.indices.contains(destino)
        return Button {
            withAnimation(Lujo.curva()) { pasos.swapAt(i, destino) }
        } label: {
            IconoFino(icono: .atras, color: Lujo.marfilSecundario.opacity(puede ? 1 : 0.25), tamano: 10)
                .rotationEffect(.degrees(arriba ? 90 : -90))
                .frame(width: 28, height: 19)
                .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .disabled(!puede)
        .accessibilityLabel(arriba ? Text("Subir este paso") : Text("Bajar este paso"))
    }

    private var pie: some View {
        VStack(spacing: 12) {
            Text(deRespaldo ? "Pasos de ejemplo, sin IA. Cámbialos como quieras."
                            : "Hechos con la IA de tu iPhone. Nada sale del teléfono.")
                .font(.zenoTexto(.caption))
                .foregroundStyle(Lujo.marfilSecundario)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                BotonSecundarioLujo("Cancelar") { Hojas.compartidas.cerrar() }
                BotonPrimarioLujo("Guardar pasos") { guardar() }
                    .disabled(pasosLimpios.isEmpty)
            }
        }
    }

    private var cuidado: some View { VistaDeCuidado(conCabecera: false) }

    private var pasosLimpios: [String] {
        pasos.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private func dividir() async {
        guard cargando else { return }
        // Crisis: se revisa en código antes de cualquier motor.
        if Cuidado.suenaACrisis(tarea.titulo) || Cuidado.suenaACrisis(tarea.porque ?? "") { crisis = true; cargando = false; return }
        if !tarea.pasos.isEmpty {
            // Ya estaba dividida: se editan sus pasos, sin volver a generar.
            pasos = tarea.pasos; motor = ""; deRespaldo = false; cargando = false; return
        }
        let pedido = PedidoDeDivision(titulo: tarea.titulo, porque: tarea.anzuelo ?? "", tamano: tarea.tamano, energia: energia, idioma: Idioma.actual,
                                      masPequenos: masPequenos)
        let resultado = await ServicioDeIA.compartido.dividir(pedido)
        pasos = resultado.pasos
        motor = resultado.motor
        deRespaldo = resultado.deRespaldo
        cargando = false
    }

    private func guardar() {
        tarea.pasos = pasosLimpios
        tarea.pasoActual = 0
        Hojas.compartidas.cerrar()
        alGuardar()
    }
}

/// Si algo suena a crisis emocional: ZENO no responde como terapeuta. Un mensaje amable y general
/// (sin números de teléfono inventados).
struct VistaDeCuidado: View {
    var conCabecera = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if conCabecera {
                HStack(spacing: 12) {
                    DibujoDeCohete(diseno: .clasico).frame(width: 30, height: 36)
                    Text(verbatim: Cohete.nombre.uppercased())
                        .font(.zenoTexto(.caption2, .semibold)).kerning(1.6).foregroundStyle(Lujo.oro)
                }
            }
            Text("Esto suena muy pesado.")
                .font(.zenoTitulo(.title3, .regular))
                .foregroundStyle(Lujo.marfil)
            Text("No hace falta dividir nada ahora. Si estás pasando por un momento muy difícil, habla con alguien de confianza o con un profesional. Si estás en peligro, llama a los servicios de emergencia de tu país.")
                .font(.zenoTexto(.callout))
                .foregroundStyle(Lujo.marfilSecundario)
                .fixedSize(horizontal: false, vertical: true)
            BotonPrimarioLujo("Entendido") { Hojas.compartidas.cerrar() }
                .padding(.top, 6)
        }
    }
}
