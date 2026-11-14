import SwiftUI

/// Selector propio de día y hora, dentro de una hoja de ZENO (sin ruedas ni calendarios de sistema).
/// Arriba, una tira de días; abajo, dos columnas que se deslizan y se asientan solas (horas y minutos).
/// Trabaja sobre una copia local y la devuelve al cambiar: así se ve fluida aunque viva en otra capa.
struct SelectorDeFecha: View {
    let titulo: LocalizedStringKey
    @Binding var fecha: Date
    /// No se puede elegir antes de esto (normalmente, ahora).
    var desde: Date = .now

    @State private var local = Date.now
    @State private var hora = 0
    @State private var minuto = 0
    @Namespace private var espacio
    private let calendario = Calendar.current

    private static let minutos = Array(stride(from: 0, to: 60, by: 5))

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                EtiquetaLujo("Cuándo")
                Text(titulo)
                    .font(.zenoTitulo(.title2, .regular))
                    .foregroundStyle(Lujo.marfil)
            }

            // Tira de días: dos semanas desde hoy.
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(dias, id: \.self) { dia in diaView(dia) }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()

            // Las dos columnas: horas y minutos, con una franja fina que marca lo elegido.
            HStack(spacing: 0) {
                RuedaDeValores(valores: Array(0..<24), seleccion: $hora)
                Text(verbatim: ":")
                    .font(.zenoTitulo(.title2, .light))
                    .foregroundStyle(Lujo.oro)
                    .frame(width: 24)
                RuedaDeValores(valores: Self.minutos, seleccion: $minuto)
            }
            .frame(height: 176)
            .background {
                VStack(spacing: 0) {
                    Rectangle().fill(Lujo.oro.opacity(0.35)).frame(height: 0.5)
                    Spacer().frame(height: 44)
                    Rectangle().fill(Lujo.oro.opacity(0.35)).frame(height: 0.5)
                }
                .padding(.horizontal, 40)
            }
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.3),
                                         .init(color: .black, location: 0.7), .init(color: .clear, location: 1)],
                                 startPoint: .top, endPoint: .bottom))

            BotonPrimarioLujo("Listo") { Hojas.compartidas.cerrar() }
        }
        .onAppear {
            local = max(fecha, calendario.startOfDay(for: desde))
            hora = calendario.component(.hour, from: local)
            let m = calendario.component(.minute, from: local)
            minuto = Self.minutos.min { abs($0 - m) < abs($1 - m) } ?? 0
        }
        .onChange(of: hora) { _, _ in componer() }
        .onChange(of: minuto) { _, _ in componer() }
    }

    private var dias: [Date] {
        let hoy = calendario.startOfDay(for: min(desde, local))
        return (0..<14).compactMap { calendario.date(byAdding: .day, value: $0, to: hoy) }
    }

    private func diaView(_ dia: Date) -> some View {
        let elegido = calendario.isDate(dia, inSameDayAs: local)
        let esHoy = calendario.isDateInToday(dia)
        return Button {
            withAnimation(Lujo.curva(0.45)) {
                local = combinar(dia: dia)
                fecha = local
            }
        } label: {
            VStack(spacing: 6) {
                Text(dia, format: .dateTime.weekday(.abbreviated))
                    .font(.lujoEtiqueta(.caption2, .medium))
                    .versalitas(1.2)
                    .foregroundStyle(elegido ? Lujo.oro : Lujo.marfilSecundario)
                Text(dia, format: .dateTime.day())
                    .font(.zenoTitulo(.title3, .regular))
                    .foregroundStyle(elegido ? Lujo.oro : Lujo.marfil)
                Circle().fill(esHoy ? Lujo.oro : .clear).frame(width: 3, height: 3)
            }
            .frame(width: 48, height: 72)
            .background {
                if elegido {
                    RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous)
                        .strokeBorder(Lujo.oro.opacity(0.8), lineWidth: 0.75)
                        .matchedGeometryEffect(id: "dia", in: espacio)
                } else {
                    RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous)
                        .fill(Lujo.marfil.opacity(0.03))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.selection, trigger: elegido)
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }

    private func combinar(dia: Date) -> Date {
        calendario.date(bySettingHour: hora, minute: minuto, second: 0, of: dia) ?? dia
    }

    private func componer() {
        local = combinar(dia: local)
        fecha = local
    }
}

