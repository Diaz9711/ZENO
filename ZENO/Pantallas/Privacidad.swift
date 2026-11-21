import SwiftUI

/// La política de privacidad dentro de ZENO (auditoría, 20 nov 2026): una página en Ajustes, sin internet.
/// Dice lo mismo que `Web/privacidad.html`; si cambia una, cambiar la otra.
struct PrivacidadView: View {
    var alCerrar: () -> Void

    private struct Parte: Identifiable {
        let id: Int
        let titulo: LocalizedStringKey
        let texto: LocalizedStringKey
    }

    private let partes: [Parte] = [
        Parte(id: 0, titulo: "En pocas palabras",
              texto: "ZENO no recopila tus datos. Lo que escribes, tu estrella y tu historial se guardan solo en tu iPhone. Sin cuentas, sin servidores, sin publicidad y sin analíticas."),
        Parte(id: 1, titulo: "Qué guarda y dónde",
              texto: "Tu nombre y tu fecha de nacimiento (para crear tu estrella), tus tareas con su para qué, y cuándo empiezas, terminas o dejas algo para después (para proponerte lo que encaja con tu energía). Todo en tu iPhone. Si creas una clave, solo se guarda una huella en el Llavero, nunca la clave."),
        Parte(id: 2, titulo: "La IA de tu iPhone",
              texto: "Divídemela, la captura por voz y algunas frases de Chispa usan la IA de Apple que funciona dentro del iPhone. Lo que escribes o dictas no sale del teléfono."),
        Parte(id: 3, titulo: "Micrófono y voz",
              texto: "El micrófono solo se usa cuando tocas el botón de dictar. Tu voz se convierte en texto dentro del iPhone."),
        Parte(id: 4, titulo: "Avisos, widget y pantalla bloqueada",
              texto: "Los avisos están apagados hasta que los activas, sin sonido y sin el texto de tus tareas. Con el iPhone bloqueado, el texto de la tarea se oculta."),
        Parte(id: 5, titulo: "Borrar tus datos",
              texto: "En Ajustes → Tus datos puedes borrarlo todo, incluida tu clave."),
        Parte(id: 6, titulo: "Salud",
              texto: "ZENO acompaña tu día. No diagnostica, no trata y no reemplaza a ningún profesional ni tratamiento.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            BotonTerciarioLujo(titulo: "Ajustes", icono: .atras) { alCerrar() }
                .padding(.leading, -12)
                .aparece(0)

            VStack(alignment: .leading, spacing: 10) {
                EtiquetaLujo("ZENO")
                Text("Privacidad")
                    .font(.zenoTitulo(.largeTitle))
                    .foregroundStyle(Lujo.marfil)
                    .shadow(color: .black.opacity(0.45), radius: 12, y: 2)
            }
            .aparece(0)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(partes) { parte in
                    if parte.id > 0 { SeparadorLujo() }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(parte.titulo)
                            .font(.zenoTitulo(.title3, .regular))
                            .foregroundStyle(Lujo.marfil)
                        Text(parte.texto)
                            .font(.zenoTexto(.callout))
                            .foregroundStyle(Lujo.marfilSecundario)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 20)
            .tarjetaLujo()
            .aparece(1)
        }
    }
}