/// Una rueda propia: se arrastra, se asienta sola en un valor y el elegido se enciende en oro.
/// Sin rueda de sistema y sin desplazamiento nativo (que no siempre se asienta en el primer valor).
struct RuedaDeValores: View {
    let valores: [Int]
    @Binding var seleccion: Int
    private let alto: CGFloat = 44
    @State private var arrastre: CGFloat = 0

    private var indice: Int { valores.firstIndex(of: seleccion) ?? 0 }

    /// El valor que queda en el centro mientras se arrastra (para encenderlo antes de soltar).
    private var indiceVisible: Int {
        min(max(indice - Int((arrastre / alto).rounded()), 0), valores.count - 1)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ForEach(valores.indices, id: \.self) { i in
                    let elegido = i == indiceVisible
                    Text(verbatim: String(format: "%02d", valores[i]))
                        .font(.zenoTitulo(.title2, elegido ? .regular : .light))
                        .foregroundStyle(elegido ? Lujo.oro : Lujo.marfil.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .frame(height: alto)
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(Lujo.curva(0.45)) { seleccion = valores[i] } }
                }
            }
            .offset(y: geo.size.height / 2 - alto / 2 - CGFloat(indice) * alto + arrastre)
        }
        .clipped()
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 2)
            .onChanged { arrastre = $0.translation.height }
            .onEnded { v in
                let recorrido = v.translation.height + (v.predictedEndTranslation.height - v.translation.height) * 0.35
                let nuevo = min(max(indice - Int((recorrido / alto).rounded()), 0), valores.count - 1)
                withAnimation(Lujo.curva(0.5)) {
                    seleccion = valores[nuevo]
                    arrastre = 0
                }
            })
        .sensoryFeedback(.selection, trigger: indiceVisible)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: String(format: "%02d", seleccion)))
        .accessibilityAdjustableAction { direccion in
            switch direccion {
            case .increment: seleccion = valores[min(indice + 1, valores.count - 1)]
            case .decrement: seleccion = valores[max(indice - 1, 0)]
            @unknown default: break
            }
        }
    }
}

/// Los cinco avisos en una cuadrícula limpia: tres arriba y dos abajo, cada fila llena de lado a lado.
/// El borde dorado de lo elegido se desliza de un chip al otro.
struct ChipsDeAviso: View {
    @Binding var seleccion: OpcionDeAviso
    var alElegir: (OpcionDeAviso) -> Void = { _ in }
    @Namespace private var espacio

    var body: some View {
        let todas = OpcionDeAviso.allCases
        VStack(spacing: 8) {
            HStack(spacing: 8) { ForEach(todas.prefix(3)) { chip($0) } }
            HStack(spacing: 8) { ForEach(todas.suffix(2)) { chip($0) } }
        }
    }

    private func chip(_ opcion: OpcionDeAviso) -> some View {
        let elegida = seleccion == opcion
        return Button {
            withAnimation(Lujo.curva(0.5)) { seleccion = opcion }
            alElegir(opcion)
        } label: {
            Text(titulo(opcion))
                .font(.lujoEtiqueta(.caption, elegida ? .semibold : .regular))
                .versalitas(0.9)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(elegida ? Lujo.oro : Lujo.marfil.opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: Lujo.altoMinimo)
                .background {
                    RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous)
                        .fill(Lujo.marfil.opacity(0.03))
                    if elegida {
                        RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous)
                            .strokeBorder(Lujo.oro.opacity(0.85), lineWidth: 0.75)
                            .matchedGeometryEffect(id: "aviso", in: espacio)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.selection, trigger: elegida) { _, ahora in ahora }
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
